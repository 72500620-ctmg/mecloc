import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mecloc/main.dart';
import 'package:mecloc/providers/workshop_provider.dart';

void main() {
  testWidgets('app starts on the nearby workshops screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WorkshopProvider()..initialize(),
        child: const MecLocApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Oficinas perto de você'), findsOneWidget);
    expect(find.text('Buscar perto de mim'), findsOneWidget);
  });
}
