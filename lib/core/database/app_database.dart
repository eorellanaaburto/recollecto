import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recollecto.db');

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _ensureImageHashSchema(db);
        }
        if (oldVersion < 3) {
          await _ensureCollectionLogoSchema(db);
        }
      },
      onOpen: (db) async {
        await _ensureImageHashSchema(db);
        await _ensureCollectionLogoSchema(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        logo_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        collection_id TEXT NOT NULL,
        title TEXT NOT NULL,
        normalized_title TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE item_photos (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        image_hash TEXT,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_categories_normalized_name
      ON categories(normalized_name)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_collections_category_id
      ON collections(category_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_collections_normalized_name
      ON collections(normalized_name)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_items_collection_id
      ON items(collection_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_items_normalized_title
      ON items(normalized_title)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_item_photos_item_id
      ON item_photos(item_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_item_photos_image_hash
      ON item_photos(image_hash)
    ''');
  }

  Future<void> _ensureImageHashSchema(DatabaseExecutor db) async {
    final columns = await db.rawQuery("PRAGMA table_info(item_photos)");
    final hasImageHash =
        columns.any((column) => column['name'] == 'image_hash');

    if (!hasImageHash) {
      await db.execute(
        'ALTER TABLE item_photos ADD COLUMN image_hash TEXT',
      );
    }

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_item_photos_image_hash
      ON item_photos(image_hash)
    ''');
  }

  Future<void> _ensureCollectionLogoSchema(DatabaseExecutor db) async {
    final columns = await db.rawQuery("PRAGMA table_info(collections)");
    final hasLogoPath = columns.any((column) => column['name'] == 'logo_path');

    if (!hasLogoPath) {
      await db.execute(
        'ALTER TABLE collections ADD COLUMN logo_path TEXT',
      );
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
