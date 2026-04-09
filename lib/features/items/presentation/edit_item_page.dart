import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/models/category_model.dart';
import '../../collections/data/collection_repository.dart';
import '../../collections/domain/models/collection_model.dart';
import '../data/item_repository.dart';
import '../domain/models/item_detail_model.dart';

class EditItemPage extends StatefulWidget {
  final ItemDetailModel item;

  const EditItemPage({
    super.key,
    required this.item,
  });

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final CollectionRepository _collectionRepository = CollectionRepository();
  final ItemRepository _itemRepository = ItemRepository();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  final List<CategoryModel> _categories = [];
  final List<CollectionModel> _collections = [];

  String? _selectedCategoryId;
  String? _selectedCollectionId;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController =
        TextEditingController(text: widget.item.description ?? '');
    _selectedCategoryId = widget.item.categoryId;
    _selectedCollectionId = widget.item.collectionId;
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final categories = await _categoryRepository.getAllCategories();
    final categoryId = _selectedCategoryId;
    List<CollectionModel> collections = [];

    if (categoryId != null) {
      collections =
          await _collectionRepository.getCollectionsByCategory(categoryId);
    }

    if (!mounted) return;

    setState(() {
      _categories
        ..clear()
        ..addAll(categories);

      _collections
        ..clear()
        ..addAll(collections);

      if (_selectedCollectionId == null ||
          !_collections.any((c) => c.id == _selectedCollectionId)) {
        _selectedCollectionId =
            _collections.isNotEmpty ? _collections.first.id : null;
      }

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

    final collections =
        await _collectionRepository.getCollectionsByCategory(categoryId);

    if (!mounted) return;

    setState(() {
      _collections.addAll(collections);
      _selectedCollectionId =
          _collections.isNotEmpty ? _collections.first.id : null;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final categoryId = _selectedCategoryId;
    final collectionId = _selectedCollectionId;

    if (title.isEmpty) {
      _showMessage(tr(context,
          es: 'Debes escribir el nombre del ítem.',
          en: 'You must enter the item name.'));
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

    setState(() {
      _isSaving = true;
    });

    try {
      await _itemRepository.updateItem(
        itemId: widget.item.itemId,
        categoryId: categoryId,
        collectionId: collectionId,
        title: title,
        normalizedTitle: TextNormalizer.normalize(title),
        description: description.isEmpty ? null : description,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showMessage(tr(context,
          es: 'No se pudo guardar el cambio.',
          en: 'Could not save the changes.'));
    }
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
        title: Text(tr(context, es: 'Editar ítem', en: 'Edit item')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!hasCategories) ...[
                          Text(tr(context,
                              es: 'No hay categorías disponibles.',
                              en: 'No categories available.')),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText:
                                  tr(context, es: 'Categoría', en: 'Category'),
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
                            value:
                                hasCollections ? _selectedCollectionId : null,
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
                            onChanged: hasCollections
                                ? (value) {
                                    setState(() {
                                      _selectedCollectionId = value;
                                    });
                                  }
                                : null,
                          ),
                          if (!hasCollections) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                tr(context,
                                    es: 'La categoría elegida no tiene colecciones.',
                                    en: 'The selected category does not have collections.'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: tr(context,
                                  es: 'Nombre del ítem', en: 'Item name'),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving
                        ? tr(context, es: 'Guardando...', en: 'Saving...')
                        : tr(context,
                            es: 'Guardar cambios', en: 'Save changes')),
                  ),
                ),
              ],
            ),
    );
  }
}
