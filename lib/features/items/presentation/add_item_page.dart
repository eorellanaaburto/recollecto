import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/localization/local_text.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/models/category_model.dart';
import '../../categories/presentation/categories_page.dart';
import '../../collections/data/collection_repository.dart';
import '../../collections/domain/models/collection_model.dart';
import '../../collections/presentation/collections_page.dart';
import '../data/item_repository.dart';
import '../data/photo_storage_service.dart';
import '../domain/models/item_model.dart';
import '../domain/models/item_photo_model.dart';
import '../domain/models/potential_duplicate_model.dart';
import '../../backup/data/server_sync_service.dart';

class AddItemPage extends StatefulWidget {
  final VoidCallback? onItemSaved;

  const AddItemPage({
    super.key,
    this.onItemSaved,
  });

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final CollectionRepository _collectionRepository = CollectionRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final PhotoStorageService _photoStorageService = PhotoStorageService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Uuid _uuid = const Uuid();

  final List<CategoryModel> _categories = [];
  final List<CollectionModel> _collections = [];
  final List<XFile> _selectedPhotos = [];

  String? _selectedCategoryId;
  String? _selectedCollectionId;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingPhotos = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    final categories = await _categoryRepository.getAllCategories();

    String? selectedCategoryId;
    List<CollectionModel> collections = [];
    String? selectedCollectionId;

    if (categories.isNotEmpty) {
      selectedCategoryId = categories.first.id;
      collections = await _collectionRepository.getCollectionsByCategory(
        selectedCategoryId,
      );

      if (collections.isNotEmpty) {
        selectedCollectionId = collections.first.id;
      }
    }

    if (!mounted) return;

    setState(() {
      _categories
        ..clear()
        ..addAll(categories);

      _collections
        ..clear()
        ..addAll(collections);

      _selectedCategoryId = selectedCategoryId;
      _selectedCollectionId = selectedCollectionId;
      _isLoading = false;
    });
  }

  Future<void> _onCategoryChanged(String? categoryId) async {
    if (categoryId == null) return;

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCollectionId = null;
      _collections.clear();
      _isLoading = true;
    });

    final collections = await _collectionRepository.getCollectionsByCategory(
      categoryId,
    );

    if (!mounted) return;

    setState(() {
      _collections.addAll(collections);
      _selectedCollectionId =
          collections.isNotEmpty ? collections.first.id : null;
      _isLoading = false;
    });
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isPickingPhotos = true;
    });

    try {
      final photos = await _photoStorageService.pickFromGallery();

      if (!mounted) return;

      setState(() {
        _selectedPhotos.addAll(photos);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isPickingPhotos = false;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() {
      _isPickingPhotos = true;
    });

    try {
      final photo = await _photoStorageService.pickFromCamera();

      if (!mounted) return;

      if (photo != null) {
        setState(() {
          _selectedPhotos.add(photo);
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isPickingPhotos = false;
      });
    }
  }

  void _removePhotoAt(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _saveItem() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final categoryId = _selectedCategoryId;
    final collectionId = _selectedCollectionId;

    if (_categories.isEmpty) {
      _showMessage(tr(context,
          es: 'Primero debes crear una categoría.',
          en: 'You must create a category first.'));
      return;
    }

    if (_collections.isEmpty) {
      _showMessage(tr(context,
          es: 'Primero debes crear una colección.',
          en: 'You must create a collection first.'));
      return;
    }

    if (categoryId == null) {
      _showMessage(tr(context,
          es: 'Debes seleccionar una categoría.',
          en: 'You must select a category.'));
      return;
    }

    if (collectionId == null) {
      _showMessage(tr(context,
          es: 'Debes seleccionar una colección.',
          en: 'You must select a collection.'));
      return;
    }

    if (title.isEmpty) {
      _showMessage(tr(context,
          es: 'Debes escribir el nombre del ítem.',
          en: 'You must enter the item name.'));
      return;
    }

    if (_selectedPhotos.isEmpty) {
      _showMessage(tr(context,
          es: 'Debes agregar al menos una foto.',
          en: 'You must add at least one photo.'));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final normalizedTitle = TextNormalizer.normalize(title);
    final imageHashes = await _photoStorageService
        .computeHashesFromPickedFiles(_selectedPhotos);

    final duplicates = await _itemRepository.findPotentialDuplicates(
      normalizedTitle: normalizedTitle,
      imageHashes: imageHashes,
    );

    if (!mounted) return;

    if (duplicates.isNotEmpty) {
      final shouldContinue = await _showDuplicatesDialog(
        normalizedTitle: normalizedTitle,
        duplicates: duplicates,
      );

      if (shouldContinue != true) {
        setState(() {
          _isSaving = false;
        });
        return;
      }
    }

    final itemId = _uuid.v4();
    List<ItemPhotoModel> storedPhotos = [];

    try {
      final item = ItemModel(
        id: itemId,
        categoryId: categoryId,
        collectionId: collectionId,
        title: title,
        normalizedTitle: normalizedTitle,
        description: description.isEmpty ? null : description,
        createdAt: DateTime.now(),
      );

      storedPhotos = await _photoStorageService.persistPhotos(
        itemId: itemId,
        pickedFiles: _selectedPhotos,
      );

      await _itemRepository.insertItemWithPhotos(
        item: item,
        photos: storedPhotos,
      );

      _titleController.clear();
      _descriptionController.clear();

      setState(() {
        _selectedPhotos.clear();
      });

      _showMessage(tr(context,
          es: 'Ítem guardado correctamente.', en: 'Item saved successfully.'));
      widget.onItemSaved?.call();
      unawaited(ServerSyncService.instance.requestSync());
    } catch (e, st) {
      await _photoStorageService.deleteStoredPhotos(storedPhotos);
      debugPrint('Error guardando ítem: $e');
      debugPrint('$st');
      _showMessage(tr(context,
          es: 'Ocurrió un error al guardar el ítem.',
          en: 'An error occurred while saving the item.'));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<bool?> _showDuplicatesDialog({
    required String normalizedTitle,
    required List<PotentialDuplicateModel> duplicates,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(tr(context,
              es: 'Posible duplicado detectado',
              en: 'Potential duplicate detected')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: duplicates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final duplicate = duplicates[index];
                final reasons = <String>[];

                if (duplicate.matchesName(normalizedTitle)) {
                  reasons.add(tr(context,
                      es: 'coincide el nombre', en: 'name matches'));
                }
                if (duplicate.matchesImage) {
                  reasons.add(tr(context,
                      es: 'coincide una foto', en: 'a photo matches'));
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DuplicateThumb(path: duplicate.primaryPhotoPath),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            duplicate.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${duplicate.categoryName} • ${duplicate.collectionName}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reasons.join(' y '),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(context, es: 'Cancelar', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(context, es: 'Guardar igual', en: 'Save anyway')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCategoriesPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoriesPage()),
    );

    await _loadInitialData();
  }

  Future<void> _openCollectionsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CollectionsPage()),
    );

    await _loadInitialData();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCategories = _categories.isNotEmpty;
    final hasCollections = _collections.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, es: 'Agregar ítem', en: 'Add item')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (!hasCategories) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                tr(context,
                                    es: 'Necesitas al menos una categoría para registrar un ítem.',
                                    en: 'You need at least one category to register an item.'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openCategoriesPage,
                                icon: const Icon(Icons.category_outlined),
                                label: Text(tr(context,
                                    es: 'Ir a categorías',
                                    en: 'Go to categories')),
                              ),
                            ),
                          ] else if (!hasCollections) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                tr(context,
                                    es: 'Necesitas al menos una colección para registrar un ítem.',
                                    en: 'You need at least one collection to register an item.'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openCollectionsPage,
                                icon: const Icon(
                                  Icons.collections_bookmark_outlined,
                                ),
                                label: Text(tr(context,
                                    es: 'Ir a colecciones',
                                    en: 'Go to collections')),
                              ),
                            ),
                          ] else ...[
                            DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: tr(context,
                                    es: 'Categoría', en: 'Category'),
                              ),
                              items: _categories
                                  .map(
                                    (category) => DropdownMenuItem<String>(
                                      value: category.id,
                                      child: Text(category.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _onCategoryChanged,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedCollectionId,
                              decoration: InputDecoration(
                                labelText: tr(context,
                                    es: 'Colección', en: 'Collection'),
                              ),
                              items: _collections
                                  .map(
                                    (collection) => DropdownMenuItem<String>(
                                      value: collection.id,
                                      child: Text(collection.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCollectionId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: tr(context,
                                    es: 'Nombre del ítem', en: 'Item name'),
                                hintText: tr(context,
                                    es: 'Ej: Zelda Breath of the Wild',
                                    en: 'Ex: Zelda Breath of the Wild'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: tr(context,
                                    es: 'Descripción', en: 'Description'),
                                hintText:
                                    tr(context, es: 'Opcional', en: 'Optional'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (hasCategories && hasCollections) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isPickingPhotos
                                        ? null
                                        : _pickFromGallery,
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                    ),
                                    label: Text(tr(context,
                                        es: 'Galería', en: 'Gallery')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isPickingPhotos
                                        ? null
                                        : _pickFromCamera,
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                    ),
                                    label: Text(tr(context,
                                        es: 'Cámara', en: 'Camera')),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                tr(context,
                                    es: 'Fotos seleccionadas: ${_selectedPhotos.length}',
                                    en: 'Selected photos: ${_selectedPhotos.length}'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_selectedPhotos.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(tr(context,
                                    es: 'Aún no has agregado fotos.',
                                    en: 'You have not added photos yet.')),
                              )
                            else
                              SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedPhotos.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final photo = _selectedPhotos[index];

                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(
                                            File(photo.path),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: InkWell(
                                            onTap: () => _removePhotoAt(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (index == 0)
                                          Positioned(
                                            left: 6,
                                            bottom: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                tr(context,
                                                    es: 'Principal',
                                                    en: 'Main'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveItem,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving
                            ? tr(context, es: 'Guardando...', en: 'Saving...')
                            : tr(context, es: 'Guardar ítem', en: 'Save item')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DuplicateThumb extends StatelessWidget {
  final String? path;

  const _DuplicateThumb({required this.path});

  @override
  Widget build(BuildContext context) {
    final filePath = path;

    if (filePath == null || filePath.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    final file = File(filePath);

    if (!file.existsSync()) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.broken_image_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        file,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
      ),
    );
  }
}
