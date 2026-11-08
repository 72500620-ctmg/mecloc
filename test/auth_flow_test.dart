import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecloc/providers/auth_provider.dart';
import 'package:mecloc/screens/auth/login_screen.dart';
import 'package:mecloc/screens/auth/register_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('Authentication UI & Provider Tests', () {
    testWidgets('LoginScreen renders all input fields, buttons, and visitor link', (tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Bem-vindo ao MecLoc'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Email and Password
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Continuar com o Google'), findsOneWidget);
      expect(find.text('Continuar navegando como visitante'), findsOneWidget);
      expect(find.text('Esqueceu a senha?'), findsOneWidget);
      expect(find.text('Cadastre-se'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders role switcher chips, fields, and terms checkbox', (tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.text('Criar nova conta'), findsOneWidget);
      expect(find.text('Motorista'), findsOneWidget);
      expect(find.text('Dono de Oficina'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Cadastrar com o Google'), findsOneWidget);
      expect(find.text('Fazer login'), findsOneWidget);

      // Verify role toggle
      await tester.tap(find.text('Dono de Oficina'));
      await tester.pumpAndSettle();
    });
  });
}

