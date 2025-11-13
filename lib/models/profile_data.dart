class Objective {
  final int id;
  final String title;
  final double target;
  final double current;
  final String deadline;
  final String category;

  Objective({
    required this.id,
    required this.title,
    required this.target,
    required this.current,
    required this.deadline,
    required this.category,
  });

  double get progress => (current / target) * 100;
  double get remaining => target - current;
}

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

class Note {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ProfileData {
  static final List<Objective> objectives = [
    Objective(
      id: 1,
      title: "Emergency Fund",
      target: 10000,
      current: 6500,
      deadline: "Dec 2025",
      category: "Savings",
    ),
    Objective(
      id: 2,
      title: "Vacation to Japan",
      target: 5000,
      current: 2800,
      deadline: "Jun 2025",
      category: "Travel",
    ),
    Objective(
      id: 3,
      title: "New Laptop",
      target: 2000,
      current: 1650,
      deadline: "Mar 2025",
      category: "Shopping",
    ),
    Objective(
      id: 4,
      title: "Investment Portfolio",
      target: 15000,
      current: 8200,
      deadline: "Dec 2026",
      category: "Investment",
    ),
  ];

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

  static final List<Note> notes = [
    Note(
      id: 1,
      title: "Budget Planning Tips",
      content: "Remember to allocate 20% for savings, 50% for needs, and 30% for wants. Track expenses daily for better control.",
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Note(
      id: 2,
      title: "Investment Strategy",
      content: "Diversify portfolio across stocks, bonds, and real estate. Consider index funds for long-term growth.",
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Note(
      id: 3,
      title: "Emergency Fund Progress",
      content: "Current progress: 65% complete. Need to save \$3,500 more to reach \$10,000 target by Dec 2025.",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
  ];

  static double get totalTarget => objectives.fold(0, (sum, obj) => sum + obj.target);
  static double get totalCurrent => objectives.fold(0, (sum, obj) => sum + obj.current);
  static double get overallProgress => (totalCurrent / totalTarget) * 100;
}
