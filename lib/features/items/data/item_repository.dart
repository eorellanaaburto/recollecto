import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/duplicate_group_model.dart';
import '../domain/models/item_detail_model.dart';
import '../domain/models/item_detail_photo_model.dart';
import '../domain/models/item_gallery_model.dart';
import '../domain/models/item_model.dart';
import '../domain/models/item_photo_model.dart';
import '../domain/models/potential_duplicate_model.dart';
import 'photo_storage_service.dart';

class ItemRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;

  Future<void> insertItemWithPhotos({
    required ItemModel item,
    required List<ItemPhotoModel> photos,
  }) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.insert(
        'items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final photo in photos) {
        await txn.insert(
          'item_photos',
          photo.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<void> updateItem({
    required String itemId,
    required String categoryId,
    required String collectionId,
    required String title,
    required String normalizedTitle,
    required String? description,
  }) async {
    final db = await _appDatabase.database;

    await db.update(
      'items',
      {
        'category_id': categoryId,
        'collection_id': collectionId,
        'title': title,
        'normalized_title': normalizedTitle,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<PotentialDuplicateModel>> findPotentialDuplicates({
    required String normalizedTitle,
    required List<String> imageHashes,
  }) async {
    final db = await _appDatabase.database;

    if (imageHashes.isEmpty) {
      final result = await db.rawQuery('''
        SELECT DISTINCT
          i.id AS item_id,
          i.title,
          i.normalized_title,
          cat.name AS category_name,
          c.name AS collection_name,
          (
            SELECT ip.file_path
            FROM item_photos ip
            WHERE ip.item_id = i.id
            ORDER BY ip.is_primary DESC, ip.created_at ASC
            LIMIT 1
          ) AS primary_photo_path,
          0 AS matching_hash_count
        FROM items i
        INNER JOIN categories cat ON cat.id = i.category_id
        INNER JOIN collections c ON c.id = i.collection_id
        WHERE i.normalized_title = ?
        ORDER BY i.created_at DESC
      ''', [normalizedTitle]);

      return result.map(PotentialDuplicateModel.fromMap).toList();
    }

    final placeholders = List.filled(imageHashes.length, '?').join(', ');

    final args = <Object?>[
      ...imageHashes,
      normalizedTitle,
      ...imageHashes,
    ];

    final result = await db.rawQuery('''
      SELECT DISTINCT
        i.id AS item_id,
        i.title,
        i.normalized_title,
        cat.name AS category_name,
        c.name AS collection_name,
        (
          SELECT ip.file_path
          FROM item_photos ip
          WHERE ip.item_id = i.id
          ORDER BY ip.is_primary DESC, ip.created_at ASC
          LIMIT 1
        ) AS primary_photo_path,
        (
          SELECT COUNT(*)
          FROM item_photos ip2
          WHERE ip2.item_id = i.id
            AND ip2.image_hash IN ($placeholders)
        ) AS matching_hash_count
      FROM items i
      INNER JOIN categories cat ON cat.id = i.category_id
      INNER JOIN collections c ON c.id = i.collection_id
      WHERE i.normalized_title = ?
         OR EXISTS (
           SELECT 1
           FROM item_photos ip3
           WHERE ip3.item_id = i.id
             AND ip3.image_hash IN ($placeholders)
         )
      ORDER BY i.created_at DESC
    ''', args);

    return result.map(PotentialDuplicateModel.fromMap).toList();
  }

  Future<List<PotentialDuplicateModel>> findItemsByImageHashes({
    required List<String> imageHashes,
  }) async {
    if (imageHashes.isEmpty) return [];

    final db = await _appDatabase.database;
    final placeholders = List.filled(imageHashes.length, '?').join(', ');

    final result = await db.rawQuery('''
      SELECT DISTINCT
        i.id AS item_id,
        i.title,
        i.normalized_title,
        cat.name AS category_name,
        c.name AS collection_name,
        (
          SELECT ip.file_path
          FROM item_photos ip
          WHERE ip.item_id = i.id
          ORDER BY ip.is_primary DESC, ip.created_at ASC
          LIMIT 1
        ) AS primary_photo_path,
        (
          SELECT COUNT(*)
          FROM item_photos ip2
          WHERE ip2.item_id = i.id
            AND ip2.image_hash IN ($placeholders)
        ) AS matching_hash_count
      FROM items i
      INNER JOIN categories cat ON cat.id = i.category_id
      INNER JOIN collections c ON c.id = i.collection_id
      WHERE EXISTS (
        SELECT 1
        FROM item_photos ip3
        WHERE ip3.item_id = i.id
          AND ip3.image_hash IN ($placeholders)
      )
      ORDER BY matching_hash_count DESC, i.created_at DESC
    ''', [
      ...imageHashes,
      ...imageHashes,
    ]);

    return result.map(PotentialDuplicateModel.fromMap).toList();
  }

  Future<int> rebuildAllImageHashes(
    PhotoStorageService photoStorageService,
  ) async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      'item_photos',
      columns: ['id', 'file_path', 'image_hash'],
    );

    int updated = 0;

    for (final row in rows) {
      final photoId = row['id'] as String;
      final filePath = row['file_path'] as String;

      final hash = await photoStorageService.computeHashFromFilePath(filePath);

      if (hash == null || hash.isEmpty) continue;

      await db.update(
        'item_photos',
        {
          'image_hash': hash,
        },
        where: 'id = ?',
        whereArgs: [photoId],
      );

      updated++;
    }

    return updated;
  }

  Future<List<DuplicateGroupModel>> getDuplicateGroupsByTitle() async {
    final db = await _appDatabase.database;

    final result = await db.rawQuery('''
      SELECT
        MIN(i.title) AS display_value,
        COUNT(*) AS duplicate_count,
        'name' AS type
      FROM items i
      GROUP BY i.normalized_title
      HAVING COUNT(*) > 1
      ORDER BY duplicate_count DESC, display_value COLLATE NOCASE ASC
    ''');

    return result.map(DuplicateGroupModel.fromMap).toList();
  }

  Future<List<DuplicateGroupModel>> getDuplicateGroupsByImageHash() async {
    final db = await _appDatabase.database;

    final result = await db.rawQuery('''
      SELECT
        'Hash ' || SUBSTR(ip.image_hash, 1, 12) AS display_value,
        COUNT(DISTINCT ip.item_id) AS duplicate_count,
        'image' AS type
      FROM item_photos ip
      WHERE ip.image_hash IS NOT NULL
        AND ip.image_hash != ''
      GROUP BY ip.image_hash
      HAVING COUNT(DISTINCT ip.item_id) > 1
      ORDER BY duplicate_count DESC, display_value ASC
    ''');

    return result.map(DuplicateGroupModel.fromMap).toList();
  }

  Future<void> debugPrintDatabaseState() async {
    final db = await _appDatabase.database;

    final itemCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM items'),
    );

    final categoryCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );

    final collectionCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM collections'),
    );

    final photoCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM item_photos'),
    );

    debugPrint(
      'DB STATE => items=$itemCount, '
      'categories=$categoryCount, '
      'collections=$collectionCount, '
      'photos=$photoCount',
    );

    final rawItems = await db.rawQuery('''
      SELECT id, title, category_id, collection_id
      FROM items
      ORDER BY title COLLATE NOCASE ASC
    ''');

    for (final row in rawItems) {
      debugPrint('RAW ITEM => $row');
    }
  }

  Future<List<ItemGalleryModel>> getAllItemsForGallery() async {
    final db = await _appDatabase.database;

    final result = await db.rawQuery('''
      SELECT
        i.id AS item_id,
        i.title,
        i.description,
        i.category_id,
        COALESCE(cat.name, 'Sin categoría') AS category_name,
        i.collection_id,
        COALESCE(c.name, 'Sin colección') AS collection_name,
        (
          SELECT ip.file_path
          FROM item_photos ip
          WHERE ip.item_id = i.id
          ORDER BY ip.is_primary DESC, ip.created_at ASC
          LIMIT 1
        ) AS primary_photo_path,
        (
          SELECT COUNT(*)
          FROM item_photos ip2
          WHERE ip2.item_id = i.id
        ) AS photo_count
      FROM items i
      LEFT JOIN categories cat ON cat.id = i.category_id
      LEFT JOIN collections c ON c.id = i.collection_id
      ORDER BY
        category_name COLLATE NOCASE ASC,
        collection_name COLLATE NOCASE ASC,
        i.title COLLATE NOCASE ASC
    ''');

    return result.map(ItemGalleryModel.fromMap).toList();
  }

  Future<ItemDetailModel?> getItemDetail(String itemId) async {
    final db = await _appDatabase.database;

    final result = await db.rawQuery('''
      SELECT
        i.id AS item_id,
        i.title,
        i.description,
        i.category_id,
        i.collection_id,
        i.created_at,
        cat.name AS category_name,
        c.name AS collection_name
      FROM items i
      INNER JOIN categories cat ON cat.id = i.category_id
      INNER JOIN collections c ON c.id = i.collection_id
      WHERE i.id = ?
      LIMIT 1
    ''', [itemId]);

    if (result.isEmpty) return null;

    return ItemDetailModel.fromMap(result.first);
  }

  Future<List<ItemDetailPhotoModel>> getPhotosByItemId(String itemId) async {
    final db = await _appDatabase.database;

    final result = await db.query(
      'item_photos',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'is_primary DESC, created_at ASC',
    );

    return result.map(ItemDetailPhotoModel.fromMap).toList();
  }

  Future<void> deleteItem(String itemId) async {
    final db = await _appDatabase.database;

    await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<Map<String, dynamic>>> getImageSearchCandidates() async {
    final db = await _appDatabase.database;

    final result = await db.rawQuery('''
    SELECT
      i.id AS itemId,
      i.title AS title,
      cat.name AS categoryName,
      c.name AS collectionName,
      (
        SELECT ip.file_path
        FROM item_photos ip
        WHERE ip.item_id = i.id
        ORDER BY ip.is_primary DESC, ip.created_at ASC
        LIMIT 1
      ) AS photoPath
    FROM items i
    INNER JOIN categories cat ON cat.id = i.category_id
    INNER JOIN collections c ON c.id = i.collection_id
    ORDER BY i.created_at DESC
  ''');

    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
