import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../data/item_repository.dart';
import '../data/photo_storage_service.dart';
import '../domain/models/item_detail_model.dart';
import '../domain/models/item_detail_photo_model.dart';
import 'edit_item_page.dart';

class ItemDetailPage extends StatefulWidget {
  final String itemId;

  const ItemDetailPage({
    super.key,
    required this.itemId,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final ItemRepository _itemRepository = ItemRepository();
  final PhotoStorageService _photoStorageService = PhotoStorageService();
  final PageController _pageController = PageController();

  ItemDetailModel? _detail;
  final List<ItemDetailPhotoModel> _photos = [];

  bool _isLoading = true;
  bool _isDeleting = false;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
    });

    final detail = await _itemRepository.getItemDetail(widget.itemId);
    final photos = await _itemRepository.getPhotosByItemId(widget.itemId);

    if (!mounted) return;

    setState(() {
      _detail = detail;
      _photos
        ..clear()
        ..addAll(photos);
      _isLoading = false;
    });
  }

  Future<void> _openEdit() async {
    final detail = _detail;
    if (detail == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditItemPage(item: detail),
      ),
    );

    if (changed == true) {
      await _loadDetail();
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(tr(context, es: 'Eliminar ítem', en: 'Delete item')),
          content: Text(
            tr(context,
                es: '¿Seguro que quieres eliminar este ítem y todas sus fotos?',
                en: 'Are you sure you want to delete this item and all its photos?'),
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

    setState(() {
      _isDeleting = true;
    });

    try {
      await _itemRepository.deleteItem(widget.itemId);
      await _photoStorageService.deleteItemDirectory(widget.itemId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context,
              es: 'No se pudo eliminar el ítem.',
              en: 'Could not delete the item.')),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, es: 'Detalle del ítem', en: 'Item details')),
        actions: [
          IconButton(
            onPressed: _isLoading || _isDeleting ? null : _openEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _isLoading || _isDeleting ? null : _deleteItem,
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? Center(
                  child: Text(tr(context,
                      es: 'No se encontró este ítem.',
                      en: 'This item was not found.')),
                )
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_photos.isEmpty)
                        Container(
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 60,
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 320,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _photos.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPhotoIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              final file = File(photo.filePath);

                              if (!file.existsSync()) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 60,
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: InteractiveViewer(
                                  minScale: 0.8,
                                  maxScale: 4,
                                  child: Image.file(
                                    file,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            '${_currentPhotoIndex + 1} / ${_photos.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 82,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              final file = File(photo.filePath);
                              final isSelected = index == _currentPhotoIndex;

                              return InkWell(
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 82,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: file.existsSync()
                                        ? Image.file(
                                            file,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(tr(context,
                                  es: 'Categoría: ${detail.categoryName}',
                                  en: 'Category: ${detail.categoryName}')),
                              const SizedBox(height: 6),
                              Text(tr(context,
                                  es: 'Colección: ${detail.collectionName}',
                                  en: 'Collection: ${detail.collectionName}')),
                              const SizedBox(height: 6),
                              Text(tr(context,
                                  es: 'Fotos: ${_photos.length}',
                                  en: 'Photos: ${_photos.length}')),
                              const SizedBox(height: 6),
                              Text(tr(context,
                                  es: 'Creado: ${_formatDate(detail.createdAt)}',
                                  en: 'Created: ${_formatDate(detail.createdAt)}')),
                              if (detail.description != null &&
                                  detail.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  tr(context,
                                      es: 'Descripción', en: 'Description'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(detail.description!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
