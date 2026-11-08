import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'vehicle_screen.dart';

class MainShellNavigation {
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static void switchToTab(int index) {
    tabIndex.value = index;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    MainShellNavigation.tabIndex.addListener(_onTabNavChange);
  }

  @override
  void dispose() {
    MainShellNavigation.tabIndex.removeListener(_onTabNavChange);
    super.dispose();
  }

  void _onTabNavChange() {
    if (mounted && index != MainShellNavigation.tabIndex.value) {
      setState(() {
        index = MainShellNavigation.tabIndex.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              left: 16,
              right: 16,
              bottom: bottomInset + 12,
              child: Material(
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                color: Theme.of(context).colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.floating),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.slateBorder,
                    width: 1.2,
                  ),
                ),
                child: NavigationBar(
                  height: 66,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  selectedIndex: index,
                  onDestinationSelected: (value) {
                    MainShellNavigation.switchToTab(value);
                  },
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
