import 'package:postgres/postgres.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/domain/models/app_user_model.dart';

class SqlBackupResult {
  final int userCount;
  final int categoryCount;
  final int collectionCount;
  final int itemCount;
  final int photoCount;

  const SqlBackupResult({
    required this.userCount,
    required this.categoryCount,
    required this.collectionCount,
    required this.itemCount,
    required this.photoCount,
  });

  int get totalRows =>
      userCount + categoryCount + collectionCount + itemCount + photoCount;
}

class SqlRestoreResult {
  final int userCount;
  final int categoryCount;
  final int collectionCount;
  final int itemCount;
  final int photoCount;

  const SqlRestoreResult({
    required this.userCount,
    required this.categoryCount,
    required this.collectionCount,
    required this.itemCount,
    required this.photoCount,
  });
}

class PostgresRemoteService {
  static const String _host = '100.79.205.20';
  static const int _port = 5432;
  static const String _database = 'recollecto_db';
  static const String _username = 'recollecto_user';
  static const String _password = 'ima3298a';

  final AppDatabase _appDatabase = AppDatabase.instance;

  Future<Connection> _open() {
    return Connection.open(
      Endpoint(
        host: _host,
        port: _port,
        database: _database,
        username: _username,
        password: _password,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
  }

  Future<bool> isServerAvailable() async {
    const tag = 'PostgresRemoteService';

    try {
      final conn = await _open();
      try {
        await conn.execute('SELECT 1');
        AppLogger.instance.info(tag, 'Servidor PostgreSQL disponible');
        return true;
      } finally {
        await conn.close();
      }
    } catch (e, st) {
      AppLogger.instance.error(tag, 'Servidor PostgreSQL no disponible', e, st);
      return false;
    }
  }

  Future<String> testConnection() async {
    const tag = 'PostgresRemoteService';
    final conn = await _open();

    try {
      final result = await conn.execute(
        'SELECT NOW(), current_database(), current_user',
      );

      final row = result.first;
      final message = 'OK • db=${row[1]} • user=${row[2]} • now=${row[0]}';
      AppLogger.instance.info(tag, 'Prueba de conexión OK: $message');
      return message;
    } catch (e, st) {
      AppLogger.instance.error(tag, 'Error probando conexión remota', e, st);
      rethrow;
    } finally {
      await conn.close();
    }
  }

  Future<String> writeTestRow() async {
    const tag = 'PostgresRemoteService';
    final conn = await _open();

    try {
      await _ensureSchema(conn);

      final id = 'cat_test_flutter_${DateTime.now().millisecondsSinceEpoch}';

      final result = await conn.execute(
        r'''
        INSERT INTO categories (
          id,
          name,
          normalized_name,
          created_at
        )
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          normalized_name = EXCLUDED.normalized_name,
          created_at = EXCLUDED.created_at
        ''',
        parameters: [
          id,
          'Prueba Flutter',
          'prueba flutter',
          DateTime.now().toIso8601String(),
        ],
      );

      final message = 'Inserción OK • filas=${result.affectedRows} • id=$id';
      AppLogger.instance.info(tag, message);
      return message;
    } catch (e, st) {
      AppLogger.instance
          .error(tag, 'Error en inserción de prueba remota', e, st);
      rethrow;
    } finally {
      await conn.close();
    }
  }

  Future<void> initializeSchema() async {
    final conn = await _open();

    try {
      await _ensureSchema(conn);
    } finally {
      await conn.close();
    }
  }

  Future<bool> userExistsByUsername(String normalizedUsername) async {
    const tag = 'PostgresRemoteService';
    final conn = await _open();

    try {
      await _ensureSchema(conn);

      final result = await conn.execute(
        '''
        SELECT 1
        FROM app_users
        WHERE normalized_username = \$1
        LIMIT 1
        ''',
        parameters: [normalizedUsername],
      );

      return result.isNotEmpty;
    } catch (e, st) {
      AppLogger.instance.error(
        tag,
        'Error consultando existencia de usuario remoto: $normalizedUsername',
        e,
        st,
      );
      rethrow;
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, dynamic>?> findRemoteUserByUsername(
    String normalizedUsername,
  ) async {
    const tag = 'PostgresRemoteService';
    final conn = await _open();

    try {
      await _ensureSchema(conn);

      final result = await conn.execute(
        '''
        SELECT
          id,
          username,
          normalized_username,
          password_hash,
          password_salt,
          biometric_enabled,
          created_at,
          updated_at
        FROM app_users
        WHERE normalized_username = \$1
        LIMIT 1
        ''',
        parameters: [normalizedUsername],
      );

      if (result.isEmpty) return null;

      final row = result.first;

      return {
        'id': row[0],
        'username': row[1],
        'normalized_username': row[2],
        'password_hash': row[3],
        'password_salt': row[4],
        'biometric_enabled': row[5],
        'created_at': row[6],
        'updated_at': row[7],
      };
    } catch (e, st) {
      AppLogger.instance.error(
        tag,
        'Error consultando usuario remoto: $normalizedUsername',
        e,
        st,
      );
      rethrow;
    } finally {
      await conn.close();
    }
  }

  Future<void> upsertRemoteUser(AppUserModel user) async {
    const tag = 'PostgresRemoteService';
    final conn = await _open();

    try {
      await _ensureSchema(conn);

      await conn.execute(
        r'''
        INSERT INTO app_users (
          id,
          username,
          normalized_username,
          password_hash,
          password_salt,
          biometric_enabled,
          created_at,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        ON CONFLICT (normalized_username) DO UPDATE SET
          username = EXCLUDED.username,
          password_hash = EXCLUDED.password_hash,
          password_salt = EXCLUDED.password_salt,
          biometric_enabled = EXCLUDED.biometric_enabled,
          updated_at = EXCLUDED.updated_at
        ''',
        parameters: [
          user.id,
          user.username,
          user.normalizedUsername,
          user.passwordHash,
          user.passwordSalt,
          user.biometricEnabled ? 1 : 0,
          user.createdAt.toIso8601String(),
          user.updatedAt.toIso8601String(),
        ],
      );

      AppLogger.instance.info(
        tag,
        'Usuario remoto insertado/actualizado: ${user.username}',
      );
    } catch (e, st) {
      AppLogger.instance.error(
        tag,
        'Error haciendo upsert remoto de usuario: ${user.username}',
        e,
        st,
      );
      rethrow;
    } finally {
      await conn.close();
    }
  }

  Future<SqlBackupResult> backupLocalSqlToServer() async {
    const tag = 'PostgresRemoteService';

    final db = await _appDatabase.database;

    final users = await db.query('app_users');
    final categories = await db.query('categories');
    final collections = await db.query('collections');
    final items = await db.query('items');
    final photos = await db.query('item_photos');

    AppLogger.instance.info(
      tag,
      'Preparando respaldo SQL '
      'users=${users.length}, '
      'cat=${categories.length}, '
      'col=${collections.length}, '
      'items=${items.length}, '
      'photos=${photos.length}',
    );

    final conn = await _open();

    try {
      await conn.runTx((tx) async {
        await _ensureSchema(tx);

        for (final row in users) {
          try {
            await tx.execute(
              r'''
              INSERT INTO app_users (
                id,
                username,
                normalized_username,
                password_hash,
                password_salt,
                biometric_enabled,
                created_at,
                updated_at
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
              ON CONFLICT (normalized_username) DO UPDATE SET
                username = EXCLUDED.username,
                password_hash = EXCLUDED.password_hash,
                password_salt = EXCLUDED.password_salt,
                biometric_enabled = EXCLUDED.biometric_enabled,
                updated_at = EXCLUDED.updated_at
              ''',
              parameters: [
                row['id'],
                row['username'],
                row['normalized_username'],
                row['password_hash'],
                row['password_salt'],
                row['biometric_enabled'],
                row['created_at'],
                row['updated_at'],
              ],
            );
          } catch (e, st) {
            AppLogger.instance.error(
              tag,
              'Error insertando usuario id=${row['id']} username=${row['username']}',
              e,
              st,
            );
            rethrow;
          }
        }

        for (final row in categories) {
          try {
            await tx.execute(
              r'''
              INSERT INTO categories (
                id,
                name,
                normalized_name,
                created_at
              )
              VALUES ($1, $2, $3, $4)
              ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                normalized_name = EXCLUDED.normalized_name,
                created_at = EXCLUDED.created_at
              ''',
              parameters: [
                row['id'],
                row['name'],
                row['normalized_name'],
                row['created_at'],
              ],
            );
          } catch (e, st) {
            AppLogger.instance.error(
              tag,
              'Error insertando categoría id=${row['id']} name=${row['name']}',
              e,
              st,
            );
            rethrow;
          }
        }

        for (final row in collections) {
          try {
            await tx.execute(
              r'''
              INSERT INTO collections (
                id,
                category_id,
                name,
                normalized_name,
                logo_path,
                created_at
              )
              VALUES ($1, $2, $3, $4, $5, $6)
              ON CONFLICT (id) DO UPDATE SET
                category_id = EXCLUDED.category_id,
                name = EXCLUDED.name,
                normalized_name = EXCLUDED.normalized_name,
                logo_path = EXCLUDED.logo_path,
                created_at = EXCLUDED.created_at
              ''',
              parameters: [
                row['id'],
                row['category_id'],
                row['name'],
                row['normalized_name'],
                row['logo_path'],
                row['created_at'],
              ],
            );
          } catch (e, st) {
            AppLogger.instance.error(
              tag,
              'Error insertando colección '
              'id=${row['id']} '
              'category_id=${row['category_id']} '
              'name=${row['name']} '
              'logo_path=${row['logo_path']}',
              e,
              st,
            );
            rethrow;
          }
        }

        for (final row in items) {
          try {
            await tx.execute(
              r'''
              INSERT INTO items (
                id,
                category_id,
                collection_id,
                title,
                normalized_title,
                description,
                created_at
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7)
              ON CONFLICT (id) DO UPDATE SET
                category_id = EXCLUDED.category_id,
                collection_id = EXCLUDED.collection_id,
                title = EXCLUDED.title,
                normalized_title = EXCLUDED.normalized_title,
                description = EXCLUDED.description,
                created_at = EXCLUDED.created_at
              ''',
              parameters: [
                row['id'],
                row['category_id'],
                row['collection_id'],
                row['title'],
                row['normalized_title'],
                row['description'],
                row['created_at'],
              ],
            );
          } catch (e, st) {
            AppLogger.instance.error(
              tag,
              'Error insertando item '
              'id=${row['id']} '
              'category_id=${row['category_id']} '
              'collection_id=${row['collection_id']} '
              'title=${row['title']}',
              e,
              st,
            );
            rethrow;
          }
        }

        for (final row in photos) {
          try {
            await tx.execute(
              r'''
              INSERT INTO item_photos (
                id,
                item_id,
                file_path,
                file_name,
                image_hash,
                is_primary,
                created_at
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7)
              ON CONFLICT (id) DO UPDATE SET
                item_id = EXCLUDED.item_id,
                file_path = EXCLUDED.file_path,
                file_name = EXCLUDED.file_name,
                image_hash = EXCLUDED.image_hash,
                is_primary = EXCLUDED.is_primary,
                created_at = EXCLUDED.created_at
              ''',
              parameters: [
                row['id'],
                row['item_id'],
                row['file_path'],
                row['file_name'],
                row['image_hash'],
                row['is_primary'],
                row['created_at'],
              ],
            );
          } catch (e, st) {
            AppLogger.instance.error(
              tag,
              'Error insertando foto '
              'id=${row['id']} '
              'item_id=${row['item_id']} '
              'file_name=${row['file_name']} '
              'file_path=${row['file_path']}',
              e,
              st,
            );
            rethrow;
          }
        }
      });

      AppLogger.instance.info(tag, 'Respaldo SQL completado correctamente');

      return SqlBackupResult(
        userCount: users.length,
        categoryCount: categories.length,
        collectionCount: collections.length,
        itemCount: items.length,
        photoCount: photos.length,
      );
    } catch (e, st) {
      AppLogger.instance.error(
        tag,
        'Fallo el respaldo SQL completo hacia PostgreSQL',
        e,
        st,
      );
      rethrow;
    } finally {
      await conn.close();
    }
  }

  Future<SqlRestoreResult> restoreServerSqlToLocal() async {
    const tag = 'PostgresRemoteService';

    final conn = await _open();

    try {
      await _ensureSchema(conn);

      final users = await conn.execute('''
        SELECT
          id,
          username,
          normalized_username,
          password_hash,
          password_salt,
          biometric_enabled,
          created_at,
          updated_at
        FROM app_users
        ORDER BY created_at ASC
      ''');

      final categories = await conn.execute('''
        SELECT id, name, normalized_name, created_at
        FROM categories
        ORDER BY created_at ASC
      ''');

      final collections = await conn.execute('''
        SELECT id, category_id, name, normalized_name, logo_path, created_at
        FROM collections
        ORDER BY created_at ASC
      ''');

      final items = await conn.execute('''
        SELECT
          id,
          category_id,
          collection_id,
          title,
          normalized_title,
          description,
          created_at
        FROM items
        ORDER BY created_at ASC
      ''');

      final photos = await conn.execute('''
        SELECT
          id,
          item_id,
          file_path,
          file_name,
          image_hash,
          is_primary,
          created_at
        FROM item_photos
        ORDER BY created_at ASC
      ''');

      final db = await _appDatabase.database;

      await db.transaction((txn) async {
        await txn.delete('item_photos');
        await txn.delete('items');
        await txn.delete('collections');
        await txn.delete('categories');
        await txn.delete('app_users');

        for (final row in users) {
          await txn.insert('app_users', {
            'id': row[0],
            'username': row[1],
            'normalized_username': row[2],
            'password_hash': row[3],
            'password_salt': row[4],
            'biometric_enabled': row[5],
            'created_at': row[6],
            'updated_at': row[7],
          });
        }

        for (final row in categories) {
          await txn.insert('categories', {
            'id': row[0],
            'name': row[1],
            'normalized_name': row[2],
            'created_at': row[3],
          });
        }

        for (final row in collections) {
          await txn.insert('collections', {
            'id': row[0],
            'category_id': row[1],
            'name': row[2],
            'normalized_name': row[3],
            'logo_path': row[4],
            'created_at': row[5],
          });
        }

        for (final row in items) {
          await txn.insert('items', {
            'id': row[0],
            'category_id': row[1],
            'collection_id': row[2],
            'title': row[3],
            'normalized_title': row[4],
            'description': row[5],
            'created_at': row[6],
          });
        }

        for (final row in photos) {
          await txn.insert('item_photos', {
            'id': row[0],
            'item_id': row[1],
            'file_path': row[2],
            'file_name': row[3],
            'image_hash': row[4],
            'is_primary': row[5],
            'created_at': row[6],
          });
        }
      });

      AppLogger.instance.info(tag, 'Restauración SQL web -> local completada');

      return SqlRestoreResult(
        userCount: users.length,
        categoryCount: categories.length,
        collectionCount: collections.length,
        itemCount: items.length,
        photoCount: photos.length,
      );
    } catch (e, st) {
      AppLogger.instance.error(
        tag,
        'Fallo la restauración SQL desde PostgreSQL hacia SQLite',
        e,
        st,
      );
      rethrow;
    } finally {
      await conn.close();
    }
  }

  Future<void> _ensureSchema(dynamic executor) async {
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS app_users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        normalized_username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        biometric_enabled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await executor.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await executor.execute('''
      CREATE TABLE IF NOT EXISTS collections (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _ensureCollectionLogoColumn(executor);

    await executor.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
        collection_id TEXT NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        normalized_title TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await executor.execute('''
      CREATE TABLE IF NOT EXISTS item_photos (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL REFERENCES items(id) ON DELETE CASCADE,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        image_hash TEXT,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_app_users_normalized_username
      ON app_users(normalized_username)
    ''');

    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_categories_normalized_name
      ON categories(normalized_name)
    ''');

    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_collections_category_id
      ON collections(category_id)
    ''');

    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_collections_normalized_name
      ON collections(normalized_name)
    ''');

    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_items_collection_id
      ON items(collection_id)
    ''');

    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_items_normalized_title
      ON items(normalized_title)
    ''');

    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_item_photos_item_id
      ON item_photos(item_id)
    ''');

    await executor.execute('''
      CREATE INDEX IF NOT EXISTS idx_item_photos_image_hash
      ON item_photos(image_hash)
    ''');
  }

  Future<void> _ensureCollectionLogoColumn(dynamic executor) async {
    try {
      await executor.execute(
        'ALTER TABLE collections ADD COLUMN IF NOT EXISTS logo_path TEXT',
      );
    } catch (e, st) {
      AppLogger.instance.error(
        'PostgresRemoteService',
        'No se pudo asegurar la columna logo_path en collections. Se intentará una segunda forma de ALTER TABLE.',
        e,
        st,
      );

      try {
        await executor.execute(
          'ALTER TABLE collections ADD COLUMN logo_path TEXT',
        );
      } catch (_) {
        // La columna probablemente ya existe.
      }
    }
  }
}
