import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecloc/services/open_street_map_service.dart';

void main() {
  test('resultado vazio é diferente de falha', () async {
    final service = OpenStreetMapService(
        client: MockClient(
            (_) async => http.Response(jsonEncode({'elements': []}), 200)));
    addTearDown(service.dispose);
    expect(await service.searchNearbyWorkshops(const LatLng(0, 0)), isEmpty);
  });
  test('falha dos servidores não gera oficinas fictícias', () async {
    final service = OpenStreetMapService(
        client: MockClient((_) async => http.Response('erro', 503)));
    addTearDown(service.dispose);
    await expectLater(
        service.searchNearbyWorkshops(const LatLng(0, 0)), throwsException);
  });
}
