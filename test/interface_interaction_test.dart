import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecloc/main.dart';
import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/providers/auth_provider.dart';
import 'package:mecloc/providers/quotes_provider.dart';
import 'package:mecloc/providers/theme_provider.dart';
import 'package:mecloc/providers/vehicle_provider.dart';
import 'package:mecloc/providers/workshop_provider.dart';
import 'package:mecloc/screens/favorites_screen.dart';
import 'package:mecloc/screens/profile_screen.dart';
import 'package:mecloc/theme/app_theme.dart';
import 'package:mecloc/widgets/workshop_detail_sheet.dart';
import 'package:mecloc/widgets/workshop_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mechanic = Workshop(
  id: 'favorite-mechanic',
  name: 'Mecânica São José',
  address: 'Centro',
);
const _tires = Workshop(
  id: 'favorite-tires',
  name: 'Pneus Avenida',
  address: 'Savassi',
  category: 'Pneus',
  categoryType: WorkshopCategory.tireShop,
);

Future<WorkshopProvider> _mount(WidgetTester tester,
    {Size size = const Size(390, 844),
    bool dark = false,
    double scale = 1,
    List<Workshop> cachedWorkshops = const []}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    if (cachedWorkshops.isNotEmpty)
      'custom_registered_workshops_v1':
          cachedWorkshops.map((w) => jsonEncode(w.toJson())).toList(),
  });
  final workshops = WorkshopProvider();
  final theme = ThemeProvider();
  await workshops.initialize(searchOnStart: false);
  await theme.initialize();
  if (dark) await theme.setThemeMode(ThemeMode.dark);
  await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: workshops),
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => QuotesProvider()),
      ],
      child: Builder(
          builder: (context) => MediaQuery(
                data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: const MecLocApp(),
              ))));
  addTearDown(workshops.dispose);
  addTearDown(theme.dispose);
  await tester.pumpAndSettle();
  return workshops;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('navegação segue o papel de superfície do tema escuro=$dark',
        (tester) async {
      await _mount(tester, dark: dark);
      final nav = find.byType(NavigationBar);
      final scheme = Theme.of(tester.element(nav)).colorScheme;
      final background =
          NavigationBarTheme.of(tester.element(nav)).backgroundColor;
      expect(background, dark ? scheme.surfaceContainer : scheme.surface);
      final ink = dark ? scheme.onSurface : scheme.primary;
      final foreground = ink.computeLuminance();
      final surface = background!.computeLuminance();
      final contrast = (foreground > surface)
          ? (foreground + 0.05) / (surface + 0.05)
          : (surface + 0.05) / (foreground + 0.05);
      expect(contrast, greaterThanOrEqualTo(4.5));
      final shellScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(shellScaffold.extendBody, isTrue);
      final sheetRect = tester.getRect(find.byType(ListView).first);
      expect(sheetRect.bottom, closeTo(844, 1));
      final navRect = tester.getRect(nav);
      expect(navRect.bottom, lessThan(844));
    });
  }

  testWidgets('ícones do perfil seguem a cor primária no tema escuro',
      (tester) async {
    await _mount(tester, dark: true);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ProfileScreen));
    final icon = tester.widget<Icon>(find.byIcon(Icons.login_rounded).first);
    expect(icon.color, Theme.of(context).colorScheme.primary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('favoritos vazios oferecem retorno funcional para o mapa',
      (tester) async {
    await _mount(tester);
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorar oficinas'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Minha localização'), findsOneWidget);
    expect(find.byType(FavoritesScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('favoritos buscam por nome sem acento e endereço',
      (tester) async {
    final workshops = await _mount(tester);
    await workshops.toggleFavorite(_mechanic.id, _mechanic);
    await workshops.toggleFavorite(_tires.id, _tires);
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sao jose');
    await tester.pumpAndSettle();
    expect(find.text(_mechanic.name), findsOneWidget);
    expect(find.text(_tires.name), findsNothing);
    await tester.enterText(find.byType(TextField), 'savassi');
    await tester.pumpAndSettle();
    expect(find.text(_tires.name), findsOneWidget);
    expect(find.text(_mechanic.name), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('salvar um card não abre seus detalhes e permite desfazer',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final workshops = WorkshopProvider();
    await workshops.initialize(searchOnStart: false);
    addTearDown(workshops.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: workshops,
        child: MaterialApp(
            theme: AppTheme.light,
            home:
                const Scaffold(body: WorkshopListTile(workshop: _mechanic)))));
    await tester.tap(find.byTooltip('Salvar nos favoritos'));
    await tester.pumpAndSettle();
    expect(workshops.isFavorite(_mechanic.id), isTrue);
    expect(find.byType(WorkshopDetailSheet), findsNothing);
    await tester.tap(find.byTooltip('Remover dos favoritos'));
    await tester.pumpAndSettle();
    expect(workshops.isFavorite(_mechanic.id), isFalse);
  });

  testWidgets('oficina salva centraliza mapa sem GPS', (tester) async {
    await _mount(tester, size: const Size(1024, 768), cachedWorkshops: const [
      Workshop(
          id: 'cached-center',
          name: 'Oficina da região',
          address: 'Centro',
          latitude: -19.92,
          longitude: -43.94,
          isCustomRegistered: true),
    ]);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center.latitude, closeTo(-19.92, 0.001));
    expect(map.mapController!.camera.center.longitude, closeTo(-43.94, 0.001));
    expect(map.mapController!.camera.zoom, greaterThan(13));
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtro principal é acessível sem rolar em celular compacto',
      (tester) async {
    final workshops = await _mount(tester, size: const Size(320, 568));
    final filter = find.widgetWithText(FilterChip, 'Mecânica').hitTestable();
    expect(filter, findsOneWidget);
    await tester.tap(filter);
    await tester.pumpAndSettle();
    expect(workshops.selectedCategory, WorkshopCategory.mechanic);
    expect(tester.takeException(), isNull);
  });

  testWidgets('painel recolhido permanece no lugar ao arrastar o mapa',
      (tester) async {
    await _mount(tester, size: const Size(390, 844));
    final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet));
    expect(sheet.snap, isFalse);
    final panel = find.byType(ListView).first;
    final initialTop = tester.getTopLeft(panel).dy;
    await tester.dragFrom(Offset(190, initialTop + 14), const Offset(0, 350));
    await tester.pumpAndSettle();
    final collapsedTop = tester.getTopLeft(panel).dy;
    expect(collapsedTop, greaterThan(initialTop + 100));

    await tester.dragFrom(const Offset(190, 260), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel).dy, closeTo(collapsedTop, 2));

    await tester.dragFrom(Offset(190, collapsedTop + 12), const Offset(0, -18));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(panel).dy, greaterThan(collapsedTop - 65),
        reason: 'Um gesto curto no puxador não deve expandir até 55%');
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtro pode trocar de serviço sem voltar ao início',
      (tester) async {
    final workshops = await _mount(tester, size: const Size(1440, 900));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'Mecânica'));
    await tester.pumpAndSettle();
    expect(workshops.selectedCategory, WorkshopCategory.mechanic);
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Pneus'));
    await tester.tap(find.widgetWithText(FilterChip, 'Pneus'));
    await tester.pumpAndSettle();
    expect(workshops.selectedCategory, WorkshopCategory.tireShop);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 768)
  ]) {
    for (final dark in [false, true]) {
      testWidgets('layout sem overflow em $size, escuro=$dark', (tester) async {
        await _mount(tester, size: size, dark: dark);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Favoritos'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
