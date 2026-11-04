import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/study_session.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('uum_smartlog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // CREATE
  Future<int> insertSession(StudySession session) async {
    final db = await database;
    return await db.insert('study_sessions', session.toMap());
  }

  // READ - paginated (LIMIT/OFFSET) - newest first
  Future<List<StudySession>> getSessionsPaged({
    required int page,
    int pageSize = 10,
  }) async {
    final db = await database;
    final offset = (page - 1) * pageSize;
    final result = await db.query(
      'study_sessions',
      orderBy: 'createdAt DESC, id DESC',
      limit: pageSize,
      offset: offset,
    );
    return result.map((map) => StudySession.fromMap(map)).toList();
  }

  // COUNT for total pages
  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM study_sessions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // UPDATE
  Future<int> updateSession(StudySession session) async {
    final db = await database;
    return await db.update(
      'study_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // DELETE
  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'study_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}