import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/localization/local_text.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../core/widgets/app_footer.dart';
import '../../../core/widgets/app_header.dart';
import '../../home/presentation/homepage.dart';
import '../data/category_repository.dart';
import '../domain/models/category_model.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryRepository _repository = CategoryRepository();
  final TextEditingController _nameController = TextEditingController();
  final Uuid _uuid = const Uuid();

  final List<CategoryModel> _categories = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _repository.getAllCategories();

      if (!mounted) return;

      setState(() {
        _categories
          ..clear()
          ..addAll(categories);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(tr(context, es: 'Error cargando categorías: $e', en: 'Error loading categories: $e'));
    }
  }

  Future<void> _createCategory() async {
    final rawName = _nameController.text.trim();

    if (rawName.isEmpty) {
      _showMessage(tr(context, es: 'Debes escribir un nombre para la categoría.', en: 'You must enter a category name.'));
      return;
    }

    final normalizedName = TextNormalizer.normalize(rawName);

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final exists = await _repository.existsByNormalizedName(normalizedName);

      if (exists) {
        _showMessage(tr(context, es: 'Esa categoría ya existe.', en: 'That category already exists.'));
        return;
      }

      final category = CategoryModel(
        id: _uuid.v4(),
        name: rawName,
        normalizedName: normalizedName,
        createdAt: DateTime.now(),
      );

      await _repository.insertCategory(category);
      _nameController.clear();
      await _loadCategories();

      if (!mounted) return;
      _showMessage(tr(context, es: 'Categoría creada correctamente.', en: 'Category created successfully.'));
    } catch (e) {
      if (!mounted) return;
      _showMessage(tr(context, es: 'Error al crear la categoría: $e', en: 'Error creating category: $e'));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(tr(context, es: 'Eliminar categoría', en: 'Delete category')),
          content: Text(
            tr(context, es: '¿Seguro que quieres eliminar "${category.name}"?', en: 'Are you sure you want to delete "${category.name}"?'),
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
      await _repository.deleteCategory(category.id);
      await _loadCategories();

      if (!mounted) return;
      _showMessage(tr(context, es: 'Categoría eliminada.', en: 'Category deleted.'));
    } catch (e) {
      if (!mounted) return;
      _showMessage(tr(context, es: 'Error eliminando categoría: $e', en: 'Error deleting category: $e'));
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
    return Scaffold(
      appBar: AppHeader(
        title: tr(context, es: 'Categorías', en: 'Categories'),
        subtitle: tr(context, es: 'Crea y administra tus categorías', en: 'Create and manage your categories'),
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: tr(context, es: 'Nombre de la categoría', en: 'Category name'),
                        hintText: tr(context, es: 'Ej: Figuras, Libros, Videojuegos', en: 'Ex: Figures, Books, Video Games'),
                      ),
                      onSubmitted: (_) => _isSaving ? null : _createCategory(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _createCategory,
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
                              : tr(context, es: 'Crear categoría', en: 'Create category'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                      ? Center(
                          child: Text(
                            tr(context, es: 'Todavía no tienes categorías creadas.', en: 'You do not have any categories yet.'),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final category = _categories[index];

                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.category_outlined),
                                ),
                                title: Text(category.name),
                                subtitle: Text(
                                  tr(context, es: 'Creada: ${_formatDate(category.createdAt)}', en: 'Created: ${_formatDate(category.createdAt)}'),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteCategory(category),
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
