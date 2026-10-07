import 'package:flutter_test/flutter_test.dart';
import 'package:mecloc/models/workshop.dart';

void main() {
  test('converts an OpenStreetMap node into a workshop', () {
    final workshop = Workshop.fromOverpassJson({
      'type': 'node',
      'id': 123,
      'lat': -19.92,
      'lon': -43.94,
      'tags': {
        'name': 'Oficina Central',
        'addr:street': 'Rua das Flores',
        'addr:housenumber': '10',
        'addr:city': 'Belo Horizonte',
        'phone': '(31) 3333-4444',
      },
    });

    expect(workshop.id, 'osm:node:123');
    expect(workshop.name, 'Oficina Central');
    expect(workshop.address, 'Rua das Flores, 10 - Belo Horizonte');
    expect(workshop.latitude, -19.92);
    expect(workshop.longitude, -43.94);
    expect(workshop.phone, '(31) 3333-4444');
    expect(
      workshop.openStreetMapUrl,
      'https://www.openstreetmap.org/node/123',
    );
  });

  test('uses way center coordinates and readable fallbacks', () {
    final workshop = Workshop.fromOverpassJson({
      'type': 'way',
      'id': 456,
      'center': {'lat': '1.5', 'lon': '2.5'},
      'tags': {'shop': 'car_repair'},
    });

    expect(workshop.name, 'Oficina mecânica');
    expect(workshop.address, 'Endereço não informado');
    expect(workshop.latitude, 1.5);
    expect(workshop.longitude, 2.5);
    expect(workshop.rating, isNull);
  });
}
