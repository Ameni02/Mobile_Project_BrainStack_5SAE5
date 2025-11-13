import './goals_data.dart';
import './goal_model.dart';

class TodoItem {
  final int id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });
}

class ProfileData {
  static final List<TodoItem> todos = [
    TodoItem(
      id: 1,
      title: "Review monthly budget",
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TodoItem(
      id: 2,
      title: "Set up automatic savings",
      isCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TodoItem(
      id: 3,
      title: "Research investment options",
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TodoItem(
      id: 4,
      title: "Update emergency fund goal",
      isCompleted: false,
      createdAt: DateTime.now(),
    ),
  ];

  // --- Ajouts pour compatibilité avec ExpenseChatbot ---
  // Importés dynamiquement via GoalsData.
  // Fournit une API de façade pour éviter de toucher aux composants existants.
  static List<Goal> get objectives => GoalsData.goals;
  static double get overallProgress => GoalsData.overallProgress;
}
