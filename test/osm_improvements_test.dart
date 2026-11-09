import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/services/open_street_map_service.dart';

void main() {
  group('OSM & Overpass Enhancements Tests', () {
    test('derives friendly default names for unnamed establishments', () {
      final carWashJson = {
        'type': 'way',
        'id': 1001,
        'center': {'lat': -19.92, 'lon': -43.94},
        'tags': {
          'amenity': 'car_wash',
          'building': 'yes',
        },
      };

      final tyreShopJson = {
        'type': 'way',
        'id': 1002,
        'center': {'lat': -19.93, 'lon': -43.95},
        'tags': {
          'shop': 'tyres',
          'building': 'yes',
        },
      };

      final namedCarRepairJson = {
        'type': 'way',
        'id': 1003,
        'center': {'lat': -19.94, 'lon': -43.96},
        'tags': {
          'shop': 'car_repair',
          'name': 'Wolmec',
        },
      };

      final carWash = Workshop.fromOverpassJson(carWashJson);
      expect(carWash.name, 'Lava-Jato');
      expect(carWash.categoryType, WorkshopCategory.carWash);
      expect(carWash.latitude, -19.92);
      expect(carWash.longitude, -43.94);

      final tyreShop = Workshop.fromOverpassJson(tyreShopJson);
      expect(tyreShop.name, 'Borracharia / Pneus');
      expect(tyreShop.categoryType, WorkshopCategory.tireShop);

      final namedShop = Workshop.fromOverpassJson(namedCarRepairJson);
      expect(namedShop.name, 'Wolmec');
      expect(namedShop.categoryType, WorkshopCategory.mechanic);
    });

    test('searches with bounding box when supplied', () async {
      String? sentQuery;
      final client = MockClient((request) async {
        sentQuery = request.bodyFields['data'];
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'way',
                'id': 999,
                'center': {'lat': -19.927, 'lon': -43.961},
                'tags': {
                  'name': 'MINAS PNEUS',
                  'shop': 'tyres',
                  'addr:street': 'Avenida Francisco Sá',
                },
              },
            ],
          }),
          200,
        );
      });

      final service = OpenStreetMapService(client: client);
      addTearDown(service.dispose);

      final results = await service.searchNearbyWorkshops(
        const LatLng(-19.927, -43.961),
        boundingBox: (
          south: -19.935,
          west: -43.970,
          north: -19.920,
          east: -43.950,
        ),
      );

      expect(sentQuery, contains('["shop"="tyres"]'));
      expect(sentQuery, isNot(contains('around:')));
      expect(sentQuery, contains('out center tags;'));
      expect(results, hasLength(1));
      expect(results.first.name, 'MINAS PNEUS');
      expect(results.first.categoryType, WorkshopCategory.tireShop);
      expect(results.first.address, contains('Avenida Francisco Sá'));
    });
  });
}
