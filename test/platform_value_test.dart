import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mecloc/models/maintenance_item.dart';
import 'package:mecloc/models/vehicle.dart';
import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/providers/quotes_provider.dart';
import 'package:mecloc/providers/workshop_provider.dart';

void main() {
  group('WhatsApp Quotes Formatting & Normalization', () {
    test('normalizes Brazilian phone numbers properly for WhatsApp URL', () {
      expect(QuotesProvider.formatPhoneForWhatsApp('(11) 98765-4321'), '5511987654321');
      expect(QuotesProvider.formatPhoneForWhatsApp('011987654321'), '5511987654321');
      expect(QuotesProvider.formatPhoneForWhatsApp('+55 (21) 99999-8888'), '5521999998888');
      expect(QuotesProvider.formatPhoneForWhatsApp('5511987654321'), '5511987654321');
    });

    test('generates formatted quote message with vehicle and service data', () {
      const workshop = Workshop(
        id: 'w1',
        name: 'Auto Mecânica Silva',
        address: 'Rua das Flores, 100',
        phone: '11987654321',
      );
      const vehicle = Vehicle(
        id: 'v1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2021,
        engine: '1.4 TSI Turbo 150cv',
        fuel: 'Flex',
        transmission: 'Automático',
        version: 'Highline',
        plate: 'BRA2E19',
      );

      final message = QuotesProvider.generateWhatsAppMessage(
        workshop: workshop,
        vehicle: vehicle,
        serviceName: 'Troca de Óleo e Filtros',
        notes: 'Cliente prefere óleo sintético 5W40',
      );

      expect(message, contains('Auto Mecânica Silva'));
      expect(message, contains('MecLoc'));
      expect(message, contains('Troca de Óleo e Filtros'));
      expect(message, contains('Volkswagen Golf Highline (2021)'));
      expect(message, contains('BRA2E19'));
      expect(message, contains('Cliente prefere óleo sintético 5W40'));
    });
  });

  group('Custom Workshop Registration & Marketplace', () {
    test('custom registered workshops are saved and prioritized at the top of results', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = WorkshopProvider();
      await provider.initialize(searchOnStart: false);

      expect(provider.customWorkshops, isEmpty);

      const customWorkshop = Workshop(
        id: 'custom_123',
        name: 'Auto Center Especializado',
        address: 'Av. Brasil, 500',
        phone: '11999991111',
        category: 'Auto Center',
        categoryType: WorkshopCategory.autoCenter,
        isCustomRegistered: true,
        isVerified: true,
      );

      await provider.registerCustomWorkshop(customWorkshop);
      expect(provider.customWorkshops.length, 1);
      expect(provider.customWorkshops.first.name, 'Auto Center Especializado');

      final filtered = provider.getFilteredWorkshops(null);
      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.first.id, 'custom_123');
      expect(filtered.first.isCustomRegistered, isTrue);
    });

    test('claimed workshop retains coordinates and supersedes OSM workshop with same name on map', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = WorkshopProvider();
      await provider.initialize(searchOnStart: false);

      const claimedWorkshop = Workshop(
        id: 'custom_claimed_1',
        name: 'Oficina Central OSM',
        address: 'Rua Principal, 100',
        latitude: -23.5505,
        longitude: -46.6333,
        phone: '11988887777',
        category: 'Oficina Mecânica',
        isCustomRegistered: true,
        isVerified: true,
      );

      await provider.registerCustomWorkshop(claimedWorkshop);

      final filtered = provider.getFilteredWorkshops(null);
      expect(filtered.length, 1);
      final first = filtered.first;
      expect(first.name, 'Oficina Central OSM');
      expect(first.latitude, -23.5505);
      expect(first.longitude, -46.6333);
      expect(first.isCustomRegistered, isTrue);
    });
  });

  group('Vehicle Mileage & Preventive Maintenance Calculations', () {
    test('calculates correct status for maintenance items based on mileage', () {
      // Carro com 48.500 km
      // Óleo trocado aos 40.000 km (intervalo 10.000 km -> vence aos 50.000 km) -> faltam 1.500 km -> warning!
      const vehicle = Vehicle(
        id: 'v1',
        brand: 'Toyota',
        model: 'Corolla',
        year: 2020,
        engine: '2.0 Flex',
        fuel: 'Flex',
        transmission: 'CVT',
        version: 'XEi',
        mileageKm: 48500,
        lastOilChangeKm: 40000,
        lastBrakesKm: 30000, // intervalo 20.000 km -> vence aos 50.000 km -> faltam 1.500 km -> warning
        lastTimingBeltKm: 0, // intervalo 50.000 km -> vence aos 50.000 km -> faltam 1.500 km -> warning
        lastFiltersKm: 40000,
      );

      final items = vehicle.getMaintenanceList();
      expect(items.length, 4);

      final oilItem = items.firstWhere((i) => i.id == 'oil_filter');
      expect(oilItem.kmRemaining(vehicle.mileageKm), 1500);
      expect(oilItem.getStatus(vehicle.mileageKm), MaintenanceStatus.warning);
      expect(oilItem.statusBadgeLabel(vehicle.mileageKm), 'Próximo');

      // Se o carro rodar até 51.000 km sem troca de óleo:
      final overdueVehicle = vehicle.copyWith(mileageKm: 51000);
      final overdueOilItem = overdueVehicle.getMaintenanceList().firstWhere((i) => i.id == 'oil_filter');
      expect(overdueOilItem.kmRemaining(overdueVehicle.mileageKm), -1000);
      expect(overdueOilItem.getStatus(overdueVehicle.mileageKm), MaintenanceStatus.expired);
      expect(overdueOilItem.statusBadgeLabel(overdueVehicle.mileageKm), 'Revisar Já');

      // Se o óleo acabou de ser trocado aos 51.000 km:
      final freshVehicle = overdueVehicle.copyWith(lastOilChangeKm: 51000);
      final freshOilItem = freshVehicle.getMaintenanceList().firstWhere((i) => i.id == 'oil_filter');
      expect(freshOilItem.kmRemaining(freshVehicle.mileageKm), 10000);
      expect(freshOilItem.getStatus(freshVehicle.mileageKm), MaintenanceStatus.ok);
      expect(freshOilItem.statusBadgeLabel(freshVehicle.mileageKm), 'Em dia');
    });
  });
}

