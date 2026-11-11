import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_assets.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';

/// Contenedor de las secciones principales con barra de navegación
/// (inferior en teléfonos, lateral en tablet/escritorio).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final _destinations = [
    (AppAssets.inicio, 'Inicio'),
    (AppAssets.historial, 'Historial'),
    (AppAssets.clima, 'Clima'),
  ];

  void _go(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (asset, label) in _destinations)
                  NavigationRailDestination(
                    icon: ModuleIcon(asset, size: 26, dimmed: true),
                    selectedIcon: ModuleIcon(asset, size: 26),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final (asset, label) in _destinations)
            NavigationDestination(
              icon: ModuleIcon(asset, size: 26, dimmed: true),
              selectedIcon: ModuleIcon(asset, size: 26),
              label: label,
            ),
        ],
      ),
    );
  }
}
