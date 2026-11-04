import 'package:flutter/material.dart';

import '../widgets/liquid_glass_nav_bar.dart';
import 'activity_screen.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'vehicle_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExploreScreen(),
    FavoritesScreen(),
    VehicleScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: LiquidGlassNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

