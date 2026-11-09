import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecloc/services/open_street_map_service.dart';

void main() {
  test('geocodes a city through Nominatim', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'nominatim.openstreetmap.org');
      expect(request.url.queryParameters['q'], 'Belo Horizonte');
      return http.Response(
        jsonEncode([
          {'lat': '-19.92', 'lon': '-43.94'},
        ]),
        200,
      );
    });
    final service = OpenStreetMapService(client: client);
    addTearDown(service.dispose);

    final center = await service.geocodeCity('Belo Horizonte');

    expect(center, const LatLng(-19.92, -43.94));
  });

  test('searches and parses workshops from Overpass', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.host, 'overpass-api.de');
      expect(request.bodyFields['data'], contains('"shop"="car_repair"'));
      expect(request.bodyFields['data'], contains('[out:json]'));
      return http.Response(
        jsonEncode({
          'elements': [
            {
              'type': 'node',
              'id': 123,
              'lat': -19.92,
              'lon': -43.94,
              'tags': {'name': 'Oficina Central'},
            },
          ],
        }),
        200,
      );
    });
    final service = OpenStreetMapService(client: client);
    addTearDown(service.dispose);

    final workshops = await service.searchNearbyWorkshops(
      const LatLng(-19.92, -43.94),
    );

    expect(workshops, hasLength(1));
    expect(workshops.single.name, 'Oficina Central');
  });

  test('usa um servidor Overpass alternativo após falha do principal',
      () async {
    final hosts = <String>[];
    final client = MockClient((request) async {
      hosts.add(request.url.host);
      if (request.url.host != 'overpass.private.coffee') {
        return http.Response('serviço temporariamente indisponível', 502);
      }
      return http.Response(
        jsonEncode({
          'elements': [
            {
              'type': 'node',
              'id': 321,
              'lat': -22.90,
              'lon': -47.06,
              'tags': {'name': 'Oficina Alternativa'},
            },
          ],
        }),
        200,
      );
    });
    final service = OpenStreetMapService(client: client);
    addTearDown(service.dispose);

    final workshops = await service.searchNearbyWorkshops(
      const LatLng(-22.9056, -47.0596),
    );

    expect(hosts, [
      'overpass-api.de',
      'lz4.overpass-api.de',
      'overpass.private.coffee',
    ]);
    expect(workshops.single.name, 'Oficina Alternativa');
  });

  test('usa Photon quando Nominatim falha', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'nominatim.openstreetmap.org') {
        return http.Response('temporariamente indisponível', 503);
      }
      expect(request.url.host, 'photon.komoot.io');
      expect(request.url.queryParameters['countrycode'], 'BR');
      return http.Response(
        jsonEncode({
          'features': [
            {
              'geometry': {
                'coordinates': [-46.6333, -23.5505]
              },
              'properties': {'name': 'São Paulo', 'countrycode': 'BR'},
            },
          ],
        }),
        200,
      );
    });
    final service = OpenStreetMapService(client: client);
    addTearDown(service.dispose);

    expect(await service.geocodeCity('São Paulo'),
        const LatLng(-23.5505, -46.6333));
  });
}
