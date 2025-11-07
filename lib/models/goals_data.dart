import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'goal_model.dart';

/// Gestion centralisée des goals (persistance simple via SharedPreferences)
/// Fournit une API statique utilisée par les composants UI.
class GoalsData {
  static const _storageKey = 'goals_data_v1';

  // Liste en mémoire des goals. Composants lisent directement GoalsData.goals.
  static List<Goal> goals = [];

  /// Charge depuis SharedPreferences. Si aucune donnée, laisse la liste vide.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        goals = [];
        return;
      }
      final list = json.decode(raw) as List<dynamic>;
      goals = list
          .map((e) => Goal.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // en cas d'erreur de parsing, on remet à vide pour éviter données corrompues
      goals = [];
    }
  }

  /// Sauvegarde la liste courante dans SharedPreferences.
  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(goals.map((g) => g.toMap()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {
      // ignore write errors for now
    }
  }

  static Future<void> addGoal(Goal goal) async {
    goals.add(goal);
    await save();
  }

  static Future<void> updateGoal(Goal updated) async {
    final index = goals.indexWhere((g) => g.id == updated.id);
    if (index == -1) return;
    goals[index] = updated;
    await save();
  }

  static Future<void> deleteGoal(String id) async {
    goals.removeWhere((g) => g.id == id);
    await save();
  }

  /// Ajoute une contribution à un goal identifié par [goalId].
  /// Si le goal n'existe pas, rien n'est fait.
  static Future<void> addContribution(String goalId, GoalTransaction tx) async {
    final index = goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;
    final g = goals[index];
    final newContributions = List<GoalTransaction>.from(g.contributions)..add(tx);
    final updated = g.copyWith(contributions: newContributions, current: g.current + tx.amount);
    goals[index] = updated;
    await save();
  }

  static Future<void> clearAll() async {
    goals = [];
    await save();
  }

  /// Pourcentage moyen d'avancement des goals actifs (0..100)
  static double get overallProgress {
    if (goals.isEmpty) return 0;
    final activeGoals = goals.where((g) => !g.isCompleted && !g.isArchived).toList();
    if (activeGoals.isEmpty) return 100.0;
    final totalProgress = activeGoals.fold<double>(0, (sum, goal) => sum + goal.progress);
    return totalProgress / activeGoals.length;
  }
}