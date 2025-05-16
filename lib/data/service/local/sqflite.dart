import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

import './schema.dart';

class DatabaseService {
  DatabaseService();

  // late final Database _db;
  Database? _db;
  final _log = Logger('DatabaseService');

  Future<Database> getDatabase() async {
    // ignore: prefer_conditional_assignment
    if (_db == null) {
      _db = await openDatabase(
        dbname,
        version: dbversion,
        onCreate: (db, version) async {
          _log.fine('onCreate:$db, $version');
          // foreign keys not recognized
          await db.execute(fgkeyPragma);
          await db.execute(channelSchema);
          await db.execute(episodeSchema);
          await db.execute(settingsSchema);
        },
      );
    }
    return _db as Database;
  }

  Future<List<Map<String, Object?>>> query(String sql) async {
    final db = await getDatabase();
    _log.fine(sql);
    return db.rawQuery(sql);
  }

  Future<int> insert(String sql) async {
    final db = await getDatabase();
    _log.fine(sql);
    return db.rawInsert(sql);
  }

  Future<int> update(String sql) async {
    final db = await getDatabase();
    _log.fine(sql);
    return db.rawUpdate(sql);
  }

  Future<int> delete(String sql) async {
    final db = await getDatabase();
    _log.fine(sql);
    return db.rawDelete(sql);
  }
}
