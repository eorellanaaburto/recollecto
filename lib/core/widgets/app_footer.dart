import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.photo_library_outlined),
          selectedIcon: const Icon(Icons.photo_library),
          label: l10n.explore,
        ),
        NavigationDestination(
          icon: const Icon(Icons.add_box_outlined),
          selectedIcon: const Icon(Icons.add_box),
          label: l10n.add,
        ),
        NavigationDestination(
          icon: const Icon(Icons.backup_outlined),
          selectedIcon: const Icon(Icons.backup),
          label: l10n.backup,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settings,
        ),
      ],
    );
  }
}
