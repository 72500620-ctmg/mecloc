import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecloc/models/vehicle.dart';
import 'package:mecloc/providers/auth_provider.dart';
import 'package:mecloc/providers/vehicle_provider.dart';
import 'package:mecloc/providers/workshop_provider.dart';
import 'package:mecloc/screens/main_shell.dart';
import 'package:mecloc/screens/vehicle_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Mode & User Scoped Garage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('VehicleProvider initializes empty for unauthenticated visitors and clears on logout', () async {
      final vehicleProvider = VehicleProvider();
      vehicleProvider.initialize();

      expect(vehicleProvider.vehicles, isEmpty);
      expect(vehicleProvider.activeVehicle, isNull);
      expect(vehicleProvider.currentUserId, isNull);

      // Simula login de um usuário
      await vehicleProvider.syncUser('user_test_123');
      expect(vehicleProvider.currentUserId, 'user_test_123');

      // Adiciona um veículo para o usuário
      const vehicle = Vehicle(
        id: 'v_user_1',
        brand: 'Toyota',
        model: 'Corolla',
        year: 2022,
        engine: '2.0 Dynamic Force',
        fuel: 'Flex',
        transmission: 'CVT',
        version: 'XEi',
        plate: 'ABC1D23',
        isSelected: true,
      );
      await vehicleProvider.addVehicle(vehicle);

      expect(vehicleProvider.vehicles.length, 1);
      expect(vehicleProvider.activeVehicle?.displayName, contains('Toyota Corolla'));

      // Simula logout chamando clearSession
      vehicleProvider.clearSession();
      expect(vehicleProvider.vehicles, isEmpty);
      expect(vehicleProvider.activeVehicle, isNull);
      expect(vehicleProvider.currentUserId, isNull);
    });

    testWidgets('VehicleScreen renders Guest Mode showcase when unauthenticated', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authProvider = AuthProvider();
      final vehicleProvider = VehicleProvider();
      final workshopProvider = WorkshopProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<VehicleProvider>.value(value: vehicleProvider),
            ChangeNotifierProvider<WorkshopProvider>.value(value: workshopProvider),
          ],
          child: const MaterialApp(
            home: VehicleScreen(),
          ),
        ),
      );

      // Garante que o banner e vantagens do Guest Mode são exibidos
      expect(find.text('Garagem na Nuvem MecLoc'), findsOneWidget);
      expect(find.text('VANTAGENS DE CADASTRAR SEU VEÍCULO'), findsOneWidget);
      expect(find.text('Alertas de Revisão Preventiva'), findsOneWidget);
      expect(find.text('Oficinas 100% Compatíveis'), findsOneWidget);
      expect(find.text('Histórico Seguro e Sincronizado'), findsOneWidget);
      expect(find.text('Entrar com minha conta'), findsOneWidget);
      expect(find.text('Criar conta gratuita'), findsOneWidget);
      expect(find.text('Continuar explorando oficinas no mapa'), findsOneWidget);

      // Tenta clicar no botão de adicionar veículo na AppBar
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      // Deve exibir o diálogo de identificação obrigatória
      expect(find.text('Identifique-se'), findsOneWidget);
      expect(
        find.text(
          'Para cadastrar veículos e salvar o histórico de manutenção na nuvem, acesse sua conta ou faça um cadastro rápido.',
        ),
        findsOneWidget,
      );
      expect(find.text('Entrar ou Cadastrar'), findsOneWidget);
    });

    test('MainShellNavigation switches tabs correctly', () {
      expect(MainShellNavigation.tabIndex.value, 0);

      MainShellNavigation.switchToTab(2);
      expect(MainShellNavigation.tabIndex.value, 2);

      MainShellNavigation.switchToTab(0);
      expect(MainShellNavigation.tabIndex.value, 0);
    });
  });
}
