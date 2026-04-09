import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/app_user_model.dart';

class AuthRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;

  Future<int> countUsers() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM app_users');
    return (result.first['total'] as num).toInt();
  }

  Future<AppUserModel?> getFirstUser() async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      'app_users',
      orderBy: 'created_at ASC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return AppUserModel.fromMap(rows.first);
  }

  Future<AppUserModel?> findByUsername(String normalizedUsername) async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      'app_users',
      where: 'normalized_username = ?',
      whereArgs: [normalizedUsername],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return AppUserModel.fromMap(rows.first);
  }

  Future<void> insertUser(AppUserModel user) async {
    final db = await _appDatabase.database;
    await db.insert('app_users', user.toMap());
  }

  Future<void> insertOrReplaceUser(AppUserModel user) async {
    final db = await _appDatabase.database;
    await db.insert(
      'app_users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBiometricEnabled({
    required String userId,
    required bool enabled,
  }) async {
    final db = await _appDatabase.database;

    await db.update(
      'app_users',
      {
        'biometric_enabled': enabled ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> exportUsersForSync() async {
    final db = await _appDatabase.database;
    return db.query('app_users');
  }
}
