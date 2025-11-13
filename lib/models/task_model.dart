import 'dart:convert';

/// Les statuts possibles d'une tâche
enum TaskStatus { todo, inProgress, done }

/// Priorité de tâche
enum TaskPriority { normal, high }

class Task {
  int? id;
  String title;
  String description;
  String? category;
  DateTime date;
  String? startTime;
  String? endTime;
  TaskStatus status;
  TaskPriority priority;

  Task({
    this.id,
    required this.title,
    required this.description,
    this.category,
    required this.date,
    this.startTime,
    this.endTime,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.normal,
  });

  // Convertir Task → Map SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'status': status.name,
      'priority': priority.name,
    };
  }

  // Recréer Task ← Map SQLite
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'],
      date: DateTime.parse(map['date']),
      startTime: map['startTime'],
      endTime: map['endTime'],
      status: TaskStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
            (e) => e.name == map['priority'],
        orElse: () => TaskPriority.normal,
      ),
    );
  }

  // copyWith() pour le Dashboard
  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    DateTime? date,
    String? startTime,
    String? endTime,
    TaskStatus? status,
    TaskPriority? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }

  String toJson() => json.encode(toMap());
  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}
