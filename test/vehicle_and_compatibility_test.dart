import 'package:flutter_test/flutter_test.dart';
import 'package:mecloc/models/vehicle.dart';
import 'package:mecloc/models/workshop.dart';

void main() {
  group('Vehicle & Smart Compatibility Tests', () {
    test('Vehicle model properties and display name', () {
      const vehicle = Vehicle(
        id: 'v1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2021,
        engine: '1.4 TSI Turbo',
        fuel: 'Flex',
        transmission: 'Automático',
        version: 'Highline',
        plate: 'BRA2E19',
        isSelected: true,
      );

      expect(vehicle.displayName, 'Volkswagen Golf Highline (2021)');
      expect(vehicle.shortName, 'Volkswagen Golf');
      expect(vehicle.specsSummary, '1.4 TSI Turbo • Flex • Automático');
    });

    test('Compatibility calculation gives 100% specialist score for matching brand and specs', () {
      const vehicle = Vehicle(
        id: 'v1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2021,
        engine: '1.4 TSI Turbo',
        fuel: 'Flex',
        transmission: 'Automático',
        version: 'Highline',
      );

      const workshop = Workshop(
        id: 'w1',
        name: 'Oficina Alemã Precision',
        address: 'Rua Central, 100',
        supportedBrands: ['Volkswagen', 'Audi'],
        specialties: ['Injeção Direta TSI/TFSI', 'Câmbio Automático'],
      );

      final compatibility = workshop.calculateCompatibility(vehicle);

      expect(compatibility.percentage, 100);
      expect(compatibility.isHighMatch, isTrue);
      expect(compatibility.label, contains('100% Especialista'));
      expect(compatibility.reasons, isNotEmpty);
    });

    test('Compatibility calculation handles generic workshops gracefully', () {
      const vehicle = Vehicle(
        id: 'v2',
        brand: 'Honda',
        model: 'Civic',
        year: 2022,
        engine: '2.0',
        fuel: 'Flex',
        transmission: 'CVT',
        version: 'Touring',
      );

      const workshop = Workshop(
        id: 'w2',
        name: 'Oficina Mecânica Multimarcas',
        address: 'Av. Brasil, 500',
        supportedBrands: ['Todas as marcas'],
        specialties: ['Mecânica Geral', 'Freios'],
      );

      final compatibility = workshop.calculateCompatibility(vehicle);

      expect(compatibility.percentage, greaterThanOrEqualTo(80));
      expect(compatibility.label, contains('Compatível'));
    });
  });
}

