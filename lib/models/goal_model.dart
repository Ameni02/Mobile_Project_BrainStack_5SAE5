// Définitions des modèles utilisés par le module FinancialGoals
// Goal, Milestone, GoalTransaction

import 'dart:convert';

class Goal {
  final String id;
  final String title;
  final String category;
  final double target;
  final double current;
  final String deadline; // YYYY-MM-DD
  final DateTime createdAt;
  final String priority; // low, medium, high
  final String description;
  final String emoji;
  final List<Milestone> milestones;
  final List<GoalTransaction> contributions;
  final bool isCompleted;
  final bool isArchived;

  Goal({
    required this.id,
    required this.title,
    required this.category,
    required this.target,
    required this.current,
    required this.deadline,
    required this.createdAt,
    required this.priority,
    this.description = '',
    this.emoji = '🎯',
    this.milestones = const [],
    this.contributions = const [],
    this.isCompleted = false,
    this.isArchived = false,
  });

  double get progress {
    if (target <= 0) return 0.0;
    final p = (current / target) * 100.0;
    if (p.isNaN) return 0.0;
    return p.clamp(0.0, 100.0);
  }

  /// Days remaining until deadline (0 if past).
  int get daysRemaining {
    try {
      final dt = DateTime.tryParse(deadline);
      if (dt == null) return 0;
      final diff = dt.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }

  /// Daily amount needed to reach target on time. If no days remaining, returns remaining amount.
  double dailySavingsNeeded() {
    final remaining = (target - current).clamp(0.0, double.infinity);
    final days = daysRemaining;
    if (days <= 0) return remaining.toDouble();
    return (remaining / days).toDouble();
  }

  Goal copyWith({
    String? id,
    String? title,
    String? category,
    double? target,
    double? current,
    String? deadline,
    DateTime? createdAt,
    String? priority,
    String? description,
    String? emoji,
    List<Milestone>? milestones,
    List<GoalTransaction>? contributions,
    bool? isCompleted,
    bool? isArchived,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      target: target ?? this.target,
      current: current ?? this.current,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      milestones: milestones ?? this.milestones,
      contributions: contributions ?? this.contributions,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'target': target,
      'current': current,
      'deadline': deadline,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'description': description,
      'emoji': emoji,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'contributions': contributions.map((t) => t.toMap()).toList(),
      'isCompleted': isCompleted,
      'isArchived': isArchived,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      target: (map['target'] as num).toDouble(),
      current: (map['current'] as num).toDouble(),
      deadline: map['deadline'] as String,
      createdAt: DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now(),
      priority: map['priority'] as String? ?? 'medium',
      description: map['description'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🎯',
      milestones: (map['milestones'] as List<dynamic>?)
              ?.map((m) => Milestone.fromMap(Map<String, dynamic>.from(m)))
              .toList() ??
          [],
      contributions: (map['contributions'] as List<dynamic>?)
              ?.map((t) => GoalTransaction.fromMap(Map<String, dynamic>.from(t)))
              .toList() ??
          [],
      isCompleted: map['isCompleted'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Goal.fromJson(String source) => Goal.fromMap(json.decode(source));
}

class Milestone {
  final String id;
  final String title;
  final double amount;
  final bool isCompleted;
  final DateTime? completedAt;

  Milestone({
    required this.id,
    required this.title,
    required this.amount,
    this.isCompleted = false,
    this.completedAt,
  });

  Milestone copyWith({
    String? id,
    String? title,
    double? amount,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
    );
  }
}

class GoalTransaction {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  GoalTransaction({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory GoalTransaction.fromMap(Map<String, dynamic> map) {
    return GoalTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.tryParse(map['date'] as String) ?? DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }
}
