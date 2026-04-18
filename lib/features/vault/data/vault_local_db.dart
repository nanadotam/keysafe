import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/vault_entry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VaultLocalDb — two-layer offline storage
//
// Layer 1 (SQLite) — fast, queryable, stores full VaultEntry rows.
//   • Used for list display, search, and filtering.
//   • Cleared and re-populated when a fresh server sync succeeds.
//
// Layer 2 (FlutterSecureStorage) — encrypted via AndroidKeystore / iOS Keychain.
//   • Stores a JSON snapshot of the entire vault as a fallback.
//   • Written every time the SQLite layer changes.
//   • Read when SQLite is empty (e.g. fresh install after backup restore).
//   • The passwords themselves are AES-GCM encrypted by CryptoService before
//     ever reaching this layer, so they are double-protected:
//       device keystore (hardware) → AES-GCM (software) → stored bytes.
//
// ─────────────────────────────────────────────────────────────────────────────

class VaultLocalDb {
  static Database? _db;

  // ── Secure storage (Android Keystore / iOS Keychain) ──────────────────────
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.passcode),
  );
  static const _secureVaultKey = 'vault_snapshot';

  // ── SQLite ────────────────────────────────────────────────────────────────

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'keysafe_vault.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS deleted_vault_entries (
              id               TEXT PRIMARY KEY,
              name             TEXT NOT NULL,
              username         TEXT NOT NULL,
              encrypted_password TEXT NOT NULL,
              url              TEXT DEFAULT '',
              notes            TEXT DEFAULT '',
              category         TEXT DEFAULT 'personal',
              strength_score   INTEGER DEFAULT 0,
              created_at       TEXT NOT NULL,
              updated_at       TEXT NOT NULL,
              deleted_at       TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE vault_entries (
        id               TEXT PRIMARY KEY,
        name             TEXT NOT NULL,
        username         TEXT NOT NULL,
        encrypted_password TEXT NOT NULL,
        url              TEXT DEFAULT '',
        notes            TEXT DEFAULT '',
        category         TEXT DEFAULT 'personal',
        strength_score   INTEGER DEFAULT 0,
        created_at       TEXT NOT NULL,
        updated_at       TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE deleted_vault_entries (
        id               TEXT PRIMARY KEY,
        name             TEXT NOT NULL,
        username         TEXT NOT NULL,
        encrypted_password TEXT NOT NULL,
        url              TEXT DEFAULT '',
        notes            TEXT DEFAULT '',
        category         TEXT DEFAULT 'personal',
        strength_score   INTEGER DEFAULT 0,
        created_at       TEXT NOT NULL,
        updated_at       TEXT NOT NULL,
        deleted_at       TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_ops (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        op        TEXT NOT NULL,
        data      TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns vault entries.
  /// Priority: SQLite  →  SecureStorage snapshot  (never empty-hands).
  static Future<List<VaultEntry>> getAll() async {
    final database = await db;
    final rows = await database.query('vault_entries');
    if (rows.isNotEmpty) {
      return rows.map(_rowToEntry).toList();
    }
    // SQLite is empty — try the secure snapshot (e.g. after a reinstall
    // where SQLite was wiped but Keychain data survived on iOS).
    return _loadSecureSnapshot();
  }

  static Future<List<VaultEntry>> _loadSecureSnapshot() async {
    try {
      final raw = await _secureStorage.read(key: _secureVaultKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => VaultEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  static Future<void> upsert(VaultEntry entry) async {
    final database = await db;
    await database.insert(
      'vault_entries',
      _entryToRow(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _persistSecureSnapshot();
  }

  static Future<void> delete(String id) async {
    final database = await db;
    await database.delete('vault_entries', where: 'id = ?', whereArgs: [id]);
    await _persistSecureSnapshot();
  }

  /// Moves an entry to the trash instead of permanently deleting it.
  static Future<void> softDelete(String id) async {
    final database = await db;
    final rows = await database.query(
      'vault_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return;
    final row = Map<String, dynamic>.from(rows.first);
    row['deleted_at'] = DateTime.now().toIso8601String();
    await database.insert(
      'deleted_vault_entries',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await database.delete('vault_entries', where: 'id = ?', whereArgs: [id]);
    await _persistSecureSnapshot();
    // Auto-purge entries deleted more than 30 days ago.
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    await database.delete(
      'deleted_vault_entries',
      where: 'deleted_at < ?',
      whereArgs: [cutoff],
    );
  }

  static Future<List<({VaultEntry entry, DateTime deletedAt})>>
      getDeleted() async {
    final database = await db;
    final rows = await database.query(
      'deleted_vault_entries',
      orderBy: 'deleted_at DESC',
    );
    return rows.map((r) {
      final entry = _rowToEntry(r);
      final deletedAt = DateTime.parse(r['deleted_at'] as String);
      return (entry: entry, deletedAt: deletedAt);
    }).toList();
  }

  static Future<void> restore(String id) async {
    final database = await db;
    final rows = await database.query(
      'deleted_vault_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return;
    final row = Map<String, dynamic>.from(rows.first)
      ..remove('deleted_at');
    await database.insert(
      'vault_entries',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await database.delete(
      'deleted_vault_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _persistSecureSnapshot();
  }

  static Future<void> permanentlyDelete(String id) async {
    final database = await db;
    await database.delete(
      'deleted_vault_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Replace the entire local cache (called after a successful server sync).
  static Future<void> replaceAll(List<VaultEntry> entries) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('vault_entries');
      for (final e in entries) {
        await txn.insert('vault_entries', _entryToRow(e));
      }
    });
    // Mirror to secure storage.
    await _persistSecureSnapshot(entries: entries);
  }

  /// Write a JSON snapshot of the current vault to the secure keystore.
  static Future<void> _persistSecureSnapshot({
    List<VaultEntry>? entries,
  }) async {
    try {
      final rows = entries ?? await getAll();
      final json = jsonEncode(rows.map((e) => e.toJson()).toList());
      await _secureStorage.write(key: _secureVaultKey, value: json);
    } catch (_) {
      // Snapshot write is best-effort — don't break the main flow.
    }
  }

  // ── Pending-ops queue ─────────────────────────────────────────────────────

  static Future<void> addPendingOp({
    required String op,
    required Map<String, dynamic> data,
  }) async {
    final database = await db;
    await database.insert('pending_ops', {
      'op':        op,
      'data':      jsonEncode(data),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingOps() async {
    final database = await db;
    final rows = await database.query('pending_ops', orderBy: 'timestamp ASC');
    return rows
        .map(
          (r) => {
            'id':        r['id'],
            'op':        r['op'],
            'data':      jsonDecode(r['data'] as String),
            'timestamp': r['timestamp'],
          },
        )
        .toList();
  }

  static Future<void> deletePendingOp(int id) async {
    final database = await db;
    await database.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  /// Clears both SQLite and the secure snapshot (called on logout/wipe).
  static Future<void> clearAll() async {
    final database = await db;
    await database.delete('vault_entries');
    await database.delete('deleted_vault_entries');
    await database.delete('pending_ops');
    try {
      await _secureStorage.delete(key: _secureVaultKey);
    } catch (_) {}
  }

  // ── Mapping helpers ───────────────────────────────────────────────────────

  static VaultEntry _rowToEntry(Map<String, dynamic> r) => VaultEntry(
        id:                r['id'] as String,
        name:              r['name'] as String,
        username:          r['username'] as String,
        encryptedPassword: r['encrypted_password'] as String,
        url:               r['url'] as String? ?? '',
        notes:             r['notes'] as String? ?? '',
        category:          r['category'] as String? ?? 'personal',
        strengthScore:     r['strength_score'] as int? ?? 0,
        createdAt:         DateTime.parse(r['created_at'] as String),
        updatedAt:         DateTime.parse(r['updated_at'] as String),
      );

  static Map<String, dynamic> _entryToRow(VaultEntry e) => {
        'id':                e.id,
        'name':              e.name,
        'username':          e.username,
        'encrypted_password': e.encryptedPassword,
        'url':               e.url,
        'notes':             e.notes,
        'category':          e.category,
        'strength_score':    e.strengthScore,
        'created_at':        e.createdAt.toIso8601String(),
        'updated_at':        e.updatedAt.toIso8601String(),
      };
}
