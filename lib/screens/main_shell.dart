import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/mecloc_brand.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'vehicle_screen.dart';

class MainShellNavigation {
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static void switchToTab(int index) {
    if (index >= 0 && index < 4) tabIndex.value = index;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  static const _destinations = [
    (icon: Icons.map_outlined, selected: Icons.map_rounded, label: 'Explorar'),
    (icon: Icons.favorite_border, selected: Icons.favorite, label: 'Favoritos'),
    (
      icon: Icons.directions_car_outlined,
      selected: Icons.directions_car,
      label: 'Veículos'
    ),
    (
      icon: Icons.person_outline_rounded,
      selected: Icons.person_rounded,
      label: 'Perfil'
    ),
  ];

  @override
  void initState() {
    super.initState();
    MainShellNavigation.tabIndex.value = 0;
    MainShellNavigation.tabIndex.addListener(_onTabNavChange);
  }

  @override
  void dispose() {
    MainShellNavigation.tabIndex.removeListener(_onTabNavChange);
    super.dispose();
  }

  void _onTabNavChange() {
    if (mounted && index != MainShellNavigation.tabIndex.value) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => index = MainShellNavigation.tabIndex.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = IndexedStack(index: index, children: const [
      ExploreScreen(),
      FavoritesScreen(),
      VehicleScreen(),
      ProfileScreen(),
    ]);

    return Scaffold(
      body: Row(children: [
        if (wide) ...[
          NavigationRail(
            backgroundColor: colors.surface,
            selectedIndex: index,
            onDestinationSelected: MainShellNavigation.switchToTab,
            labelType: NavigationRailLabelType.all,
            minWidth: 92,
            groupAlignment: -0.6,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: MecLocBrand(compact: true),
            ),
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selected),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          VerticalDivider(width: 1, color: colors.outline),
        ],
        Expanded(child: content),
      ]),
      bottomNavigationBar: wide || keyboardOpen
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  color: isDark ? const Color(0xFF273140) : AppColors.slateInk,
                  borderRadius: BorderRadius.circular(26),
                  clipBehavior: Clip.antiAlias,
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      height: 68,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      indicatorColor: AppColors.cobaltPrimary,
                      iconTheme: WidgetStateProperty.resolveWith(
                          (states) => IconThemeData(
                                size: 22,
                                color: states.contains(WidgetState.selected)
                                    ? Colors.white
                                    : const Color(0xFFB6C4D8),
                              )),
                      labelTextStyle:
                          WidgetStateProperty.resolveWith((states) => TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    states.contains(WidgetState.selected)
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color: states.contains(WidgetState.selected)
                                    ? Colors.white
                                    : const Color(0xFFB6C4D8),
                              )),
                    ),
                    child: NavigationBar(
                      selectedIndex: index,
                      onDestinationSelected: MainShellNavigation.switchToTab,
                      destinations: _destinations
                          .map((d) => NavigationDestination(
                                icon: Icon(d.icon),
                                selectedIcon: Icon(d.selected),
                                label: d.label,
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
