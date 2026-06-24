import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'papo_wallet_v3.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── USERS ─────────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        name               TEXT    NOT NULL,
        phone              TEXT    NOT NULL UNIQUE,
        pin_hash           TEXT    NOT NULL,
        blockchain_addr    TEXT    NOT NULL,
        initials           TEXT    NOT NULL DEFAULT '',
        is_merchant        INTEGER NOT NULL DEFAULT 0,
        kyc_status         TEXT    NOT NULL DEFAULT 'none',
        face_verified      INTEGER NOT NULL DEFAULT 0,
        kyc_doc_type       TEXT,
        kyc_doc_name       TEXT,
        biometrics_enabled INTEGER NOT NULL DEFAULT 1,
        two_factor_enabled INTEGER NOT NULL DEFAULT 0,
        language           TEXT    NOT NULL DEFAULT 'fr',
        theme_mode         TEXT    NOT NULL DEFAULT 'dark',
        created_at         TEXT    NOT NULL
      )
    ''');

    // ── WALLET SLOTS (0-9 per user) ────────────────────────────────────────
    // name = user-chosen label, device_name = physical device name from devices_catalog
    await db.execute('''
      CREATE TABLE wallet_slots (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     INTEGER NOT NULL,
        slot        INTEGER NOT NULL,
        wallet_id   TEXT    NOT NULL UNIQUE,
        name        TEXT    NOT NULL DEFAULT 'Wallet',
        device_name TEXT    NOT NULL DEFAULT 'Inconnu',
        is_active   INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT    NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, slot)
      )
    ''');

    // ── WALLET BALANCES (per slot per asset) ──────────────────────────────
    await db.execute('''
      CREATE TABLE wallet_balances (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        slot_id   INTEGER NOT NULL,
        asset     TEXT    NOT NULL,
        balance   REAL    NOT NULL DEFAULT 0,
        FOREIGN KEY (slot_id) REFERENCES wallet_slots(id) ON DELETE CASCADE,
        UNIQUE(slot_id, asset)
      )
    ''');

    // ── DEVICE CATALOG (global list of device types) ──────────────────────
    await db.execute('''
      CREATE TABLE devices_catalog (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT    NOT NULL UNIQUE,
        icon TEXT    NOT NULL DEFAULT 'smartphone'
      )
    ''');

    // Seed device catalog
    for (final d in _deviceCatalog) {
      await db.insert('devices_catalog', d);
    }

    // ── TRANSACTIONS ──────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE transactions (
        id          TEXT    PRIMARY KEY,
        user_id     INTEGER NOT NULL,
        slot_id     INTEGER NOT NULL,
        title       TEXT    NOT NULL,
        amount      REAL    NOT NULL,
        asset       TEXT    NOT NULL,
        type        TEXT    NOT NULL,
        status      TEXT    NOT NULL DEFAULT 'completed',
        description TEXT    NOT NULL DEFAULT '',
        recipient   TEXT    NOT NULL DEFAULT '',
        method      TEXT    NOT NULL DEFAULT 'standard',
        is_offline  INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT    NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // ── NOTIFICATIONS ─────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE notifications (
        id         TEXT    PRIMARY KEY,
        user_id    INTEGER NOT NULL,
        title      TEXT    NOT NULL,
        content    TEXT    NOT NULL,
        type       TEXT    NOT NULL DEFAULT 'info',
        is_read    INTEGER NOT NULL DEFAULT 0,
        created_at TEXT    NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // ── SESSIONS (connected devices) ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE sessions (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        label      TEXT    NOT NULL,
        peer_id    TEXT    NOT NULL,
        is_current INTEGER NOT NULL DEFAULT 0,
        last_seen  TEXT    NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // ── TONTINE CIRCLES ────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE circles (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id         INTEGER NOT NULL,
        name            TEXT    NOT NULL,
        description     TEXT    NOT NULL DEFAULT '',
        target          REAL    NOT NULL,
        collected       REAL    NOT NULL DEFAULT 0,
        contribution    REAL    NOT NULL DEFAULT 100000,
        turn_month      TEXT    NOT NULL DEFAULT '',
        frequency       TEXT    NOT NULL DEFAULT 'monthly',
        created_at      TEXT    NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE circle_members (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        circle_id INTEGER NOT NULL,
        name      TEXT    NOT NULL,
        phone     TEXT    NOT NULL DEFAULT '',
        wallet_id TEXT    NOT NULL DEFAULT '',
        paid      INTEGER NOT NULL DEFAULT 0,
        paid_date TEXT,
        FOREIGN KEY (circle_id) REFERENCES circles(id) ON DELETE CASCADE
      )
    ''');

    // ── BILL PAYMENTS ─────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE bill_payments (
        id         TEXT    PRIMARY KEY,
        user_id    INTEGER NOT NULL,
        provider   TEXT    NOT NULL,
        reference  TEXT    NOT NULL,
        amount     REAL    NOT NULL,
        asset      TEXT    NOT NULL DEFAULT 'XOF',
        status     TEXT    NOT NULL DEFAULT 'completed',
        created_at TEXT    NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  static const List<Map<String, dynamic>> _deviceCatalog = [
    {'name': 'iPhone 15 Pro', 'icon': 'smartphone'},
    {'name': 'iPhone 14', 'icon': 'smartphone'},
    {'name': 'Samsung Galaxy S24', 'icon': 'smartphone'},
    {'name': 'Samsung Galaxy A54', 'icon': 'smartphone'},
    {'name': 'Tecno Camon 20', 'icon': 'smartphone'},
    {'name': 'Tecno Spark 20', 'icon': 'smartphone'},
    {'name': 'Infinix Hot 30', 'icon': 'smartphone'},
    {'name': 'Infinix Smart 7', 'icon': 'smartphone'},
    {'name': 'Xiaomi Redmi 12', 'icon': 'smartphone'},
    {'name': 'Huawei Y9s', 'icon': 'smartphone'},
    {'name': 'OPPO Reno 10', 'icon': 'smartphone'},
    {'name': 'Google Pixel 8', 'icon': 'smartphone'},
    {'name': 'OnePlus 12', 'icon': 'smartphone'},
    {'name': 'Autre appareil Android', 'icon': 'smartphone'},
    {'name': 'Tablette Android', 'icon': 'tablet'},
  ];

  // ─── Generic helpers ──────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawInsert(sql, args);
  }

  Future<int> dbUpdate(String table, Map<String, dynamic> row,
      String where, List<dynamic> args) async {
    final db = await database;
    return db.update(table, row, where: where, whereArgs: args);
  }

  Future<int> dbDelete(String table, String where, List<dynamic> args) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: args);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit);
  }

  Future<Map<String, dynamic>?> queryFirst(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final rows =
        await query(table, where: where, whereArgs: whereArgs, limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> rawExecute(String sql, [List<dynamic>? args]) async {
    final db = await database;
    await db.execute(sql, args);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }
}
