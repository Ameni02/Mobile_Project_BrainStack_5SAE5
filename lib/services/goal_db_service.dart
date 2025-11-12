// filepath: f:\ESPRIT\Mobile\Mobile_Project_BrainStack_5SAE5\lib\services\goal_db_service.dart

import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/goal_model.dart';

/// Service SQLite pour persister uniquement les Financial Goals.
/// Stocke une table `goals` avec une colonne `data` qui contient le JSON complet
/// du Goal (y compris milestones et contributions). Les opérations CRUD sont
/// exposées en tant que méthodes async.
class GoalDbService {
  static final GoalDbService instance = GoalDbService._init();
  static Database? _database;

  GoalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('goals.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT,
        target REAL NOT NULL,
        current REAL NOT NULL,
        deadline TEXT,
        createdAt TEXT,
        priority TEXT,
        description TEXT,
        emoji TEXT,
        data TEXT NOT NULL
      )
    ''');
  }

  Future<List<Goal>> fetchAllGoals() async {
    final db = await instance.database;
    final rows = await db.query('goals', orderBy: "createdAt DESC");
    return rows.map((r) => Goal.fromMap(json.decode(r['data'] as String))).toList();
  }

  Future<void> insertGoal(Goal goal) async {
    final db = await instance.database;
    final map = goal.toMap();
    await db.insert(
      'goals',
      {
        'id': goal.id,
        'title': goal.title,
        'category': goal.category,
        'target': goal.target,
        'current': goal.current,
        'deadline': goal.deadline,
        'createdAt': goal.createdAt.toIso8601String(),
        'priority': goal.priority,
        'description': goal.description,
        'emoji': goal.emoji,
        'data': json.encode(map),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await instance.database;
    final map = goal.toMap();
    await db.update(
      'goals',
      {
        'title': goal.title,
        'category': goal.category,
        'target': goal.target,
        'current': goal.current,
        'deadline': goal.deadline,
        'createdAt': goal.createdAt.toIso8601String(),
        'priority': goal.priority,
        'description': goal.description,
        'emoji': goal.emoji,
        'data': json.encode(map),
      },
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await instance.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addContribution(String goalId, GoalTransaction tx) async {
    final db = await instance.database;
    final rows = await db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (rows.isEmpty) return;
    final goal = Goal.fromMap(json.decode(rows.first['data'] as String));
    final newContributions = List<GoalTransaction>.from(goal.contributions)..add(tx);
    final updated = goal.copyWith(contributions: newContributions, current: goal.current + tx.amount);
    await updateGoal(updated);
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}

