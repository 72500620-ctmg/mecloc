import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: index, children: const [
              ExploreScreen(),
              FavoritesScreen(),
              VehicleScreen(),
              ProfileScreen(),
            ]),
          ),
          if (!keyboardOpen)
            Positioned(
              left: 14,
              right: 14,
              bottom: bottomInset + 10,
              child: Material(
                elevation: 7,
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.floating),
                clipBehavior: Clip.antiAlias,
                child: NavigationBar(
                  height: 66,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      setState(() => index = value),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: 'Explorar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite),
                      label: 'Favoritos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.directions_car_outlined),
                      selectedIcon: Icon(Icons.directions_car),
                      label: 'Veículos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Perfil',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
