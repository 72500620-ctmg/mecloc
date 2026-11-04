import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/quotes_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/workshop_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => QuotesProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => WorkshopProvider()..initialize()),
      ],
      child: const MecLocApp(),
    ),
  );
}

class MecLocApp extends StatelessWidget {
  const MecLocApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'MecLoc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const MainShell(),
    );
  }
}
