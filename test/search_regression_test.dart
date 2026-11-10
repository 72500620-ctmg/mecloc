import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/models/workshop_search_result.dart';
import 'package:mecloc/providers/workshop_provider.dart';
import 'package:mecloc/services/open_street_map_service.dart';

const center = LatLng(-19.92, -43.94);
Map<String, dynamic> element(int id, Map<String, dynamic> tags,
        {LatLng point = center}) =>
    {
      'type': 'node',
      'id': id,
      'lat': point.latitude,
      'lon': point.longitude,
      'tags': tags,
    };
http.Response overpass(List<dynamic> items, {String? remark}) => http.Response(
    jsonEncode({'elements': items, if (remark != null) 'remark': remark}), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});
Map<String, dynamic> feature(int id, String key, String value, String name,
        {LatLng point = center, String type = 'N'}) =>
    {
      'geometry': {
        'coordinates': [point.longitude, point.latitude]
      },
      'properties': {
        'osm_type': type,
        'osm_id': id,
        'osm_key': key,
        'osm_value': value,
        'name': name
      },
    };
http.Response photon(List<dynamic> features) =>
    http.Response(jsonEncode({'features': features}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
Workshop workshop(int id,
        {String name = 'Oficina João',
        LatLng point = center,
        Map<String, dynamic> tags = const {'shop': 'car_repair'}}) =>
    Workshop.fromOverpassJson(
        element(id, {...tags, 'name': name}, point: point));

class FakeDiscovery extends OpenStreetMapService {
  int nearbyCalls = 0, nameCalls = 0;
  List<Workshop> nearby = [workshop(1)];
  List<Workshop> named = [];
  ({double south, double west, double north, double east})? lastBounds;
  LatLng? lastCenter;
  @override
  Future<LatLng> geocodeCity(String city) async => center;
  @override
  Future<List<Workshop>> searchNearbyWorkshops(LatLng point,
      {int? radiusMeters,
      ({double south, double west, double north, double east})? boundingBox,
      bool automatic = false,
      bool forceRefresh = false,
      void Function(List<Workshop>)? onProgress}) async {
    nearbyCalls++;
    lastBounds = boundingBox;
    lastCenter = point;
    return nearby;
  }

  @override
  Future<List<Workshop>> searchWorkshopsByName(
      String name, LatLng point) async {
    nameCalls++;
    return named;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'rejeita concessionárias, revendas, motos, restaurantes e serviço negado',
      () async {
    String? query;
    final service = OpenStreetMapService(client: MockClient((request) async {
      query = request.bodyFields['data'];
      return overpass([
        element(1, {'shop': 'car', 'service:vehicle:oil_change': 'yes'}),
        element(2, {'shop': 'car_repair', 'name': 'Concessionária Teste'}),
        element(3, {'shop': 'motorcycle_repair'}),
        element(4, {'amenity': 'restaurant'}),
        element(5, {'service:vehicle:glass': 'no'}),
        element(6, {'shop': 'car_repair', 'name': 'Oficina multimarcas'}),
        element(7, {'amenity': 'car_wash'}),
        element(8, {'shop': 'tyres'}),
      ]);
    }));
    addTearDown(service.dispose);
    final results = await service.searchNearbyWorkshops(center);
    expect(
        results.map((w) => w.id), ['osm:node:6', 'osm:node:7', 'osm:node:8']);
    expect(query, isNot(contains('["shop"="car"]')));
    expect(query, isNot(contains('["shop"="motorcycle_repair"]')));
    expect(query, contains('out center tags;'));
  });

  test('mais de 400 estabelecimentos são mantidos e ordenados por distância',
      () async {
    final service = OpenStreetMapService(
        client: MockClient((_) async => overpass([
              for (var id = 450; id >= 1; id--)
                element(id, {'shop': 'car_repair'},
                    point: LatLng(
                        center.latitude + id / 100000, center.longitude)),
            ])));
    addTearDown(service.dispose);
    final result = await service.searchNearbyWorkshops(center);
    expect(result, hasLength(450));
    expect(result.first.id, 'osm:node:1');
    expect(result.last.id, 'osm:node:450');
  });

  test(
      'oficina mantém múltiplos serviços após persistência; craft não implica funilaria',
      () {
    final original = workshop(1, tags: {
      'shop': 'car_repair',
      'service:vehicle:oil_change': 'yes',
      'service:vehicle:body_repair': 'yes'
    });
    final restored = Workshop.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
    for (final value in [original, restored]) {
      expect(value.matchesCategory(WorkshopCategory.mechanic), isTrue);
      expect(value.matchesCategory(WorkshopCategory.oilChange), isTrue);
      expect(value.matchesCategory(WorkshopCategory.bodyPaint), isTrue);
      expect(value.specialties, containsAll(['Troca de óleo', 'Funilaria']));
    }
    expect(workshop(2, tags: {'craft': 'car_repair'}).categoryType,
        WorkshopCategory.mechanic);
    expect(
        workshop(3, tags: {'shop': 'car_repair', 'car_repair': 'bodywork'})
            .categoryType,
        WorkshopCategory.bodyPaint);
    expect(
        workshop(4, name: 'Troca de óleo', tags: {
          'shop': 'car_repair',
          'service:vehicle:oil_change': 'no'
        }).matchesCategory(WorkshopCategory.oilChange),
        isFalse);
  });

  test(
      'Photon por nome mantém categorias e relations e rejeita atividades externas',
      () async {
    final service = OpenStreetMapService(
        client: MockClient((request) async => request.method == 'POST'
            ? http.Response('erro', 503)
            : photon([
                feature(1, 'shop', 'car', 'Concessionária'),
                feature(2, 'amenity', 'restaurant', 'Restaurante'),
                feature(3, 'shop', 'tyres', 'Pneus Central', type: 'R'),
                feature(4, 'amenity', 'car_wash', 'Lava-jato Central'),
              ])));
    addTearDown(service.dispose);
    final result = await service.searchWorkshopsByName('Central', center);
    expect(result.map((w) => w.id), ['osm:relation:3', 'osm:node:4']);
    expect(result.map((w) => w.categoryType),
        [WorkshopCategory.tireShop, WorkshopCategory.carWash]);
    expect((result as WorkshopSearchResult).isComplete, isFalse);
  });

  test(
      'nome com aspas e regex vira filtro literal, sem seletor genérico por nome',
      () async {
    final queries = <String>[];
    const name = 'Auto "A.*"';
    final service = OpenStreetMapService(client: MockClient((request) async {
      if (request.method != 'POST') return photon([]);
      queries.add(request.bodyFields['data']!);
      return overpass([
        element(1, {'shop': 'car_repair', 'name': name}),
        element(2, {'amenity': 'restaurant', 'name': name}),
      ]);
    }));
    addTearDown(service.dispose);
    expect(await service.searchWorkshopsByName(name, center), hasLength(1));
    expect(queries.single,
        contains('["name"~${jsonEncode(RegExp.escape(name))},i]'));
    expect(queries.single, isNot(contains(')["name"~')));
  });

  test(
      'fallback respeita área e declara lista parcial sem cachear como completa',
      () async {
    int postCalls = 0;
    final service = OpenStreetMapService(client: MockClient((request) async {
      if (request.method == 'POST') {
        postCalls++;
        return http.Response('erro', 503);
      }
      expect(request.url.queryParametersAll['osm_tag'], contains('shop:tyres'));
      expect(request.url.queryParameters['bbox'], isNotNull);
      return photon([
        feature(1, 'shop', 'tyres', 'Pneus próximos'),
        feature(2, 'amenity', 'car_wash', 'Lavagem distante',
            point: const LatLng(-20.5, -44.5)),
        feature(3, 'shop', 'car', 'Concessionária'),
      ]);
    }));
    addTearDown(service.dispose);
    for (var i = 0; i < 2; i++) {
      final result = await service.searchNearbyWorkshops(center);
      expect(result, hasLength(1));
      expect((result as WorkshopSearchResult).notice, isNotNull);
    }
    expect(
        postCalls, 2); // Não insiste imediatamente em servidores indisponíveis.
  });

  test('cache distingue centros e expira após seis horas', () async {
    int calls = 0;
    var now = DateTime(2026, 11, 9, 14);
    final service = OpenStreetMapService(
        now: () => now,
        client: MockClient((_) async {
          calls++;
          return overpass([
            element(1, {'shop': 'car_repair'})
          ]);
        }));
    addTearDown(service.dispose);
    await service.searchNearbyWorkshops(center);
    await service.searchNearbyWorkshops(center);
    expect(calls, 1);
    await service.searchNearbyWorkshops(
        LatLng(center.latitude + 0.009, center.longitude));
    expect(calls, 2);
    now = now.add(const Duration(hours: 7));
    await service.searchNearbyWorkshops(center);
    expect(calls, 3);
  });

  test(
      'fontes indisponíveis usam correspondências Nominatim tipadas e parciais',
      () async {
    final terms = <String>[];
    final starts = <DateTime>[];
    final service = OpenStreetMapService(client: MockClient((request) async {
      if (request.url.host != 'nominatim.openstreetmap.org') {
        return http.Response('erro', 503);
      }
      terms.add(request.url.queryParameters['q']!);
      starts.add(DateTime.now());
      expect(request.url.queryParameters['limit'], '10');
      expect(request.url.queryParameters['bounded'], '1');
      final type = switch (terms.last) {
        '[shop=tyres]' => 'tyres',
        '[amenity=car_wash]' => 'car_wash',
        _ => 'car_repair'
      };
      return http.Response(
          jsonEncode([
            {
              'osm_type': 'node',
              'osm_id': terms.length,
              'category': type == 'car_wash' ? 'amenity' : 'shop',
              'type': type,
              'name': 'Estabelecimento ${terms.length}',
              'lat': '${center.latitude}',
              'lon': '${center.longitude}',
              'address': {'road': 'Rua Teste', 'house_number': '10'}
            },
            {
              'osm_type': 'node',
              'osm_id': 100,
              'class': 'shop',
              'type': 'car',
              'name': 'Concessionária',
              'lat': '${center.latitude}',
              'lon': '${center.longitude}'
            },
            {
              'osm_type': 'node',
              'osm_id': 101,
              'category': 'amenity',
              'type': 'restaurant',
              'name': 'Restaurante',
              'lat': '${center.latitude}',
              'lon': '${center.longitude}'
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    addTearDown(service.dispose);
    final result = await service.searchNearbyWorkshops(center);
    expect(result, hasLength(3));
    expect(result.map((w) => w.categoryType), [
      WorkshopCategory.mechanic,
      WorkshopCategory.tireShop,
      WorkshopCategory.carWash
    ]);
    expect((result as WorkshopSearchResult).isComplete, isFalse);
    expect(terms, ['[shop=car_repair]', '[shop=tyres]', '[amenity=car_wash]']);
    expect(starts[1].difference(starts[0]).inMilliseconds,
        greaterThanOrEqualTo(900));
    expect(starts[2].difference(starts[1]).inMilliseconds,
        greaterThanOrEqualTo(900));
  });

  test('nome sem acento usa Photon quando a busca literal completa está vazia',
      () async {
    final service = OpenStreetMapService(
        client: MockClient((request) async => request.method == 'POST'
            ? overpass([])
            : photon([
                feature(1, 'shop', 'car_repair', 'Oficina João'),
              ])));
    addTearDown(service.dispose);
    final result = await service.searchWorkshopsByName('Joao', center);
    expect(result.single.name, 'Oficina João');
    expect((result as WorkshopSearchResult).isComplete, isFalse);
  });

  test('restaurante por nome é rejeitado em ambos os provedores', () async {
    final service = OpenStreetMapService(
        client: MockClient((request) async => request.method == 'POST'
            ? overpass([
                element(1, {'amenity': 'restaurant', 'name': 'Central'})
              ])
            : photon([feature(1, 'amenity', 'restaurant', 'Central')])));
    addTearDown(service.dispose);
    expect(await service.searchWorkshopsByName('Central', center), isEmpty);
  });

  test('nova tentativa preserva a área escolhida no mapa', () async {
    final fake = FakeDiscovery();
    final provider = WorkshopProvider(openStreetMapService: fake);
    addTearDown(provider.dispose);
    await provider.initialize(searchOnStart: false);
    const box = (south: -19.93, west: -43.95, north: -19.91, east: -43.93);
    await provider.searchWorkshops(customCenter: center, boundingBox: box);
    await provider.retrySearch();
    expect(fake.nearbyCalls, 2);
    expect(fake.lastCenter, center);
    expect(fake.lastBounds, box);
  });

  test('requisições simultâneas da mesma área compartilham uma consulta',
      () async {
    int calls = 0;
    final response = Completer<http.Response>();
    final service = OpenStreetMapService(client: MockClient((_) {
      calls++;
      return response.future;
    }));
    addTearDown(service.dispose);
    final first = service.searchNearbyWorkshops(center);
    final second = service.searchNearbyWorkshops(center);
    await Future<void>.delayed(Duration.zero);
    response.complete(overpass([
      element(1, {'shop': 'tyres'})
    ]));
    expect(await first, hasLength(1));
    expect(await second, hasLength(1));
    expect(calls, 1);
  });

  test('remark de timeout tenta outra fonte em vez de devolver sucesso vazio',
      () async {
    int calls = 0;
    final service = OpenStreetMapService(client: MockClient((_) async {
      calls++;
      return calls == 1
          ? overpass([], remark: 'runtime error: Query timed out')
          : overpass([
              element(1, {'shop': 'tyres'})
            ]);
    }));
    addTearDown(service.dispose);
    expect(await service.searchNearbyWorkshops(center), hasLength(1));
    expect(calls, 2);
  });

  test('resposta parcial preserva dados e avisa; falha total gera erro',
      () async {
    final partial = OpenStreetMapService(
        client: MockClient((request) async => request.method == 'POST'
            ? overpass([
                element(1, {'shop': 'car_repair'})
              ], remark: 'Query timed out')
            : photon([])));
    addTearDown(partial.dispose);
    final result = await partial.searchNearbyWorkshops(center);
    expect(result, hasLength(1));
    expect((result as WorkshopSearchResult).isComplete, isFalse);
    final failed = OpenStreetMapService(
        client: MockClient((_) async => http.Response('erro', 503)));
    addTearDown(failed.dispose);
    await expectLater(
        failed.searchNearbyWorkshops(const LatLng(0, 0)), throwsException);
  });

  test('timeout cancela requisição HTTP', () async {
    int aborts = 0;
    final service = OpenStreetMapService(
        requestTimeout: const Duration(milliseconds: 10),
        client: MockClient.streaming((request, _) async {
          if (request.method != 'POST') {
            return http.StreamedResponse(
                Stream.value(utf8.encode('{"features":[]}')), 200);
          }
          await (request as http.AbortableRequest).abortTrigger;
          aborts++;
          throw http.RequestAbortedException(request.url);
        }));
    addTearDown(service.dispose);
    await expectLater(service.searchNearbyWorkshops(center), throwsException);
    expect(aborts, 2);
  });

  test('acentos são opcionais e cidade não exige endereço completo no cadastro',
      () async {
    final fake = FakeDiscovery();
    final provider = WorkshopProvider(openStreetMapService: fake);
    addTearDown(provider.dispose);
    await provider.initialize(searchOnStart: false);
    await provider.searchWorkshops(query: 'Belo Horizonte');
    expect(provider.searchQuery, isEmpty);
    expect(provider.getFilteredWorkshops(null), hasLength(1));
    provider.setSearchQuery('joao');
    expect(provider.getFilteredWorkshops(null), hasLength(1));
    provider.setSearchQuery('mecanica');
    expect(provider.getFilteredWorkshops(null), hasLength(1));
    await provider.searchWorkshops(query: 'oficina');
    expect(fake.nearbyCalls, 2);
  });

  test('correspondência local ainda busca outros estabelecimentos por nome',
      () async {
    final fake = FakeDiscovery()
      ..named = [workshop(1), workshop(2, name: 'Oficina João 2')];
    final provider = WorkshopProvider(openStreetMapService: fake);
    addTearDown(provider.dispose);
    await provider.initialize(searchOnStart: false);
    await provider.searchWorkshops(customCenter: center);
    await provider.searchWorkshops(query: 'João');
    expect(fake.nameCalls, 1);
    expect(provider.getFilteredWorkshops(null), hasLength(2));
  });

  test('troca de área remove resultados antigos e cadastros distantes',
      () async {
    final fake = FakeDiscovery();
    final provider = WorkshopProvider(openStreetMapService: fake);
    addTearDown(provider.dispose);
    await provider.initialize(searchOnStart: false);
    await provider.searchWorkshops(customCenter: center);
    await provider.registerCustomWorkshop(
        workshop(8, point: const LatLng(-23.55, -46.63)));
    expect(provider.getFilteredWorkshops(null), hasLength(1));
    fake.nearby = [workshop(2, point: const LatLng(-23.55, -46.63))];
    await provider.searchWorkshops(customCenter: const LatLng(-23.55, -46.63));
    expect(provider.workshops.single.id, 'osm:node:2');
    expect(provider.getFilteredWorkshops(null).any((w) => w.id == 'osm:node:1'),
        isFalse);
  });

  test('provider expõe aviso parcial e encontra serviço adicional da oficina',
      () async {
    final fake = FakeDiscovery()
      ..nearby = WorkshopSearchResult([
        workshop(1,
            tags: {'shop': 'car_repair', 'service:vehicle:oil_change': 'yes'}),
      ], isComplete: false);
    final provider = WorkshopProvider(openStreetMapService: fake);
    addTearDown(provider.dispose);
    await provider.initialize(searchOnStart: false);
    await provider.searchWorkshops(customCenter: center);
    expect(provider.searchNotice, isNotNull);
    provider.setSelectedCategory(WorkshopCategory.oilChange);
    expect(provider.getFilteredWorkshops(null), hasLength(1));
  });

  test('atualização parcial preserva locais conhecidos dentro do novo viewport',
      () async {
    final fake = FakeDiscovery()
      ..nearby =
          WorkshopSearchResult([workshop(1), workshop(2)], isComplete: false);
    final provider = WorkshopProvider(openStreetMapService: fake);
    addTearDown(provider.dispose);
    await provider.initialize(searchOnStart: false);
    await provider.searchWorkshops(customCenter: center);
    fake.nearby = WorkshopSearchResult([workshop(1)], isComplete: false);
    await provider.searchWorkshops(
        customCenter: center,
        boundingBox: (
          south: -19.925,
          west: -43.945,
          north: -19.915,
          east: -43.935
        ),
        automatic: true);
    expect(provider.getFilteredWorkshops(null).map((w) => w.id).toSet(),
        {'osm:node:1', 'osm:node:2'});
    expect(provider.searchNotice, isNotNull);
    fake.nearby = WorkshopSearchResult([workshop(1)]);
    await provider.searchWorkshops(customCenter: center, forceRefresh: true);
    expect(provider.getFilteredWorkshops(null).single.id, 'osm:node:1');
  });

  test(
      'nome inexistente na região retorna vazio quando Overpass falha e fallbacks respondem',
      () async {
    final service = OpenStreetMapService(
        client: MockClient((request) async {
      if (request.method == 'POST') {
        return overpass([], remark: 'runtime error: Query timed out');
      }
      if (request.url.host.contains('nominatim')) {
        return http.Response('[]', 200);
      }
      return photon([]);
    }));
    addTearDown(service.dispose);
    final result =
        await service.searchWorkshopsByName('mecanica quantica', center);
    expect(result, isEmpty);
    expect((result as WorkshopSearchResult).isComplete, isFalse);
  });

  test('busca por nome ainda falha quando nenhuma fonte responde', () async {
    final service = OpenStreetMapService(
        client: MockClient((_) async => http.Response('erro', 503)));
    addTearDown(service.dispose);
    await expectLater(
        service.searchWorkshopsByName('mecanica quantica', center),
        throwsException);
  });

  test('nome sem resultados e que não é cidade mostra lista vazia sem erro',
      () async {
    final fake = _NoCityDiscovery();
    final provider = WorkshopProvider(openStreetMapService: fake);
    addTearDown(provider.dispose);
    await provider.initialize(searchOnStart: false);
    await provider.searchWorkshops(customCenter: center);
    await provider.searchWorkshops(query: 'mecanica quantica');
    expect(fake.nameCalls, 1);
    expect(provider.errorMessage, isNull);
    expect(provider.workshops, isEmpty);
  });
}

class _NoCityDiscovery extends FakeDiscovery {
  @override
  Future<LatLng> geocodeCity(String city) async =>
      throw Exception('Local não encontrado.');
}
