import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/water_entry.dart';
import '../models/daily_goal.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dailydone.db');
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

  Future<void> initDatabase() async {
    await database;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE water_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        type INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type INTEGER NOT NULL,
        targetCount INTEGER,
        date INTEGER NOT NULL,
        currentCount INTEGER DEFAULT 0,
        isCompleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default water goal
    await db.insert('settings', {
      'key': 'daily_water_goal',
      'value': '2000', // 2 liters in milliliters
    });
  }

  // Water Entries
  Future<int> addWaterEntry(WaterEntry entry) async {
    final db = await database;
    return await db.insert('water_entries', entry.toMap());
  }

  Future<List<WaterEntry>> getTodayWaterEntries() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'water_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => WaterEntry.fromMap(map)).toList();
  }

  Future<int> getTodayTotalWater() async {
    final entries = await getTodayWaterEntries();
    return entries.fold<int>(0, (sum, entry) => sum + entry.amount);
  }

  // Daily Goals
  Future<int> addDailyGoal(DailyGoal goal) async {
    final db = await database;
    return await db.insert('daily_goals', goal.toMap());
  }

  Future<List<DailyGoal>> getTodayGoals() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final maps = await db.query(
      'daily_goals',
      where: 'date >= ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch],
    );

    return maps.map((map) => DailyGoal.fromMap(map)).toList();
  }

  Future<void> updateGoal(DailyGoal goal) async {
    final db = await database;
    await db.update(
      'daily_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // Settings
  Future<int> getDailyWaterGoal() async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['daily_water_goal'],
    );

    if (result.isNotEmpty) {
      return int.parse(result.first['value'] as String);
    }
    return 2000; // Default 2 liters
  }

  Future<void> setDailyWaterGoal(int milliliters) async {
    final db = await database;
    await db.update(
      'settings',
      {'value': milliliters.toString()},
      where: 'key = ?',
      whereArgs: ['daily_water_goal'],
    );
  }

  // Export functionality
  Future<String> exportToCSV() async {
    final entries = await getTodayWaterEntries();
    final goals = await getTodayGoals();

    final buffer = StringBuffer();

    // Water entries CSV
    buffer.writeln('Water Entries');
    buffer.writeln('Timestamp,Amount(ml),Type');
    for (final entry in entries) {
      buffer.writeln('${entry.timestamp},${entry.amount},${entry.type.label}');
    }

    buffer.writeln('\nDaily Goals');
    buffer.writeln('Title,Type,Target,Current,Completed');
    for (final goal in goals) {
      buffer.writeln(
          '${goal.title},${goal.type.name},${goal.targetCount ?? "N/A"},${goal.currentCount},${goal.isCompleted}'
      );
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/dailydone_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }
}