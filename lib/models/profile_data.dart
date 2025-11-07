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
      content:
          "Remember to allocate 20% for savings, 50% for needs, and 30% for wants. Track expenses daily for better control.",
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Note(
      id: 2,
      title: "Investment Strategy",
      content:
          "Diversify portfolio across stocks, bonds, and real estate. Consider index funds for long-term growth.",
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Note(
      id: 3,
      title: "Emergency Fund Progress",
      content:
          "Current progress: 65% complete. Need to save \$3,500 more to reach \$10,000 target by Dec 2025.",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
  ];
}
