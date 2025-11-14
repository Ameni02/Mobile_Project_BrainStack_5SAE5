import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/goal_db_service.dart';
import 'goal_model.dart';

/// Gestion centralisée des goals (persistance via GoalDbService).
/// Fournit une API statique utilisée par les composants UI.
class GoalsData {
  // Liste en mémoire des goals. Composants lisent directement GoalsData.goals.
  static List<Goal> goals = [];
  // Notifier pour mise à jour réactive (écouté par les tabs via ValueListenableBuilder)
  static final ValueNotifier<List<Goal>> goalsNotifier = ValueNotifier<List<Goal>>([]);

  static void _emit() {
    // Publie une copie immuable pour éviter modifications directes.
    goalsNotifier.value = List.unmodifiable(goals);
  }

  /// Charge depuis la base SQLite (GoalDbService). Si aucune donnée, laisse la liste vide.
  static Future<void> load() async {
    try {
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {
      goals = [];
    }
    _emit();
  }

  /// Sauvegarde la liste courante dans la base (upsert par goal).
  /// Note: pour simplicité on effectue un insert (qui utilise REPLACE) pour chaque goal.
  static Future<void> save() async {
    try {
      for (final g in goals) {
        await GoalDbService.instance.insertGoal(g);
      }
      // refresh in-memory list from DB to stay consistent
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {
      // ignore for now
    }
    _emit();
  }

  /// Ajoute un nouveau goal et le persiste.
  static Future<void> addGoal(Goal goal) async {
    try {
      await GoalDbService.instance.insertGoal(goal);
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {}
    _emit();
  }

  /// Met à jour un goal existant.
  static Future<void> updateGoal(Goal updated) async {
    try {
      await GoalDbService.instance.updateGoal(updated);
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {}
    _emit();
  }

  /// Supprime un goal par identifiant.
  static Future<void> deleteGoal(String id) async {
    try {
      await GoalDbService.instance.deleteGoal(id);
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {}
    _emit();
  }

  /// Ajoute une contribution à un goal identifié par [goalId].
  /// Si le goal n'existe pas, rien n'est fait.
  static Future<void> addContribution(String goalId, GoalTransaction tx) async {
    try {
      await GoalDbService.instance.addContribution(goalId, tx);
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {}
    _emit();
  }

  static Future<void> clearAll() async {
    // Supprime tous les goals en itérant (GoalDbService n'expose pas clear table).
    try {
      final all = await GoalDbService.instance.fetchAllGoals();
      for (final g in all) {
        await GoalDbService.instance.deleteGoal(g.id);
      }
      goals = [];
    } catch (_) {
      goals = [];
    }
    _emit();
  }

  /// Pourcentage moyen d'avancement des goals actifs (0..100)
  static double get overallProgress {
    if (goals.isEmpty) return 0.0;
    final activeGoals = goals.where((g) => !g.isCompleted && !g.isArchived).toList();
    if (activeGoals.isEmpty) return 100.0;
    final totalProgress = activeGoals.fold<double>(0.0, (sum, goal) => sum + goal.progress);
    return totalProgress / activeGoals.length;
  }

  static Future<void> ensureSeeded() async {
    if (goals.isNotEmpty) return;
    final now = DateTime.now();
    String fmt(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    final seedGoals = <Goal>[
      Goal(
        id: 'g1',
        title: 'Buy a Laptop',
        category: 'Electronics',
        target: 3000,
        current: 1200,
        deadline: fmt(now.add(const Duration(days: 60))),
        createdAt: now.subtract(const Duration(days: 5)),
        priority: 'high',
        description: 'New laptop for development and design tasks.',
        emoji: '💻',
        contributions: [
          GoalTransaction(id: 'tx1', amount: 500, date: now.subtract(const Duration(days: 4)), note: 'Initial savings'),
          GoalTransaction(id: 'tx2', amount: 700, date: now.subtract(const Duration(days: 1)), note: 'Bonus'),
        ],
      ),
      Goal(
        id: 'g2',
        title: 'Vacation Trip',
        category: 'Travel',
        target: 5000,
        current: 2500,
        deadline: fmt(now.add(const Duration(days: 75))),
        createdAt: now.subtract(const Duration(days: 10)),
        priority: 'medium',
        description: 'Save for summer vacation in Europe.',
        emoji: '✈️',
        contributions: [
          GoalTransaction(id: 'tx3', amount: 1500, date: now.subtract(const Duration(days: 9)), note: 'Salary portion'),
          GoalTransaction(id: 'tx4', amount: 1000, date: now.subtract(const Duration(days: 2)), note: 'Extra gig'),
        ],
      ),
      Goal(
        id: 'g3',
        title: 'Emergency Fund Phase 1',
        category: 'Savings',
        target: 2000,
        current: 2000,
        deadline: fmt(now.add(const Duration(days: 30))),
        createdAt: now.subtract(const Duration(days: 40)),
        priority: 'high',
        description: 'Basic emergency fund achieved.',
        emoji: '💰',
        contributions: [
          GoalTransaction(id: 'tx5', amount: 1000, date: now.subtract(const Duration(days: 35)), note: 'Start'),
          GoalTransaction(id: 'tx6', amount: 1000, date: now.subtract(const Duration(days: 20)), note: 'Completion'),
        ],
        isCompleted: true,
      ),
      Goal(
        id: 'g4',
        title: 'Fitness Equipment',
        category: 'Health',
        target: 1500,
        current: 1500,
        deadline: fmt(now.add(const Duration(days: 40))),
        createdAt: now.subtract(const Duration(days: 25)),
        priority: 'low',
        description: 'Completed home gym setup.',
        emoji: '💪',
        contributions: [
          GoalTransaction(id: 'tx7', amount: 600, date: now.subtract(const Duration(days: 20)), note: 'Weights'),
          GoalTransaction(id: 'tx8', amount: 900, date: now.subtract(const Duration(days: 12)), note: 'Bench + accessories'),
        ],
        isCompleted: true,
      ),
    ];
    for (final g in seedGoals) {
      await GoalDbService.instance.insertGoal(g);
    }
    goals = await GoalDbService.instance.fetchAllGoals();
    _emit();
  }

  static Future<void> migrateDeadlinesAndCompletion() async {
    if (goals.isEmpty) return;
    final now = DateTime.now();
    bool changed = false;
    final updatedList = <Goal>[];
    for (final g in goals) {
      DateTime? deadlineDt = DateTime.tryParse(g.deadline);
      var updated = g;
      if (deadlineDt != null && deadlineDt.isBefore(now)) {
        final newDeadline = now.add(const Duration(days: 45));
        updated = updated.copyWith(deadline: "${newDeadline.year}-${newDeadline.month.toString().padLeft(2, '0')}-${newDeadline.day.toString().padLeft(2, '0')}");
        changed = true;
      }
      if (updated.current >= updated.target && !updated.isCompleted) {
        updated = updated.copyWith(isCompleted: true);
        changed = true;
      }
      updatedList.add(updated);
    }
    if (changed) {
      for (final u in updatedList) {
        await GoalDbService.instance.updateGoal(u);
      }
      goals = await GoalDbService.instance.fetchAllGoals();
      _emit();
    }
  }
}
