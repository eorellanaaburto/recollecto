import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../collections/data/collection_logo_storage_service.dart';
import '../../collections/data/collection_repository.dart';
import '../../collections/domain/models/collection_with_category_model.dart';
import '../../items/data/item_repository.dart';
import '../../items/domain/models/item_gallery_model.dart';
import 'collection_items_page.dart';

enum _CollectionCardAction {
  addLogo,
  changeLogo,
  removeLogo,
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ItemRepository _itemRepository = ItemRepository();
  final CollectionRepository _collectionRepository = CollectionRepository();
  final CollectionLogoStorageService _logoStorageService =
      CollectionLogoStorageService();

  final List<ItemGalleryModel> _items = [];
  final List<CollectionWithCategoryModel> _collections = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final items = await _itemRepository.getAllItemsForGallery();
      final collections = await _collectionRepository.getAllCollections();

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(items);

        _collections
          ..clear()
          ..addAll(collections);

        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading gallery collections: $e');
      debugPrint('$st');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              es: 'Error cargando el explorador.',
              en: 'Error loading explorer.',
            ),
          ),
        ),
      );
    }
  }

  Map<String, List<_CollectionGroup>> _groupCollectionsByCategory() {
    final itemsByCollectionId = <String, List<ItemGalleryModel>>{};

    for (final item in _items) {
      itemsByCollectionId.putIfAbsent(item.collectionId, () => []);
      itemsByCollectionId[item.collectionId]!.add(item);
    }

    final grouped = <String, List<_CollectionGroup>>{};

    for (final collection in _collections) {
      final collectionItems = List<ItemGalleryModel>.from(
        itemsByCollectionId[collection.id] ?? const [],
      )..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      final visualPath = _resolveVisualPath(
        logoPath: collection.logoPath,
        items: collectionItems,
      );

      final entry = _CollectionGroup(
        categoryId: collection.categoryId,
        categoryName: collection.categoryName,
        collectionId: collection.id,
        collectionName: collection.name,
        logoPath: collection.logoPath,
        visualPath: visualPath,
        items: collectionItems,
      );

      grouped.putIfAbsent(collection.categoryName, () => []);
      grouped[collection.categoryName]!.add(entry);
    }

    for (final list in grouped.values) {
      list.sort((a, b) {
        return a.collectionName.toLowerCase().compareTo(
              b.collectionName.toLowerCase(),
            );
      });
    }

    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );
  }

  String? _resolveVisualPath({
    required String? logoPath,
    required List<ItemGalleryModel> items,
  }) {
    if (logoPath != null &&
        logoPath.isNotEmpty &&
        File(logoPath).existsSync()) {
      return logoPath;
    }

    for (final item in items) {
      final path = item.primaryPhotoPath;
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        return path;
      }
    }

    return null;
  }

  int _countItemsInCategory(List<_CollectionGroup> collections) {
    int total = 0;
    for (final collection in collections) {
      total += collection.items.length;
    }
    return total;
  }

  Future<void> _openCollection(_CollectionGroup collection) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionItemsPage(
          categoryName: collection.categoryName,
          collectionName: collection.collectionName,
          items: collection.items,
          coverPhotoPath: collection.visualPath,
        ),
      ),
    );

    if (changed == true) {
      await _loadData();
    }
  }

  Future<void> _setLogo(_CollectionGroup collection) async {
    final savedPath = await _logoStorageService.pickAndSaveLogo(
      collectionId: collection.collectionId,
    );

    if (savedPath == null) return;

    await _collectionRepository.updateCollectionLogo(
      collectionId: collection.collectionId,
      logoPath: savedPath,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            es: 'Logo guardado correctamente.',
            en: 'Logo saved successfully.',
          ),
        ),
      ),
    );

    await _loadData();
  }

  Future<void> _removeLogo(_CollectionGroup collection) async {
    await _logoStorageService.deleteLogoByPath(collection.logoPath);

    await _collectionRepository.updateCollectionLogo(
      collectionId: collection.collectionId,
      logoPath: null,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            es: 'Logo eliminado.',
            en: 'Logo removed.',
          ),
        ),
      ),
    );

    await _loadData();
  }

  Future<void> _handleCollectionAction(
    _CollectionCardAction action,
    _CollectionGroup collection,
  ) async {
    switch (action) {
      case _CollectionCardAction.addLogo:
      case _CollectionCardAction.changeLogo:
        await _setLogo(collection);
        break;
      case _CollectionCardAction.removeLogo:
        await _removeLogo(collection);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupCollectionsByCategory();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(context, es: 'Explorar colección', en: 'Explore collection'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _collections.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              tr(
                                context,
                                es: 'Todavía no tienes colecciones guardadas.',
                                en: 'You do not have any collections yet.',
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: grouped.entries.map((categoryEntry) {
                        final categoryName = categoryEntry.key;
                        final collections = categoryEntry.value;
                        final totalItems = _countItemsInCategory(collections);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            title: Text(
                              categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${tr(context, es: '${collections.length} colecciones', en: '${collections.length} collections')} • '
                              '${tr(context, es: '$totalItems ítems', en: '$totalItems items')}',
                            ),
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth;

                                    int crossAxisCount = 2;
                                    if (width >= 1000) {
                                      crossAxisCount = 4;
                                    } else if (width >= 700) {
                                      crossAxisCount = 3;
                                    }

                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: collections.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.86,
                                      ),
                                      itemBuilder: (context, index) {
                                        final collection = collections[index];

                                        return _CollectionCard(
                                          collection: collection,
                                          onTap: () =>
                                              _openCollection(collection),
                                          onSelectedAction: (action) {
                                            _handleCollectionAction(
                                              action,
                                              collection,
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
    );
  }
}

class _CollectionGroup {
  final String categoryId;
  final String categoryName;
  final String collectionId;
  final String collectionName;
  final String? logoPath;
  final String? visualPath;
  final List<ItemGalleryModel> items;

  const _CollectionGroup({
    required this.categoryId,
    required this.categoryName,
    required this.collectionId,
    required this.collectionName,
    required this.logoPath,
    required this.visualPath,
    required this.items,
  });
}

class _CollectionCard extends StatelessWidget {
  final _CollectionGroup collection;
  final VoidCallback onTap;
  final ValueChanged<_CollectionCardAction> onSelectedAction;

  const _CollectionCard({
    required this.collection,
    required this.onTap,
    required this.onSelectedAction,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = collection.visualPath;
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    final hasRealLogo = collection.logoPath != null &&
        collection.logoPath!.isNotEmpty &&
        File(collection.logoPath!).existsSync();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasImage
                        ? Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(
                                Icons.collections_bookmark_outlined,
                                size: 42,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      child: PopupMenuButton<_CollectionCardAction>(
                        tooltip: tr(context, es: 'Logo', en: 'Logo'),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        onSelected: onSelectedAction,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: hasRealLogo
                                ? _CollectionCardAction.changeLogo
                                : _CollectionCardAction.addLogo,
                            child: Text(
                              hasRealLogo
                                  ? tr(context,
                                      es: 'Cambiar logo', en: 'Change logo')
                                  : tr(context,
                                      es: 'Agregar logo', en: 'Add logo'),
                            ),
                          ),
                          if (hasRealLogo)
                            PopupMenuItem(
                              value: _CollectionCardAction.removeLogo,
                              child: Text(
                                tr(context,
                                    es: 'Quitar logo', en: 'Remove logo'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        collection.collectionName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  if (hasRealLogo)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tr(context, es: 'Logo', en: 'Logo'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tr(
                            context,
                            es: '${collection.items.length} ítems',
                            en: '${collection.items.length} items',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
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
