import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/collection_model.dart';
import '../domain/models/collection_with_category_model.dart';

class CollectionRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;

  Future<List<CollectionWithCategoryModel>> getAllCollections() async {
    final db = await _appDatabase.database;

    final result = await db.rawQuery('''
      SELECT
        c.id,
        c.category_id,
        c.name,
        c.normalized_name,
        c.logo_path,
        c.created_at,
        cat.name AS category_name
      FROM collections c
      INNER JOIN categories cat ON cat.id = c.category_id
      ORDER BY cat.name COLLATE NOCASE ASC, c.name COLLATE NOCASE ASC
    ''');

    return result
        .map((map) => CollectionWithCategoryModel.fromMap(map))
        .toList();
  }

  Future<bool> existsByNormalizedNameInCategory({
    required String normalizedName,
    required String categoryId,
  }) async {
    final db = await _appDatabase.database;

    final result = await db.query(
      'collections',
      where: 'normalized_name = ? AND category_id = ?',
      whereArgs: [normalizedName, categoryId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> insertCollection(CollectionModel collection) async {
    final db = await _appDatabase.database;

    await db.insert(
      'collections',
      collection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateCollectionLogo({
    required String collectionId,
    required String? logoPath,
  }) async {
    final db = await _appDatabase.database;

    await db.update(
      'collections',
      {
        'logo_path': logoPath,
      },
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }

  Future<CollectionModel?> getCollectionById(String id) async {
    final db = await _appDatabase.database;

    final result = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return CollectionModel.fromMap(result.first);
  }

  Future<void> deleteCollection(String id) async {
    final db = await _appDatabase.database;

    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CollectionModel>> getCollectionsByCategory(
    String categoryId,
  ) async {
    final db = await _appDatabase.database;

    final result = await db.query(
      'collections',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(CollectionModel.fromMap).toList();
  }
}
