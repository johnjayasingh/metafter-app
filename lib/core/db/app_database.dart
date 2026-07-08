import 'package:sqflite/sqflite.dart';

/// Bootstrap for the on-device SQLite store (`metafter.db`).
///
/// Schema v1 mirrors ARCHITECTURE.md §5: everything the app knows lives in
/// these seven tables; key material stays in secure storage, never here.
/// Repositories in this directory are the only consumers.
abstract final class AppDatabase {
  /// Database file name inside [DatabaseFactory.getDatabasesPath].
  static const String dbName = 'metafter.db';

  /// Current schema version.
  ///
  /// v2 adds the durable `seen_messages` replay ledger (finding [0]).
  static const int schemaVersion = 2;

  /// Open (creating on first run) the app database.
  ///
  /// [factory] defaults to the sqflite plugin factory; tests inject
  /// `sqflite_common_ffi`'s `databaseFactoryFfi`. [path] defaults to
  /// `<databasesPath>/metafter.db`; tests may pass `inMemoryDatabasePath`.
  static Future<Database> openAppDatabase({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactorySqflitePlugin;
    final dbPath = path ?? '${await f.getDatabasesPath()}/$dbName';
    return f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSeenMessages(db);
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Single-row own profile (id is always 1).
    await db.execute('''
      CREATE TABLE my_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        sub TEXT NOT NULL,
        name TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL DEFAULT '',
        designation TEXT NOT NULL DEFAULT '',
        company TEXT NOT NULL DEFAULT '',
        intro TEXT NOT NULL DEFAULT '',
        photo_path TEXT,
        verified INTEGER NOT NULL DEFAULT 0,
        verified_badge_sig TEXT
      )
    ''');

    // "Crossed paths" ledger. peer_sub is denormalised out of card_json so
    // the merge query does not have to parse JSON.
    await db.execute('''
      CREATE TABLE encounters (
        id TEXT PRIMARY KEY,
        peer_eid TEXT NOT NULL,
        peer_sub TEXT NOT NULL DEFAULT '',
        card_json TEXT NOT NULL,
        first_seen INTEGER NOT NULL,
        last_seen INTEGER NOT NULL,
        meters REAL NOT NULL,
        sent_request_id TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_encounters_last_seen ON encounters (last_seen)');
    await db.execute(
        'CREATE INDEX idx_encounters_peer_sub ON encounters (peer_sub)');
    await db.execute(
        'CREATE INDEX idx_encounters_peer_eid ON encounters (peer_eid)');

    // Connection requests, both directions.
    await db.execute('''
      CREATE TABLE requests (
        id TEXT PRIMARY KEY,
        direction TEXT NOT NULL,
        peer_sub TEXT NOT NULL,
        card_json TEXT NOT NULL,
        note TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_requests_dir_status ON requests (direction, status)');

    // Active connections.
    await db.execute('''
      CREATE TABLE connections (
        peer_sub TEXT PRIMARY KEY,
        card_json TEXT NOT NULL,
        connected_at INTEGER NOT NULL,
        mood_at_meet INTEGER
      )
    ''');

    // Chat list summaries (one row per 1:1 thread).
    await db.execute('''
      CREATE TABLE threads (
        peer_sub TEXT PRIMARY KEY,
        card_json TEXT NOT NULL,
        last_message TEXT NOT NULL DEFAULT '',
        last_message_at INTEGER NOT NULL,
        last_from_me INTEGER NOT NULL DEFAULT 0,
        unread_count INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        disappearing_ttl_ms INTEGER
      )
    ''');

    // Message history; disappearing sweep honours expires_at.
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        peer_sub TEXT NOT NULL,
        from_me INTEGER NOT NULL,
        body TEXT NOT NULL,
        sent_at INTEGER NOT NULL,
        status TEXT NOT NULL,
        reaction TEXT,
        expires_at INTEGER
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_messages_peer_sent ON messages (peer_sub, sent_at)');
    await db.execute('CREATE INDEX idx_messages_expires ON messages '
        '(expires_at) WHERE expires_at IS NOT NULL');

    // Typed app settings, key/value TEXT.
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _createSeenMessages(db);
  }

  /// Durable processed-message ledger for replay protection (finding [0]).
  /// Independent of thread retention: an id stays here even after its message
  /// row is purged by the disappearing sweep, so a re-injected envelope is
  /// still recognised as a replay. Bounded by a periodic prune on `seen_at`.
  static Future<void> _createSeenMessages(Database db) async {
    await db.execute('''
      CREATE TABLE seen_messages (
        message_id TEXT PRIMARY KEY,
        seen_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_seen_messages_seen_at ON seen_messages (seen_at)');
  }

  /// Names of every table wiped by [clearAllData], in FK-safe order.
  static const List<String> _allTables = [
    'my_profile',
    'encounters',
    'requests',
    'connections',
    'threads',
    'messages',
    'settings',
    'seen_messages',
  ];

  /// Delete every row from every table (sign-out / account change, finding
  /// [10]). Keeps the schema so repositories can keep using the open handle.
  static Future<void> clearAllData(Database db) async {
    await db.transaction((txn) async {
      for (final table in _allTables) {
        await txn.delete(table);
      }
    });
  }
}
