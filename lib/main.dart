import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/workshop_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkshopProvider()..initialize(),
      child: const MecLocApp(),
    ),
  );
}

class MecLocApp extends StatefulWidget {
  const MecLocApp({super.key});

  @override
  State<MecLocApp> createState() => _MecLocAppState();
}

class _MecLocAppState extends State<MecLocApp> {
  final _themeController = ThemeController()..load();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeController>.value(
      value: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, _) => MaterialApp(
          title: 'MecLoc',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeController.mode,
          themeAnimationDuration: const Duration(milliseconds: 350),
          themeAnimationCurve: Curves.easeOutCubic,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
