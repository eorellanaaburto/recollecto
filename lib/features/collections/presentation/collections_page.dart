import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/localization/local_text.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../core/widgets/app_footer.dart';
import '../../../core/widgets/app_header.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/models/category_model.dart';
import '../../categories/presentation/categories_page.dart';
import '../../home/presentation/homepage.dart';
import '../data/collection_repository.dart';
import '../domain/models/collection_model.dart';
import '../domain/models/collection_with_category_model.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final CollectionRepository _collectionRepository = CollectionRepository();
  final TextEditingController _nameController = TextEditingController();
  final Uuid _uuid = const Uuid();

  final List<CategoryModel> _categories = [];
  final List<CollectionWithCategoryModel> _collections = [];

  String? _selectedCategoryId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _goToTab(int index) async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(initialIndex: index),
      ),
      (route) => false,
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _categoryRepository.getAllCategories();
      final collections = await _collectionRepository.getAllCollections();

      if (!mounted) return;

      String? selectedCategoryId = _selectedCategoryId;

      if (categories.isEmpty) {
        selectedCategoryId = null;
      } else if (selectedCategoryId == null ||
          !categories.any((category) => category.id == selectedCategoryId)) {
        selectedCategoryId = categories.first.id;
      }

      setState(() {
        _categories
          ..clear()
          ..addAll(categories);

        _collections
          ..clear()
          ..addAll(collections);

        _selectedCategoryId = selectedCategoryId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(tr(context, es: 'Error cargando colecciones: $e', en: 'Error loading collections: $e'));
    }
  }

  Future<void> _openCategoriesPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoriesPage()),
    );

    await _loadData();
  }

  Future<void> _createCollection() async {
    final rawName = _nameController.text.trim();
    final categoryId = _selectedCategoryId;

    if (_categories.isEmpty) {
      _showMessage(tr(context, es: 'Primero debes crear una categoría.', en: 'You must create a category first.'));
      return;
    }

    if (categoryId == null) {
      _showMessage(tr(context, es: 'Debes seleccionar una categoría.', en: 'You must select a category.'));
      return;
    }

    if (rawName.isEmpty) {
      _showMessage(tr(context, es: 'Debes escribir un nombre para la colección.', en: 'You must enter a collection name.'));
      return;
    }

    final normalizedName = TextNormalizer.normalize(rawName);

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final exists = await _collectionRepository.existsByNormalizedNameInCategory(
        normalizedName: normalizedName,
        categoryId: categoryId,
      );

      if (exists) {
        _showMessage(tr(context, es: 'Esa colección ya existe dentro de la categoría elegida.', en: 'That collection already exists in the selected category.'));
        return;
      }

      final collection = CollectionModel(
        id: _uuid.v4(),
        categoryId: categoryId,
        name: rawName,
        normalizedName: normalizedName,
        createdAt: DateTime.now(),
      );

      await _collectionRepository.insertCollection(collection);
      _nameController.clear();
      await _loadData();

      if (!mounted) return;
      _showMessage(tr(context, es: 'Colección creada correctamente.', en: 'Collection created successfully.'));
    } catch (e) {
      if (!mounted) return;
      _showMessage(tr(context, es: 'Error al crear la colección: $e', en: 'Error creating collection: $e'));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteCollection(CollectionWithCategoryModel collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(tr(context, es: 'Eliminar colección', en: 'Delete collection')),
          content: Text(
            tr(context, es: '¿Seguro que quieres eliminar "${collection.name}"?', en: 'Are you sure you want to delete "${collection.name}"?'),
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

    try {
      await _collectionRepository.deleteCollection(collection.id);
      await _loadData();

      if (!mounted) return;
      _showMessage(tr(context, es: 'Colección eliminada.', en: 'Collection deleted.'));
    } catch (e) {
      if (!mounted) return;
      _showMessage(tr(context, es: 'Error eliminando colección: $e', en: 'Error deleting collection: $e'));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final hasCategories = _categories.isNotEmpty;

    return Scaffold(
      appBar: AppHeader(
        title: tr(context, es: 'Colecciones', en: 'Collections'),
        subtitle: tr(context, es: 'Agrupa tus ítems por colección', en: 'Group your items by collection'),
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                                tr(context, es: 'Antes de crear colecciones, necesitas al menos una categoría.', en: 'Before creating collections, you need at least one category.'),
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openCategoriesPage,
                                icon: const Icon(Icons.category_outlined),
                                label: Text(tr(context, es: 'Ir a categorías', en: 'Go to categories')),
                              ),
                            ),
                          ] else ...[
                            DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: tr(context, es: 'Categoría', en: 'Category'),
                              ),
                              items: _categories
                                  .map(
                                    (category) => DropdownMenuItem<String>(
                                      value: category.id,
                                      child: Text(category.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: tr(context, es: 'Nombre de la colección', en: 'Collection name'),
                                hintText: tr(context, es: 'Ej: Funko Pop, Nintendo Switch, Manga', en: 'Ex: Funko Pop, Nintendo Switch, Manga'),
                              ),
                              onSubmitted: (_) => _isSaving ? null : _createCollection(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isSaving ? null : _createCollection,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add),
                                label: Text(
                                  _isSaving
                                      ? tr(context, es: 'Guardando...', en: 'Saving...')
                                      : tr(context, es: 'Crear colección', en: 'Create collection'),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _collections.isEmpty
                        ? Center(
                            child: Text(
                              tr(context, es: 'Todavía no tienes colecciones creadas.', en: 'You do not have any collections yet.'),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _collections.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final collection = _collections[index];

                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.collections_bookmark_outlined),
                                  ),
                                  title: Text(collection.name),
                                  subtitle: Text(
                                    '${collection.categoryName}\n${tr(context, es: 'Creada', en: 'Created')}: ${_formatDate(collection.createdAt)}',
                                  ),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteCollection(collection),
                                    tooltip: tr(context, es: 'Eliminar', en: 'Delete'),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: 0,
        onTap: _goToTab,
      ),
    );
  }
}
