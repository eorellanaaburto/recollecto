import 'package:flutter/material.dart';
import 'package:recollecto/core/widgets/app_footer.dart';
import 'package:recollecto/core/widgets/app_header.dart';
import 'package:recollecto/features/gallery/presentation/gallery_page.dart';

import '../../../core/localization/local_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../backup/data/server_sync_service.dart';
import '../../backup/presentation/backup_page.dart';
import '../../categories/presentation/categories_page.dart';
import '../../collections/presentation/collections_page.dart';
import '../../duplicates/presentation/image_analysis_page.dart';
import '../../items/presentation/add_item_page.dart';
import '../../settings/presentation/settings_page.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;
  int _galleryRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
    ServerSyncService.instance.start();
  }

  void _goToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleItemSaved() {
    setState(() {
      _galleryRefreshVersion++;
      _currentIndex = 1;
    });
  }

  List<Widget> get _pages => [
        _DashboardTab(onGoToTab: _goToTab),
        GalleryPage(
          key: ValueKey('gallery_$_galleryRefreshVersion'),
        ),
        AddItemPage(
          onItemSaved: _handleItemSaved,
        ),
        const BackupPage(),
        const SettingsPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: _goToTab,
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final ValueChanged<int> onGoToTab;

  const _DashboardTab({
    required this.onGoToTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.appTitle,
        subtitle: l10n.welcomeSubtitle,
        actions: const [
          _HomeServerStatusAction(),
          SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [
                    Color(0xFF020617),
                    Color(0xFF111827),
                    Color(0xFF1E1B4B),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFF3E8FF),
                    Color(0xFFFCE7F3),
                    Color(0xFFECFEFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
          child: ListView(
            children: [
              _HomeOptionCard(
                icon: Icons.category_outlined,
                title: l10n.categories,
                subtitle: l10n.categoriesSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesPage()),
                  );
                },
              ),
              const SizedBox(height: 14),
              _HomeOptionCard(
                icon: Icons.collections_bookmark_outlined,
                title: l10n.collections,
                subtitle: l10n.collectionsSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CollectionsPage()),
                  );
                },
              ),
              const SizedBox(height: 14),
              _HomeOptionCard(
                icon: Icons.add_photo_alternate_outlined,
                title: l10n.addItem,
                subtitle: l10n.addItemSubtitle,
                onTap: () => onGoToTab(2),
              ),
              const SizedBox(height: 14),
              _HomeOptionCard(
                icon: Icons.camera_alt_outlined,
                title:
                    tr(context, es: 'Análisis de imagen', en: 'Image analysis'),
                subtitle: tr(
                  context,
                  es: 'Toma una foto y busca coincidencias en tu colección.',
                  en: 'Take a photo and search for matches in your collection.',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImageAnalysisPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _HomeOptionCard(
                icon: Icons.photo_library_outlined,
                title: l10n.exploreCollection,
                subtitle: l10n.exploreCollectionSubtitle,
                onTap: () => onGoToTab(1),
              ),
              const SizedBox(height: 14),
              _HomeOptionCard(
                icon: Icons.backup_outlined,
                title: l10n.backup,
                subtitle: l10n.backupSubtitle,
                onTap: () => onGoToTab(3),
              ),
              const SizedBox(height: 14),
              _HomeOptionCard(
                icon: Icons.settings_outlined,
                title: l10n.settings,
                subtitle: l10n.settingsSubtitle,
                onTap: () => onGoToTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeServerStatusAction extends StatelessWidget {
  const _HomeServerStatusAction();

  Color _statusColor(ServerSyncState state) {
    switch (state) {
      case ServerSyncState.synced:
        return const Color(0xFF22C55E);
      case ServerSyncState.syncing:
      case ServerSyncState.checking:
        return const Color(0xFFF59E0B);
      case ServerSyncState.disconnected:
      case ServerSyncState.error:
        return const Color(0xFFEF4444);
      case ServerSyncState.idle:
        return Colors.white70;
    }
  }

  IconData _statusIcon(ServerSyncState state) {
    switch (state) {
      case ServerSyncState.synced:
        return Icons.cloud_done_outlined;
      case ServerSyncState.syncing:
        return Icons.sync;
      case ServerSyncState.checking:
        return Icons.cloud_queue_outlined;
      case ServerSyncState.disconnected:
      case ServerSyncState.error:
        return Icons.cloud_off_outlined;
      case ServerSyncState.idle:
        return Icons.cloud_outlined;
    }
  }

  String _statusText(ServerSyncState state) {
    switch (state) {
      case ServerSyncState.synced:
        return 'Servidor conectado';
      case ServerSyncState.syncing:
        return 'Sincronizando';
      case ServerSyncState.checking:
        return 'Buscando';
      case ServerSyncState.disconnected:
        return 'Sin conexión';
      case ServerSyncState.error:
        return 'Error';
      case ServerSyncState.idle:
        return 'Sin verificar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ServerSyncService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final color = _statusColor(service.state);
        final icon = _statusIcon(service.state);
        final text = _statusText(service.state);

        return Padding(
          padding: const EdgeInsets.only(top: 18, right: 6),
          child: Tooltip(
            message: text,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (service.state == ServerSyncState.syncing)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  else
                    Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF111827).withOpacity(0.96)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFFEC4899),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
