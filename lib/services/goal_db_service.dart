// filepath: f:\ESPRIT\Mobile\Mobile_Project_BrainStack_5SAE5\lib\services\goal_db_service.dart

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../DB/DB.dart';
import '../models/goal_model.dart';

/// Service SQLite pour persister uniquement les Financial Goals.
/// Utilise la base partagée définie dans DB.dart (finance_dashboard.db)
/// avec une table `goals` dont la colonne `data` contient le JSON complet.
class GoalDbService {
  static final GoalDbService instance = GoalDbService._init();

  GoalDbService._init();

  Future<Database> get database async {
    // Récupère la base partagée
    return await DB.db;
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

  // No-op: la base partagée est gérée globalement par DB.db
  Future<void> close() async {
    return;
  }
}
