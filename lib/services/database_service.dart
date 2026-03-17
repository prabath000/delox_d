import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN userId TEXT NOT NULL DEFAULT "guest"');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE users (
          email TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          password TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add photoUrl column for existing users
      try {
        await db.execute('ALTER TABLE users ADD COLUMN photoUrl TEXT');
      } catch (e) {
        // Column might already exist if they downgraded/upgraded weirdly, ignore
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        email TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        photoUrl TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        progress REAL NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');
  }

  Future<String> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap());
    return task.id;
  }

  Future<List<Task>> readTasksForUser(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteAllTasksForUser(String userId) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> migrateGuestTasks(String newUserId) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      {'userId': newUserId.toLowerCase()},
      where: 'userId = ?',
      whereArgs: ['guest'],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
