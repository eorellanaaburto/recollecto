import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../items/data/item_repository.dart';
import '../../items/data/photo_storage_service.dart';
import '../../items/domain/models/item_gallery_model.dart';
import '../../items/presentation/edit_item_page.dart';
import '../../items/presentation/item_detail_page.dart';

enum _GalleryItemAction {
  edit,
  delete,
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ItemRepository _itemRepository = ItemRepository();
  final PhotoStorageService _photoStorageService = PhotoStorageService();

  final List<ItemGalleryModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _itemRepository.debugPrintDatabaseState();

      final items = await _itemRepository.getAllItemsForGallery();

      debugPrint('Gallery items loaded: ${items.length}');
      for (final item in items) {
        debugPrint(
          'ITEM => ${item.title} | '
          'cat=${item.categoryName} | '
          'col=${item.collectionName} | '
          'photos=${item.photoCount} | '
          'image=${item.primaryPhotoPath}',
        );
      }

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading gallery: $e');
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

  Map<String, Map<String, List<ItemGalleryModel>>> _groupItems() {
    final grouped = <String, Map<String, List<ItemGalleryModel>>>{};

    for (final item in _items) {
      grouped.putIfAbsent(item.categoryName, () => {});
      grouped[item.categoryName]!.putIfAbsent(item.collectionName, () => []);
      grouped[item.categoryName]![item.collectionName]!.add(item);
    }

    return grouped;
  }

  int _countItemsInCategory(Map<String, List<ItemGalleryModel>> collections) {
    int total = 0;
    for (final items in collections.values) {
      total += items.length;
    }
    return total;
  }

  Future<void> _openItemDetail(ItemGalleryModel item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailPage(itemId: item.itemId),
      ),
    );

    if (changed == true) {
      await _loadItems();
    }
  }

  Future<void> _openEdit(ItemGalleryModel item) async {
    final detail = await _itemRepository.getItemDetail(item.itemId);
    if (detail == null || !mounted) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditItemPage(item: detail),
      ),
    );

    if (changed == true) {
      await _loadItems();
    }
  }

  Future<void> _deleteItem(ItemGalleryModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            tr(context, es: 'Eliminar ítem', en: 'Delete item'),
          ),
          content: Text(
            tr(
              context,
              es: '¿Seguro que quieres eliminar "${item.title}" y todas sus fotos?',
              en: 'Are you sure you want to delete "${item.title}" and all its photos?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(context, es: 'Cancelar', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(context, es: 'Eliminar', en: 'Delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _itemRepository.deleteItem(item.itemId);
    await _photoStorageService.deleteItemDirectory(item.itemId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, es: 'Ítem eliminado.', en: 'Item deleted.')),
      ),
    );

    await _loadItems();
  }

  Future<void> _handleItemAction(
    _GalleryItemAction action,
    ItemGalleryModel item,
  ) async {
    switch (action) {
      case _GalleryItemAction.edit:
        await _openEdit(item);
        break;
      case _GalleryItemAction.delete:
        await _deleteItem(item);
        break;
    }
  }

  void _openPhotoModal(ItemGalleryModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPhotoModal(
        item: item,
        onOpenDetail: () async {
          Navigator.pop(context);
          await _openItemDetail(item);
        },
        onEdit: () async {
          Navigator.pop(context);
          await _openEdit(item);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteItem(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(context, es: 'Explorar colección', en: 'Explore collection'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadItems,
              child: _items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              tr(
                                context,
                                es: 'Todavía no tienes ítems guardados para mostrar.',
                                en: 'You do not have any saved items to show yet.',
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
                            title: Text(
                              categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${tr(context, es: '$totalItems ítems', en: '$totalItems items')} • '
                              '${tr(context, es: '${collections.length} colecciones', en: '${collections.length} collections')}',
                            ),
                            children:
                                collections.entries.map((collectionEntry) {
                              final collectionName = collectionEntry.key;
                              final items = collectionEntry.value;

                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: ExpansionTile(
                                    title: Text(collectionName),
                                    subtitle: Text(
                                      tr(
                                        context,
                                        es: '${items.length} ítems',
                                        en: '${items.length} items',
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final width = constraints.maxWidth;

                                            int crossAxisCount = 2;
                                            if (width >= 900) {
                                              crossAxisCount = 4;
                                            } else if (width >= 600) {
                                              crossAxisCount = 3;
                                            }

                                            return GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: items.length,
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                crossAxisSpacing: 12,
                                                mainAxisSpacing: 12,
                                                childAspectRatio: 0.78,
                                              ),
                                              itemBuilder: (context, index) {
                                                final item = items[index];

                                                return _GalleryItemCard(
                                                  item: item,
                                                  onTap: () =>
                                                      _openPhotoModal(item),
                                                  onSelectedAction: (action) =>
                                                      _handleItemAction(
                                                          action, item),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
            ),
    );
  }
}

class _GalleryItemCard extends StatelessWidget {
  final ItemGalleryModel item;
  final VoidCallback onTap;
  final ValueChanged<_GalleryItemAction> onSelectedAction;

  const _GalleryItemCard({
    required this.item,
    required this.onTap,
    required this.onSelectedAction,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = item.primaryPhotoPath;
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
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
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 38,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      child: PopupMenuButton<_GalleryItemAction>(
                        tooltip: tr(context, es: 'Acciones', en: 'Actions'),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        onSelected: onSelectedAction,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _GalleryItemAction.edit,
                            child: Text(tr(context, es: 'Editar', en: 'Edit')),
                          ),
                          PopupMenuItem(
                            value: _GalleryItemAction.delete,
                            child:
                                Text(tr(context, es: 'Eliminar', en: 'Delete')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      context,
                      es: '${item.photoCount} foto(s)',
                      en: '${item.photoCount} photo(s)',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
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

class _ItemPhotoModal extends StatelessWidget {
  final ItemGalleryModel item;
  final Future<void> Function() onOpenDetail;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  const _ItemPhotoModal({
    required this.item,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = item.primaryPhotoPath;
    final description = item.description;

    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    final hasDescription = description != null && description.trim().isNotEmpty;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: hasImage
                  ? InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Image.file(
                        File(imagePath!),
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 60,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(
                          context,
                          es: 'Categoría: ${item.categoryName}',
                          en: 'Category: ${item.categoryName}',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(
                          context,
                          es: 'Colección: ${item.collectionName}',
                          en: 'Collection: ${item.collectionName}',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(
                          context,
                          es: 'Fotos: ${item.photoCount}',
                          en: 'Photos: ${item.photoCount}',
                        ),
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: 10),
                        Text(
                          tr(context, es: 'Descripción', en: 'Description'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(description!),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label:
                                  Text(tr(context, es: 'Editar', en: 'Edit')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline),
                              label: Text(
                                tr(context, es: 'Eliminar', en: 'Delete'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onOpenDetail,
                          icon: const Icon(Icons.open_in_new),
                          label: Text(
                            tr(
                              context,
                              es: 'Ver detalle completo',
                              en: 'View full details',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
