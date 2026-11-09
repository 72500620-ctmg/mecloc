import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/providers/workshop_provider.dart';
import 'package:mecloc/services/open_street_map_service.dart';

class FakeSearch extends OpenStreetMapService {
  final requests = <int, Completer<List<Workshop>>>{};
  @override
  Future<LatLng> geocodeCity(String city) async =>
      LatLng(double.parse(city), 0);
  @override
  Future<List<Workshop>> searchNearbyWorkshops(
    LatLng center, {
    int? radiusMeters,
    ({double south, double west, double north, double east})? boundingBox,
  }) =>
      (requests[center.latitude.toInt()] = Completer<List<Workshop>>()).future;
}

Workshop item(int id) => Workshop(
    id: 'osm:node:$id',
    name: 'Oficina $id',
    address: 'Rua $id',
    latitude: id.toDouble(),
    longitude: 0);
void main() {
  test(
      'resposta antiga não substitui busca mais recente; favoritos sobrevivem a outra busca',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeSearch();
    final provider = WorkshopProvider(openStreetMapService: service);
    await provider.initialize(searchOnStart: false);
    final first = provider.searchWorkshops(city: '1');
    await Future<void>.delayed(Duration.zero);
    final second = provider.searchWorkshops(city: '2');
    await Future<void>.delayed(Duration.zero);
    service.requests[2]!.complete([item(2)]);
    await second;
    service.requests[1]!.complete([item(1)]);
    await first;
    expect(provider.workshops.single.id, 'osm:node:2');
    provider.setSearchQuery('inexistente');
    expect(provider.getFilteredWorkshops(null), isEmpty);
    provider.setSearchQuery('oficina');
    expect(provider.getFilteredWorkshops(null), hasLength(1));
    await provider.toggleFavorite('osm:node:2');
    provider.dispose();
    final restored = WorkshopProvider(openStreetMapService: FakeSearch());
    await restored.initialize(searchOnStart: false);
    expect(restored.favoriteWorkshops.single.id, 'osm:node:2');
    restored.dispose();
  });

  test('mapa recebe a cidade mesmo quando a consulta de oficinas falha',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeSearch();
    final provider = WorkshopProvider(openStreetMapService: service);
    await provider.initialize(searchOnStart: false);

    final search = provider.searchWorkshops(city: '3');
    await Future<void>.delayed(Duration.zero);
    expect(provider.searchCenter, const LatLng(3, 0));

    service.requests[3]!.completeError(Exception('Overpass indisponível'));
    await search;

    expect(provider.searchCenter, const LatLng(3, 0));
    expect(provider.errorMessage, 'Overpass indisponível');
    expect(provider.workshops, isEmpty);
    provider.dispose();
  });
}
