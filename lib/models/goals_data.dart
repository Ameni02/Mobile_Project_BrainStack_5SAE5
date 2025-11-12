import 'dart:async';

import '../services/goal_db_service.dart';
import 'goal_model.dart';

/// Gestion centralisée des goals (persistance via GoalDbService).
/// Fournit une API statique utilisée par les composants UI.
class GoalsData {
  // Liste en mémoire des goals. Composants lisent directement GoalsData.goals.
  static List<Goal> goals = [];

  /// Charge depuis la base SQLite (GoalDbService). Si aucune donnée, laisse la liste vide.
  static Future<void> load() async {
    try {
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {
      goals = [];
    }
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
  }

  /// Ajoute un nouveau goal et le persiste.
  static Future<void> addGoal(Goal goal) async {
    try {
      await GoalDbService.instance.insertGoal(goal);
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {}
  }

  /// Met à jour un goal existant.
  static Future<void> updateGoal(Goal updated) async {
    try {
      await GoalDbService.instance.updateGoal(updated);
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {}
  }

  /// Supprime un goal par identifiant.
  static Future<void> deleteGoal(String id) async {
    try {
      await GoalDbService.instance.deleteGoal(id);
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {}
  }

  /// Ajoute une contribution à un goal identifié par [goalId].
  /// Si le goal n'existe pas, rien n'est fait.
  static Future<void> addContribution(String goalId, GoalTransaction tx) async {
    try {
      await GoalDbService.instance.addContribution(goalId, tx);
      goals = await GoalDbService.instance.fetchAllGoals();
    } catch (_) {}
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
  }

  /// Pourcentage moyen d'avancement des goals actifs (0..100)
  static double get overallProgress {
    if (goals.isEmpty) return 0.0;
    final activeGoals = goals.where((g) => !g.isCompleted && !g.isArchived).toList();
    if (activeGoals.isEmpty) return 100.0;
    final totalProgress = activeGoals.fold<double>(0.0, (sum, goal) => sum + goal.progress);
    return totalProgress / activeGoals.length;
  }
}