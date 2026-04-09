import 'package:flutter/material.dart';

import '../../core/localization/local_text.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: tr(context, es: 'Inicio', en: 'Home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.photo_library_outlined),
          selectedIcon: const Icon(Icons.photo_library),
          label: tr(context, es: 'Explorar', en: 'Explore'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.add_box_outlined),
          selectedIcon: const Icon(Icons.add_box),
          label: tr(context, es: 'Agregar', en: 'Add'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.backup_outlined),
          selectedIcon: const Icon(Icons.backup),
          label: tr(context, es: 'Respaldo', en: 'Backup'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: tr(context, es: 'Ajustes', en: 'Settings'),
        ),
      ],
    );
  }
}
