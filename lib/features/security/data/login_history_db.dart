import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/login_event.dart';

class LoginHistoryDb {
  LoginHistoryDb._();
  static final LoginHistoryDb instance = LoginHistoryDb._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'keysafe_login_history.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE login_events (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp  TEXT    NOT NULL,
            latitude   REAL,
            longitude  REAL,
            city       TEXT,
            country    TEXT,
            is_trusted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insert(LoginEvent event) async {
    final db = await _database;
    return db.insert('login_events', event.toLocalMap());
  }

  Future<List<LoginEvent>> getAll({int limit = 50}) async {
    final db = await _database;
    final rows = await db.query(
      'login_events',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(LoginEvent.fromLocalMap).toList();
  }

  Future<void> setTrusted(String id, {required bool trusted}) async {
    final db = await _database;
    await db.update(
      'login_events',
      {'is_trusted': trusted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [int.tryParse(id) ?? id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('login_events', where: 'id = ?', whereArgs: [int.tryParse(id) ?? id]);
  }

  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('login_events');
  }

  /// Returns true if the given city+country combo is already trusted.
  Future<bool> isLocationTrusted(String? city, String? country) async {
    if (city == null && country == null) return false;
    final db = await _database;
    final rows = await db.query(
      'login_events',
      where: 'is_trusted = 1 AND city = ? AND country = ?',
      whereArgs: [city, country],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
