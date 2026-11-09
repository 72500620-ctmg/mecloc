import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecloc/main.dart';
import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/models/workshop_search_result.dart';
import 'package:mecloc/providers/auth_provider.dart';
import 'package:mecloc/providers/quotes_provider.dart';
import 'package:mecloc/providers/theme_provider.dart';
import 'package:mecloc/providers/vehicle_provider.dart';
import 'package:mecloc/providers/workshop_provider.dart';
import 'package:mecloc/services/open_street_map_service.dart';
import 'package:mecloc/services/workshop_discovery_service.dart';
import 'package:mecloc/widgets/workshop_pin_marker.dart';

class _Search extends OpenStreetMapService {
  int automaticCalls = 0;
  LatLng? lastCenter;
  bool deferOnce = false;
  List<Workshop>? fixture;
  @override
  Future<List<Workshop>> searchNearbyWorkshops(LatLng center,
      {int? radiusMeters,
      ({double south, double west, double north, double east})? boundingBox,
      bool automatic = false,
      bool forceRefresh = false,
      void Function(List<Workshop>)? onProgress}) async {
    if (automatic) {
      automaticCalls++;
      if (deferOnce) {
        deferOnce = false;
        throw AutomaticSearchDeferred(
            DateTime.now().add(const Duration(seconds: 3)));
      }
    }
    lastCenter = center;
    return WorkshopSearchResult(
        fixture ??
            [
              Workshop(
                  id: 'osm:node:1',
                  name: 'Oficina Teste',
                  address: 'Rua Teste',
                  latitude: center.latitude,
                  longitude: center.longitude)
            ],
        isComplete: false);
  }
}

Future<_Search> _mount(WidgetTester tester, {List<Workshop>? initial}) async {
  SharedPreferences.setMockInitialValues({});
  final service = _Search()..fixture = initial;
  final provider = WorkshopProvider(openStreetMapService: service);
  addTearDown(provider.dispose);
  await provider.initialize(searchOnStart: false);
  await provider.searchWorkshops(customCenter: const LatLng(-19.92, -43.94));
  await tester.pumpWidget(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
    ChangeNotifierProvider.value(value: provider),
    ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
    ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ], child: const MecLocApp()));
  await tester.pump();
  return service;
}

void gesture(WidgetTester tester, LatLng point, double zoom) {
  final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
  map.mapController!.move(point, zoom);
  map.options.onPositionChanged!(map.mapController!.camera, true);
}

void main() {
  testWidgets(
      'estabelecimentos centrais permanecem nos zooms 13 a 17 com novas respostas parciais',
      (tester) async {
    const one = Workshop(
        id: 'osm:node:1',
        name: 'Oficina Um',
        address: 'Rua Teste',
        latitude: -19.92,
        longitude: -43.94);
    const two = Workshop(
        id: 'osm:node:2',
        name: 'Oficina Dois',
        address: 'Rua Teste',
        latitude: -19.92,
        longitude: -43.9397);
    final source = await _mount(tester, initial: [one, two]);
    source.fixture = [one];
    for (final zoom in [14.0, 15.0, 17.0, 13.0]) {
      gesture(tester, const LatLng(-19.92, -43.94), zoom);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();
      final visible = tester
          .widgetList<WorkshopPinMarker>(find.byType(WorkshopPinMarker))
          .map((marker) => marker.workshop.id)
          .toSet();
      expect(visible, containsAll(['osm:node:1', 'osm:node:2']),
          reason: 'zoom $zoom');
    }
  });
  testWidgets(
      'pequeno movimento durante espera preserva busca automática pendente',
      (tester) async {
    final source = await _mount(tester);
    source.deferOnce = true;
    gesture(tester, const LatLng(-19.93, -43.94), 14);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    expect(source.automaticCalls, 1);
    gesture(tester, const LatLng(-19.9301, -43.94), 14);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    expect(source.automaticCalls, 2);
    expect(source.lastCenter, const LatLng(-19.9301, -43.94));
    await tester.pump(const Duration(seconds: 4));
    expect(source.automaticCalls, 2);
  });
  testWidgets(
      'mapa continua automático com cobertura parcial e busca somente a última posição parada',
      (tester) async {
    final source = await _mount(tester);
    expect(find.text('Cobertura limitada'), findsOneWidget);
    gesture(tester, const LatLng(-19.925, -43.94), 14);
    await tester.pump(const Duration(milliseconds: 900));
    expect(source.automaticCalls, 0);
    gesture(tester, const LatLng(-19.93, -43.94), 14);
    await tester.pump(const Duration(milliseconds: 900));
    expect(source.automaticCalls, 0);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(source.automaticCalls, 1);
    expect(source.lastCenter, const LatLng(-19.93, -43.94));
    expect(find.text('Busca incompleta'), findsNothing);
  });

  testWidgets('zoom muito afastado mantém dados e não consulta servidores',
      (tester) async {
    final source = await _mount(tester);
    gesture(tester, const LatLng(-19.93, -43.94), 10);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(source.automaticCalls, 0);
    expect(
        find.text('Aproxime o mapa para buscar nesta região'), findsOneWidget);
  });
}
