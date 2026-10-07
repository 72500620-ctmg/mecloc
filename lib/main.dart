import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/workshop_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkshopProvider()..initialize(),
      child: const MecLocApp(),
    ),
  );
}

class MecLocApp extends StatelessWidget {
  const MecLocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MecLoc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
