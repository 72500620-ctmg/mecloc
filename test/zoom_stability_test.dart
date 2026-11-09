import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecloc/models/search_area.dart';
import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/models/workshop_search_result.dart';
import 'package:mecloc/services/discovery_cache.dart';
import 'package:mecloc/services/open_street_map_service.dart';

const center = LatLng(-19.92, -43.94);
const wide = SearchArea(center,
    bounds: (south: -19.95, west: -43.97, north: -19.89, east: -43.91));
const close = SearchArea(center,
    bounds: (south: -19.925, west: -43.945, north: -19.915, east: -43.935));
Workshop place(int id, {double offset = 0, String? name}) => Workshop(
    id: 'osm:node:$id',
    name: name ?? 'Oficina $id',
    address: 'Rua Teste',
    latitude: center.latitude,
    longitude: center.longitude + offset);
Set<String> ids(Iterable<Workshop>? result) =>
    (result ?? []).map((w) => w.id).toSet();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parcial menor não oculta locais já conhecidos ao alternar zoom',
      () async {
    final cache = DiscoveryCache(now: () => DateTime(2026, 11, 9));
    await cache.restore();
    await cache.put(
        wide,
        WorkshopSearchResult([place(1), place(2, offset: 0.001)],
            isComplete: false));
    await cache.put(
        close,
        WorkshopSearchResult([place(1, name: 'Nome atualizado')],
            isComplete: false));
    for (final area in [close, wide, close, wide]) {
      final result = cache.lookup(area)!;
      expect(ids(result), {'osm:node:1', 'osm:node:2'});
      expect(result.isComplete, isFalse);
      expect(result.firstWhere((w) => w.id == 'osm:node:1').name,
          'Nome atualizado');
    }
  });

  test(
      'recorte mantém apenas locais dentro da área sem esquecê-los no zoom de volta',
      () async {
    final cache = DiscoveryCache(now: () => DateTime(2026, 11, 9));
    await cache.restore();
    await cache.put(
        wide,
        WorkshopSearchResult([place(1), place(2, offset: 0.02)],
            isComplete: false));
    expect(ids(cache.lookup(close)), {'osm:node:1'});
    expect(ids(cache.lookup(wide)), {'osm:node:1', 'osm:node:2'});
  });

  test('parcial recente não rebaixa cobertura completa ainda válida', () async {
    var date = DateTime(2026, 11, 9);
    final cache = DiscoveryCache(now: () => date);
    await cache.restore();
    await cache.put(wide, WorkshopSearchResult([place(1), place(2)]));
    date = date.add(const Duration(minutes: 1));
    await cache.put(close, WorkshopSearchResult([place(1)], isComplete: false));
    final result = cache.lookup(close)!;
    expect(result.isComplete, isTrue);
    expect(ids(result), {'osm:node:1', 'osm:node:2'});
  });

  test('cache anterior é migrado e continua estável após reabrir', () async {
    final date = DateTime(2026, 11, 9);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        DiscoveryCache.storageKey,
        jsonEncode([
          {
            'area': wide.toJson(),
            'at': date.toIso8601String(),
            'complete': false,
            'items': [place(1).toJson(), place(2).toJson()]
          },
          {
            'area': close.toJson(),
            'at': date.add(const Duration(seconds: 1)).toIso8601String(),
            'complete': false,
            'items': [place(1).toJson()]
          },
        ]));
    final cache =
        DiscoveryCache(now: () => date.add(const Duration(seconds: 2)));
    await cache.restore();
    expect(ids(cache.lookup(close)), {'osm:node:1', 'osm:node:2'});
    await cache.put(close, WorkshopSearchResult([place(1)], isComplete: false));
    final reopened =
        DiscoveryCache(now: () => date.add(const Duration(seconds: 3)));
    await reopened.restore();
    expect(ids(reopened.lookup(close)), {'osm:node:1', 'osm:node:2'});
  });

  test(
      'resposta completa substitui seus dados sem ressuscitar ausências após reabrir',
      () async {
    final date = DateTime(2026, 11, 9);
    final cache = DiscoveryCache(now: () => date);
    await cache.restore();
    await cache.put(
        wide,
        WorkshopSearchResult([place(1), place(2), place(3, offset: 0.02)],
            isComplete: false));
    await cache.put(close, WorkshopSearchResult([place(1)]));
    expect(ids(cache.lookup(wide)), {'osm:node:1', 'osm:node:3'});
    final reopened = DiscoveryCache(now: () => date);
    await reopened.restore();
    expect(ids(reopened.lookup(wide)), {'osm:node:1', 'osm:node:3'});
    expect(reopened.lookup(close)!.isComplete, isTrue);
  });

  test('parciais não renovam indefinidamente a validade de locais ausentes',
      () async {
    var date = DateTime(2026, 11, 9);
    final cache = DiscoveryCache(now: () => date);
    await cache.restore();
    await cache.put(wide, WorkshopSearchResult([place(1)], isComplete: false));
    date = date.add(const Duration(days: 6));
    await cache.put(wide, WorkshopSearchResult([place(2)], isComplete: false));
    date = date.add(const Duration(days: 2));
    expect(ids(cache.preview(wide)), {'osm:node:2'});
  });

  test('troca de zoom combina áreas salvas sem novas requisições de rede',
      () async {
    final date = DateTime(2026, 11, 9);
    final cache = DiscoveryCache(now: () => date);
    await cache.restore();
    await cache.put(
        wide, WorkshopSearchResult([place(1), place(2)], isComplete: false));
    await cache.put(close, WorkshopSearchResult([place(1)], isComplete: false));
    var calls = 0;
    final service = OpenStreetMapService(
        now: () => date,
        client: MockClient((_) async {
          calls++;
          return http.Response('erro', 503);
        }));
    addTearDown(service.dispose);
    for (final area in [close, wide, close]) {
      final result = await service.searchNearbyWorkshops(center,
          boundingBox: area.bounds, automatic: true);
      expect(ids(result), {'osm:node:1', 'osm:node:2'});
    }
    expect(calls, 0);
  });

  test(
      'resposta individual acima do limite não perde locais ao reutilizar cache',
      () async {
    final date = DateTime(2026, 11, 9);
    final cache = DiscoveryCache(now: () => date);
    await cache.restore();
    await cache.put(wide,
        WorkshopSearchResult(List.generate(1601, (index) => place(index))));
    expect(cache.lookup(close), hasLength(1601));
    final reopened = DiscoveryCache(now: () => date);
    await reopened.restore();
    expect(reopened.lookup(close), hasLength(1601));
  });
}
