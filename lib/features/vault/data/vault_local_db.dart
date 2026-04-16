import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../domain/vault_entry.dart';

class VaultLocalDb {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'keysafe_vault.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vault_entries (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            username TEXT NOT NULL,
            encrypted_password TEXT NOT NULL,
            url TEXT DEFAULT '',
            notes TEXT DEFAULT '',
            category TEXT DEFAULT 'personal',
            strength_score INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_ops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            op TEXT NOT NULL,
            data TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<List<VaultEntry>> getAll() async {
    final database = await db;
    final rows = await database.query('vault_entries');
    return rows.map(_rowToEntry).toList();
  }

  static Future<void> upsert(VaultEntry entry) async {
    final database = await db;
    await database.insert(
      'vault_entries',
      _entryToRow(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> delete(String id) async {
    final database = await db;
    await database.delete('vault_entries', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> replaceAll(List<VaultEntry> entries) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('vault_entries');
      for (final e in entries) {
        await txn.insert('vault_entries', _entryToRow(e));
      }
    });
  }

  static Future<void> addPendingOp({
    required String op,
    required Map<String, dynamic> data,
  }) async {
    final database = await db;
    await database.insert('pending_ops', {
      'op': op,
      'data': jsonEncode(data),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingOps() async {
    final database = await db;
    final rows = await database.query(
      'pending_ops',
      orderBy: 'timestamp ASC',
    );
    return rows
        .map((r) => {
              'id': r['id'],
              'op': r['op'],
              'data': jsonDecode(r['data'] as String),
              'timestamp': r['timestamp'],
            })
        .toList();
  }

  static Future<void> deletePendingOp(int id) async {
    final database = await db;
    await database.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  static VaultEntry _rowToEntry(Map<String, dynamic> r) => VaultEntry(
        id: r['id'] as String,
        name: r['name'] as String,
        username: r['username'] as String,
        encryptedPassword: r['encrypted_password'] as String,
        url: r['url'] as String? ?? '',
        notes: r['notes'] as String? ?? '',
        category: r['category'] as String? ?? 'personal',
        strengthScore: r['strength_score'] as int? ?? 0,
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
      );

  static Map<String, dynamic> _entryToRow(VaultEntry e) => {
        'id': e.id,
        'name': e.name,
        'username': e.username,
        'encrypted_password': e.encryptedPassword,
        'url': e.url,
        'notes': e.notes,
        'category': e.category,
        'strength_score': e.strengthScore,
        'created_at': e.createdAt.toIso8601String(),
        'updated_at': e.updatedAt.toIso8601String(),
      };
}
