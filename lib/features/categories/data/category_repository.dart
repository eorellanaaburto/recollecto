import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/category_model.dart';

class CategoryRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _appDatabase.database;

    final result = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(CategoryModel.fromMap).toList();
  }

  Future<bool> existsByNormalizedName(String normalizedName) async {
    final db = await _appDatabase.database;

    final result = await db.query(
      'categories',
      where: 'normalized_name = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await _appDatabase.database;

    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await _appDatabase.database;

    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
