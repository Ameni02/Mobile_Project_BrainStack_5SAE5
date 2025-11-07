import 'dart:async';

import '../models/goal_model.dart';

/// Service d'API simulée pour FinancialGoals.
/// Actuellement mock local; peut être remplacé par des requêtes HTTP réelles.
class GoalApiService {
  // Simule une latence réseau
  static Future<T> _withDelay<T>(T result, [int ms = 400]) async {
    await Future.delayed(Duration(milliseconds: ms));
    return result;
  }

  static Future<List<Goal>> fetchGoals() async {
    // Ici on renvoie une liste vide: l'app utilisera GoalsData.load() pour persistance locale.
    return _withDelay<List<Goal>>([], 300);
  }

  static Future<Goal> createGoal(Goal goal) async {
    return _withDelay<Goal>(goal, 300);
  }

  static Future<Goal> updateGoal(Goal goal) async {
    return _withDelay<Goal>(goal, 300);
  }

  static Future<void> deleteGoal(String id) async {
    return _withDelay<void>(null, 200);
  }

  static Future<GoalTransaction> addContribution(String goalId, GoalTransaction transaction) async {
    return _withDelay<GoalTransaction>(transaction, 200);
  }
}
