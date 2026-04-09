import 'package:postgres/postgres.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';

class SqlBackupResult {
  final int categoryCount;
  final int collectionCount;
  final int itemCount;
  final int photoCount;

  const SqlBackupResult({
    required this.categoryCount,
    required this.collectionCount,
    required this.itemCount,
    required this.photoCount,
  });

  int get totalRows => categoryCount + collectionCount + itemCount + photoCount;
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
    final conn = await _open();

    try {
      final result = await conn.execute(
        'SELECT NOW(), current_database(), current_user',
      );

      final row = result.first;
      return 'OK • db=${row[1]} • user=${row[2]} • now=${row[0]}';
    } finally {
      await conn.close();
    }
  }

  Future<String> writeTestRow() async {
    final conn = await _open();

    try {
      await _ensureSchema(conn);

      final result = await conn.execute(
        r'''
        INSERT INTO categories (id, name, normalized_name, created_at)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          normalized_name = EXCLUDED.normalized_name,
          created_at = EXCLUDED.created_at
        ''',
        parameters: [
          'cat_test_flutter_${DateTime.now().millisecondsSinceEpoch}',
          'Prueba Flutter',
          'prueba flutter',
          DateTime.now().toIso8601String(),
        ],
      );

      return 'Inserción OK • filas=${result.affectedRows}';
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

  Future<SqlBackupResult> backupLocalSqlToServer() async {
    const tag = 'PostgresRemoteService';

    final db = await _appDatabase.database;

    final categories = await db.query('categories');
    final collections = await db.query('collections');
    final items = await db.query('items');
    final photos = await db.query('item_photos');

    AppLogger.instance.info(
      tag,
      'Preparando respaldo SQL '
      'cat=${categories.length}, '
      'col=${collections.length}, '
      'items=${items.length}, '
      'photos=${photos.length}',
    );

    final conn = await _open();

    try {
      await conn.runTx((tx) async {
        await _ensureSchema(tx);

        for (final row in categories) {
          await tx.execute(
            r'''
            INSERT INTO categories (id, name, normalized_name, created_at)
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
        }

        for (final row in collections) {
          await tx.execute(
            r'''
            INSERT INTO collections (id, category_id, name, normalized_name, logo_path, created_at)
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
        }

        for (final row in items) {
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
        }

        for (final row in photos) {
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
        }
      });

      AppLogger.instance.info(tag, 'Respaldo SQL completado correctamente');

      return SqlBackupResult(
        categoryCount: categories.length,
        collectionCount: collections.length,
        itemCount: items.length,
        photoCount: photos.length,
      );
    } finally {
      await conn.close();
    }
  }

  Future<void> _ensureSchema(dynamic executor) async {
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
        logo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

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

    await _ensureCollectionLogoColumn(executor);
  }

  Future<void> _ensureCollectionLogoColumn(dynamic executor) async {
    try {
      await executor.execute(
        'ALTER TABLE collections ADD COLUMN logo_path TEXT',
      );
    } catch (_) {
      // La columna ya existe.
    }
  }
}
