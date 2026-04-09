import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../items/data/item_repository.dart';
import '../../items/data/photo_storage_service.dart';
import '../../items/domain/models/item_gallery_model.dart';
import '../../items/presentation/edit_item_page.dart';
import '../../items/presentation/item_detail_page.dart';

enum _CollectionItemAction {
  edit,
  delete,
}

class CollectionItemsPage extends StatefulWidget {
  final String categoryName;
  final String collectionName;
  final List<ItemGalleryModel> items;
  final String? coverPhotoPath;

  const CollectionItemsPage({
    super.key,
    required this.categoryName,
    required this.collectionName,
    required this.items,
    required this.coverPhotoPath,
  });

  @override
  State<CollectionItemsPage> createState() => _CollectionItemsPageState();
}

class _CollectionItemsPageState extends State<CollectionItemsPage> {
  final ItemRepository _itemRepository = ItemRepository();
  final PhotoStorageService _photoStorageService = PhotoStorageService();
  final TextEditingController _searchController = TextEditingController();

  late List<ItemGalleryModel> _allItems;
  late List<ItemGalleryModel> _filteredItems;

  @override
  void initState() {
    super.initState();
    _allItems = List<ItemGalleryModel>.from(widget.items)
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    _filteredItems = List<ItemGalleryModel>.from(_allItems);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_applyFilter)
      ..dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredItems = List<ItemGalleryModel>.from(_allItems);
      } else {
        _filteredItems = _allItems.where((item) {
          return item.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _openItemDetail(ItemGalleryModel item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailPage(itemId: item.itemId),
      ),
    );

    if (changed == true && mounted) {
      Navigator.pop(context, true);
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

    if (changed == true && mounted) {
      Navigator.pop(context, true);
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
        content: Text(
          tr(context, es: 'Ítem eliminado.', en: 'Item deleted.'),
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  Future<void> _handleItemAction(
    _CollectionItemAction action,
    ItemGalleryModel item,
  ) async {
    switch (action) {
      case _CollectionItemAction.edit:
        await _openEdit(item);
        break;
      case _CollectionItemAction.delete:
        await _deleteItem(item);
        break;
    }
  }

  void _openPhotoModal(ItemGalleryModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CollectionItemPhotoModal(
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
    final coverPath = widget.coverPhotoPath;
    final hasCover = coverPath != null &&
        coverPath.isNotEmpty &&
        File(coverPath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collectionName),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: hasCover
                        ? Image.file(
                            File(coverPath!),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(
                                Icons.collections_bookmark_outlined,
                                size: 52,
                              ),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.collectionName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(
                            context,
                            es: 'Categoría: ${widget.categoryName}',
                            en: 'Category: ${widget.categoryName}',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr(
                            context,
                            es: '${_filteredItems.length} resultado(s) • ${_allItems.length} ítem(s) total',
                            en: '${_filteredItems.length} result(s) • ${_allItems.length} total item(s)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr(
                  context,
                  es: 'Buscar por nombre...',
                  en: 'Search by name...',
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            tr(
                              context,
                              es: 'No se encontraron ítems con ese nombre.',
                              en: 'No items found with that name.',
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          itemCount: _filteredItems.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];

                            return _CollectionItemCard(
                              item: item,
                              onTap: () => _openPhotoModal(item),
                              onSelectedAction: (action) =>
                                  _handleItemAction(action, item),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CollectionItemCard extends StatelessWidget {
  final ItemGalleryModel item;
  final VoidCallback onTap;
  final ValueChanged<_CollectionItemAction> onSelectedAction;

  const _CollectionItemCard({
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
                      child: PopupMenuButton<_CollectionItemAction>(
                        tooltip: tr(context, es: 'Acciones', en: 'Actions'),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        onSelected: onSelectedAction,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _CollectionItemAction.edit,
                            child: Text(tr(context, es: 'Editar', en: 'Edit')),
                          ),
                          PopupMenuItem(
                            value: _CollectionItemAction.delete,
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

class _CollectionItemPhotoModal extends StatelessWidget {
  final ItemGalleryModel item;
  final Future<void> Function() onOpenDetail;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  const _CollectionItemPhotoModal({
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
