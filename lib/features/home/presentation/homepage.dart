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
                    Color(0xFF1D1822),
                    Color(0xFF2A2431),
                    Color(0xFF352B39),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFF8F1E7), // cream
                    Color(0xFFF6E4DC), // peach cream
                    Color(0xFFEADFF2), // lavender mist
                    Color(0xFFDDEBF0), // faded blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 30,
              right: -30,
              child: _SoftBlob(
                size: 140,
                color:
                    isDark ? const Color(0x55D6BEDF) : const Color(0x66E9C9D0),
              ),
            ),
            Positioned(
              top: 180,
              left: -40,
              child: _SoftBlob(
                size: 120,
                color:
                    isDark ? const Color(0x44B8D3DE) : const Color(0x66D8E8EE),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -20,
              child: _SoftBlob(
                size: 110,
                color:
                    isDark ? const Color(0x44D8C8B8) : const Color(0x55F0D8C8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
              child: ListView(
                children: [
                  const SizedBox(height: 18),
                  _HomeOptionCard(
                    icon: Icons.category_outlined,
                    title: l10n.categories,
                    subtitle: l10n.categoriesSubtitle,
                    iconColors: const [
                      Color(0xFFD7B7C8),
                      Color(0xFFE8C7A8),
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CategoriesPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _HomeOptionCard(
                    icon: Icons.collections_bookmark_outlined,
                    title: l10n.collections,
                    subtitle: l10n.collectionsSubtitle,
                    iconColors: const [
                      Color(0xFFCDBCE8),
                      Color(0xFFAFCFE0),
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CollectionsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _HomeOptionCard(
                    icon: Icons.add_photo_alternate_outlined,
                    title: l10n.addItem,
                    subtitle: l10n.addItemSubtitle,
                    iconColors: const [
                      Color(0xFFE4B8B0),
                      Color(0xFFF0D3B8),
                    ],
                    onTap: () => onGoToTab(2),
                  ),
                  const SizedBox(height: 14),
                  _HomeOptionCard(
                    icon: Icons.camera_alt_outlined,
                    title: tr(context,
                        es: 'Análisis de imagen', en: 'Image analysis'),
                    subtitle: tr(
                      context,
                      es: 'Toma una foto y busca coincidencias en tu colección.',
                      en: 'Take a photo and search for matches in your collection.',
                    ),
                    iconColors: const [
                      Color(0xFFBFD6CF),
                      Color(0xFFD9E7C2),
                    ],
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
                    iconColors: const [
                      Color(0xFFAFCFE0),
                      Color(0xFFD7B7C8),
                    ],
                    onTap: () => onGoToTab(1),
                  ),
                  const SizedBox(height: 14),
                  _HomeOptionCard(
                    icon: Icons.backup_outlined,
                    title: l10n.backup,
                    subtitle: l10n.backupSubtitle,
                    iconColors: const [
                      Color(0xFFE3C8B2),
                      Color(0xFFD6C5E9),
                    ],
                    onTap: () => onGoToTab(3),
                  ),
                  const SizedBox(height: 14),
                  _HomeOptionCard(
                    icon: Icons.settings_outlined,
                    title: l10n.settings,
                    subtitle: l10n.settingsSubtitle,
                    iconColors: const [
                      Color(0xFFD8D1C7),
                      Color(0xFFC7D9D1),
                    ],
                    onTap: () => onGoToTab(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HomeHeroCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF342E3B),
                  Color(0xFF2D2834),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFFFFFBF6),
                  Color(0xFFF8EEE7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEADCCF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE8C7D1),
                  Color(0xFFD8D2F0),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF5F5068),
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: isDark
                        ? const Color(0xFFF3E9DE)
                        : const Color(0xFF534657),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: isDark
                        ? Colors.white.withOpacity(0.76)
                        : const Color(0xFF7A6D68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeServerStatusAction extends StatelessWidget {
  const _HomeServerStatusAction();

  Color _statusColor(ServerSyncState state) {
    switch (state) {
      case ServerSyncState.synced:
        return const Color(0xFF7FA88B);
      case ServerSyncState.syncing:
      case ServerSyncState.checking:
        return const Color(0xFFD8A86E);
      case ServerSyncState.disconnected:
      case ServerSyncState.error:
        return const Color(0xFFC97D7D);
      case ServerSyncState.idle:
        return const Color(0xFFE7DDD2);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.68),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE8D9CC),
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
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF5EBE1)
                          : const Color(0xFF6B5D59),
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
  final List<Color> iconColors;

  const _HomeOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.iconColors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [
                      Color(0xFF302A35),
                      Color(0xFF28232D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFFFFFCF8),
                      Color(0xFFF9F1EA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFEADCCE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.10 : 0.05),
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
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: iconColors),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: iconColors.first.withOpacity(0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF5D4E56),
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
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFF3E9DE)
                              : const Color(0xFF544857),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.3,
                          color: isDark
                              ? Colors.white.withOpacity(0.68)
                              : const Color(0xFF7D6F6B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? Colors.white.withOpacity(0.65)
                      : const Color(0xFFA39690),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
