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
}
