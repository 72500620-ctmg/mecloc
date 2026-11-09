import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecloc/main.dart';
import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/models/workshop_search_result.dart';
import 'package:mecloc/providers/auth_provider.dart';
import 'package:mecloc/providers/theme_provider.dart';
import 'package:mecloc/providers/workshop_provider.dart';
import 'package:mecloc/providers/vehicle_provider.dart';
import 'package:mecloc/providers/quotes_provider.dart';
import 'package:mecloc/services/location_service.dart';
import 'package:mecloc/services/open_street_map_service.dart';

class _CitySearchService extends OpenStreetMapService {
  _CitySearchService({this.failSearch = false, this.partialSearch = false});

  final bool failSearch;
  final bool partialSearch;
  @override
  Future<List<Workshop>> searchWorkshopsByName(
          String name, LatLng center) async =>
      [];
  static const center = LatLng(-22.9056, -47.0596);
  static const secondCenter = LatLng(-23.5505, -46.6333);

  @override
  Future<LatLng> geocodeCity(String city) async {
    return switch (city) {
      'Campinas, SP' => center,
      'São Paulo' => secondCenter,
      _ => throw Exception('Cidade de teste desconhecida'),
    };
  }

  @override
  Future<List<Workshop>> searchNearbyWorkshops(
    LatLng center, {
    int? radiusMeters,
    ({double south, double west, double north, double east})? boundingBox,
    bool automatic = false,
    bool forceRefresh = false,
    void Function(List<Workshop>)? onProgress,
  }) async {
    if (failSearch) throw Exception('Serviço de teste indisponível');
    return WorkshopSearchResult([
      Workshop(
        id: 'osm:node:${center.latitude}',
        name: center == _CitySearchService.center
            ? 'Oficina Campinas de teste'
            : 'Oficina São Paulo de teste',
        address: 'Rua do Teste',
        latitude: center.latitude,
        longitude: center.longitude,
      ),
    ], isComplete: !partialSearch);
  }
}

class _PendingLocationService extends LocationService {
  _PendingLocationService(this.pending);

  final Future<LatLng> pending;

  @override
  Future<LatLng?> getLastKnownLocation() async => null;

  @override
  Future<LatLng> getCurrentLocation() => pending;
}

class _DeferredWorkshopService extends _CitySearchService {
  final response = Completer<List<Workshop>>();
  @override
  Future<List<Workshop>> searchNearbyWorkshops(LatLng center,
          {int? radiusMeters,
          ({double south, double west, double north, double east})? boundingBox,
          bool automatic = false,
          bool forceRefresh = false,
          void Function(List<Workshop>)? onProgress}) =>
      response.future;
}

void main() {
  testWidgets(
      'GPS inicial centraliza o mapa antes de terminar a busca de estabelecimentos',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final fix = Completer<LatLng>();
    final service = _DeferredWorkshopService();
    final workshops = WorkshopProvider(
        openStreetMapService: service,
        locationService: _PendingLocationService(fix.future));
    addTearDown(workshops.dispose);
    final boot = workshops.initialize();
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
      ChangeNotifierProvider.value(value: workshops),
      ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ], child: const MecLocApp()));
    await tester.pump();
    expect(find.text('Obtendo sua localização…'), findsOneWidget);
    fix.complete(_CitySearchService.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center, _CitySearchService.center);
    expect(workshops.isLoading, isTrue);
    service.response.completeError(Exception('Consulta externa falhou'));
    await tester.pump();
    await boot;
    await tester.pump();
    expect(map.mapController!.camera.center, _CitySearchService.center);
    expect(find.text('Consulta externa falhou'), findsOneWidget);
  });

  testWidgets('abertura usa posição salva e não inicia a câmera em Brasília',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'last_known_device_lat': _CitySearchService.center.latitude,
      'last_known_device_lng': _CitySearchService.center.longitude,
    });
    final workshops =
        WorkshopProvider(openStreetMapService: _CitySearchService());
    addTearDown(workshops.dispose);
    await workshops.initialize(searchOnStart: false);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
      ChangeNotifierProvider.value(value: workshops),
      ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ], child: const MecLocApp()));
    await tester.pump();
    expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!
            .camera
            .center,
        _CitySearchService.center);
  });

  testWidgets('navegação dá acesso às tarefas principais', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
      ChangeNotifierProvider(
          create: (_) => WorkshopProvider()..initialize(searchOnStart: false)),
      ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ], child: const MecLocApp()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Minha localização'), findsOneWidget);
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Suas oficinas salvas'), findsOneWidget);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Aparência'), findsNothing);
    expect(find.text('CONTA E ACESSO'), findsOneWidget);
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Orçamentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orçamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Orçamentos & Cotações'), findsOneWidget);
    expect(
        find.textContaining('Cotações Rápidas via WhatsApp'), findsOneWidget);
  });
  testWidgets('busca por cidade funciona enquanto o GPS está pendente',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final locationPending = Completer<LatLng>();
    final workshopProvider = WorkshopProvider(
      openStreetMapService: _CitySearchService(),
      locationService: _PendingLocationService(locationPending.future),
    );
    addTearDown(workshopProvider.dispose);
    await workshopProvider.initialize(searchOnStart: false);

    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
      ChangeNotifierProvider.value(value: workshopProvider),
      ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ], child: const MecLocApp()));
    await tester.pump();

    await tester.tap(find.byTooltip('Minha localização'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(workshopProvider.isLoading, isTrue);

    await tester.enterText(find.byType(TextField), 'Campinas, SP');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byTooltip('Buscar cidade'), findsNothing);
    expect(find.text('Perfil'), findsOneWidget);
    expect(workshopProvider.isLoading, isFalse);
    expect(workshopProvider.searchCenter, _CitySearchService.center);
    expect(workshopProvider.errorMessage, isNull);
    expect(workshopProvider.workshops.single.name, 'Oficina Campinas de teste');

    await tester.enterText(find.byType(TextField), 'São Paulo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(workshopProvider.searchCenter, _CitySearchService.secondCenter);
    expect(
        workshopProvider.workshops.single.name, 'Oficina São Paulo de teste');
  });

  testWidgets('menu oferece tema automático, claro e escuro', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final themeProvider = ThemeProvider();
    final workshopProvider = WorkshopProvider();
    await themeProvider.initialize();
    await workshopProvider.initialize(searchOnStart: false);
    addTearDown(themeProvider.dispose);
    addTearDown(workshopProvider.dispose);

    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: themeProvider),
      ChangeNotifierProvider.value(value: workshopProvider),
      ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ], child: const MecLocApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tema do aplicativo'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tema do aplicativo'));
    await tester.pumpAndSettle();
    expect(find.text('Automático'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);

    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(themeProvider.themeMode, ThemeMode.dark);
    expect(Theme.of(tester.element(find.text('Aparência'))).brightness,
        Brightness.dark);
  });

  testWidgets('resultado parcial aparece com aviso e ação de nova tentativa',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final theme = ThemeProvider();
    final workshops = WorkshopProvider(
        openStreetMapService: _CitySearchService(partialSearch: true));
    addTearDown(theme.dispose);
    addTearDown(workshops.dispose);
    await theme.initialize();
    await workshops.initialize(searchOnStart: false);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: theme),
      ChangeNotifierProvider.value(value: workshops),
      ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ], child: const MecLocApp()));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Campinas, SP');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Cobertura limitada'), findsOneWidget);
    expect(find.text('Busca incompleta'), findsNothing);
    expect(find.text('Atualizar'), findsOneWidget);
    expect(workshops.getFilteredWorkshops(null), hasLength(1));
  });

  testWidgets('falha da busca é mostrada no componente de aviso',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final themeProvider = ThemeProvider();
    final workshopProvider = WorkshopProvider(
      openStreetMapService: _CitySearchService(failSearch: true),
    );
    await themeProvider.initialize();
    await workshopProvider.initialize(searchOnStart: false);
    addTearDown(themeProvider.dispose);
    addTearDown(workshopProvider.dispose);

    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: themeProvider),
      ChangeNotifierProvider.value(value: workshopProvider),
      ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ], child: const MecLocApp()));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Campinas, SP');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Não foi possível concluir a busca'), findsOneWidget);
    expect(find.text('Serviço de teste indisponível'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
