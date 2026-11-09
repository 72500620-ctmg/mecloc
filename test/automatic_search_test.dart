import 'dart:async';
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
import 'package:mecloc/services/map_search_policy.dart';
import 'package:mecloc/services/open_street_map_service.dart';
import 'package:mecloc/services/workshop_discovery_service.dart';

const point = LatLng(-19.92, -43.94);
const box = (south: -19.93, west: -43.95, north: -19.91, east: -43.93);
Workshop item([int id = 1]) => Workshop.fromOverpassJson({
      'id': id,
      'type': 'node',
      'lat': point.latitude,
      'lon': point.longitude,
      'tags': {'name': 'Oficina $id', 'shop': 'car_repair'}
    });
http.Response osm({String? remark}) => http.Response(
    jsonEncode({
      'elements': [
        {
          'id': 1,
          'type': 'node',
          'lat': point.latitude,
          'lon': point.longitude,
          'tags': {'shop': 'car_repair'}
        },
      ],
      if (remark != null) 'remark': remark
    }),
    200);
OpenStreetMapService service(http.Client client, {DateTime Function()? now}) =>
    OpenStreetMapService(
        client: client, now: now, minimumRequestInterval: Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cache persiste parciais e mantém cobertura e avaliação desconhecida',
      () async {
    final now = DateTime(2026, 11, 9);
    final cache = DiscoveryCache(now: () => now);
    await cache.restore();
    await cache.put(const SearchArea(point),
        WorkshopSearchResult([item()], isComplete: false));
    final restored = DiscoveryCache(now: () => now);
    await restored.restore();
    final result = restored.lookup(const SearchArea(point, bounds: box))!;
    expect(result.single.rating, isNull);
    expect(result.single.ratingCount, isNull);
    expect(result.isComplete, isFalse);
    expect(result.fromCache, isTrue);
  });

  test('cache de círculo cobre viewport e evita novas chamadas ao mover pouco',
      () async {
    var calls = 0;
    final s = service(MockClient((_) async {
      calls++;
      return osm();
    }));
    addTearDown(s.dispose);
    await s.searchNearbyWorkshops(point);
    final result =
        await s.searchNearbyWorkshops(point, boundingBox: box, automatic: true);
    expect(calls, 1);
    expect((result as WorkshopSearchResult).fromCache, isTrue);
  });

  test('margem do viewport reaproveita consulta sem alterar escopo exibido',
      () async {
    var calls = 0;
    final s = service(MockClient((_) async {
      calls++;
      return osm();
    }));
    addTearDown(s.dispose);
    await s.searchNearbyWorkshops(point, boundingBox: box, automatic: true);
    final result = await s.searchNearbyWorkshops(point,
        boundingBox: (
          south: -19.929,
          west: -43.949,
          north: -19.909,
          east: -43.929
        ),
        automatic: true);
    expect(calls, 1);
    expect(result, hasLength(1));
  });

  test('navegação automática não aciona Nominatim e limita contingência Photon',
      () async {
    final hosts = <String>[];
    final s = service(MockClient((request) async {
      hosts.add(request.url.host);
      return request.method == 'POST'
          ? http.Response('indisponível', 503)
          : http.Response('{"features":[]}', 200);
    }));
    addTearDown(s.dispose);
    await expectLater(
        s.searchNearbyWorkshops(point, automatic: true), throwsException);
    expect(hosts.where((h) => h == 'nominatim.openstreetmap.org'), isEmpty);
    expect(hosts.where((h) => h == 'photon.komoot.io').length, 3);
    expect(hosts.length, 5);
  });

  test('parciais frescos são reutilizados sem repetir APIs', () async {
    var calls = 0;
    final s = service(MockClient((request) async {
      calls++;
      return request.method == 'POST'
          ? osm(remark: 'Query timed out')
          : http.Response('erro', 503);
    }));
    addTearDown(s.dispose);
    final first = await s.searchNearbyWorkshops(point);
    final before = calls;
    final second = await s.searchNearbyWorkshops(point);
    expect((first as WorkshopSearchResult).isComplete, isFalse);
    expect((second as WorkshopSearchResult).isComplete, isFalse);
    expect(calls, before);
  });

  test('primeiro lote aparece antes do restante da contingência terminar',
      () async {
    final first = Completer<void>();
    final second = Completer<http.Response>();
    var done = false;
    http.Response matches(int id, String type) => http.Response(
        jsonEncode([
          {
            'osm_type': 'node',
            'osm_id': id,
            'category': 'shop',
            'type': type,
            'lat': '-19.92',
            'lon': '-43.94',
            'name': 'Estabelecimento $id'
          },
        ]),
        200);
    final s = service(MockClient((request) async {
      if (request.url.host != 'nominatim.openstreetmap.org') {
        return http.Response('erro', 503);
      }
      return switch (request.url.queryParameters['q']) {
        '[shop=car_repair]' => matches(1, 'car_repair'),
        '[shop=tyres]' => second.future,
        _ => http.Response('[]', 200),
      };
    }));
    addTearDown(s.dispose);
    final future = s.searchNearbyWorkshops(point, onProgress: (items) {
      if (items.isNotEmpty && !first.isCompleted) first.complete();
    }).then((result) {
      done = true;
      return result;
    });
    await first.future;
    expect(done, isFalse);
    second.complete(matches(2, 'tyres'));
    expect(await future, hasLength(2));
  });

  test('apenas uma requisição HTTP fica ativa mesmo entre regiões diferentes',
      () async {
    var active = 0, maxActive = 0, calls = 0;
    final s = service(MockClient((_) async {
      active++;
      calls++;
      if (active > maxActive) maxActive = active;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      active--;
      return osm();
    }));
    addTearDown(s.dispose);
    await Future.wait([
      s.searchNearbyWorkshops(point),
      s.searchNearbyWorkshops(const LatLng(-23, -46))
    ]);
    expect(calls, 2);
    expect(maxActive, 1);
  });

  test(
      'cancelamento interrompe HTTP e não inicia contingências da busca antiga',
      () async {
    final started = Completer<void>();
    var calls = 0, aborted = false;
    final s = service(MockClient.streaming((request, _) async {
      calls++;
      if (calls == 1) {
        started.complete();
        await (request as http.AbortableRequest).abortTrigger;
        aborted = true;
        throw http.RequestAbortedException(request.url);
      }
      return http.StreamedResponse(
          Stream.value(utf8.encode('{"elements":[]}')), 200);
    }));
    addTearDown(s.dispose);
    final old = s.searchNearbyWorkshops(point);
    final assertion = expectLater(old, throwsA(isA<DiscoveryCancelled>()));
    await started.future;
    s.cancelDiscoverySearches();
    final current = await s.searchNearbyWorkshops(const LatLng(-23, -46));
    await assertion;
    expect(aborted, isTrue);
    expect(current, isEmpty);
    expect(calls, 2);
  });

  test('buscas automáticas aguardam intervalo e coalescem a mesma área',
      () async {
    var now = DateTime(2026, 11, 9);
    var calls = 0;
    final pending = Completer<http.Response>();
    final s = service(MockClient((_) async {
      calls++;
      return calls == 1 ? pending.future : osm();
    }), now: () => now);
    addTearDown(s.dispose);
    final a = s.searchNearbyWorkshops(point, automatic: true);
    final b = s.searchNearbyWorkshops(point, automatic: true);
    await Future<void>.delayed(Duration.zero);
    pending.complete(osm());
    await a;
    await b;
    expect(calls, 1);
    await expectLater(
        s.searchNearbyWorkshops(const LatLng(-23, -46), automatic: true),
        throwsA(isA<AutomaticSearchDeferred>()));
    expect(calls, 1);
    now = now.add(const Duration(seconds: 9));
    await s.searchNearbyWorkshops(const LatLng(-23, -46), automatic: true);
    expect(calls, 2);
  });

  test('Retry-After é respeitado mesmo ao pedir atualização explícita',
      () async {
    var now = DateTime(2026, 11, 9), firstCalls = 0;
    final s = service(MockClient((request) async {
      if (request.url.host == 'overpass-api.de') {
        firstCalls++;
        if (firstCalls == 1) {
          return http.Response('limite', 429, headers: {'retry-after': '90'});
        }
      }
      return http.Response('{"elements":[]}', 200);
    }), now: () => now);
    addTearDown(s.dispose);
    await s.searchNearbyWorkshops(point);
    now = now.add(const Duration(seconds: 61));
    await s.searchNearbyWorkshops(point, forceRefresh: true);
    expect(firstCalls, 1);
    now = now.add(const Duration(seconds: 30));
    await s.searchNearbyWorkshops(point, forceRefresh: true);
    expect(firstCalls, 2);
  });

  test('falha de atualização devolve dados antigos identificados como salvos',
      () async {
    var now = DateTime(2026, 11, 9);
    final cache = DiscoveryCache(now: () => now);
    await cache.restore();
    await cache.put(const SearchArea(point), WorkshopSearchResult([item()]));
    now = now.add(const Duration(hours: 7));
    final s = service(MockClient((_) async => http.Response('erro', 503)),
        now: () => now);
    addTearDown(s.dispose);
    final result = await s.searchNearbyWorkshops(point, automatic: true);
    expect(result, hasLength(1));
    expect((result as WorkshopSearchResult).isStale, isTrue);
  });

  test(
      'política ignora pequenos movimentos e zoom amplo, mas acompanha mudança útil',
      () {
    expect(MapSearchPolicy.shouldSearch(point, 10, box), isFalse);
    expect(
        MapSearchPolicy.shouldSearch(const LatLng(-19.919, -43.94), 13, box,
            previousCenter: point, previousZoom: 13),
        isFalse);
    expect(
        MapSearchPolicy.shouldSearch(const LatLng(-19.912, -43.94), 13, box,
            previousCenter: point, previousZoom: 13),
        isTrue);
    expect(
        MapSearchPolicy.shouldSearch(point, 13.5, box,
            previousCenter: point, previousZoom: 13),
        isTrue);
  });
}
