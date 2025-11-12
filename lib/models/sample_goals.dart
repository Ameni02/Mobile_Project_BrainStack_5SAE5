// Helper qui fournit des goals d'exemple pour le thème "student".

import 'package:uuid/uuid.dart';
import 'goal_model.dart';

final _uuid = Uuid();

List<Goal> studentSampleGoals({DateTime? now}) {
  final t = now ?? DateTime.now();
  return [
    Goal(
      id: _uuid.v4(),
      title: 'Buy textbooks',
      category: 'student',
      target: 250.0,
      current: 0.0,
      deadline: t.add(const Duration(days: 30)).toIso8601String().split('T').first,
      createdAt: t,
      priority: 'high',
      description: 'Purchase required textbooks for the semester',
      emoji: '📚',
    ),
    Goal(
      id: _uuid.v4(),
      title: 'Laptop fund',
      category: 'student',
      target: 800.0,
      current: 100.0,
      deadline: t.add(const Duration(days: 180)).toIso8601String().split('T').first,
      createdAt: t,
      priority: 'high',
      description: 'Save for a new laptop for coursework',
      emoji: '💻',
    ),
    Goal(
      id: _uuid.v4(),
      title: 'Study abroad application fees',
      category: 'student',
      target: 500.0,
      current: 0.0,
      deadline: t.add(const Duration(days: 90)).toIso8601String().split('T').first,
      createdAt: t,
      priority: 'medium',
      description: 'Application and visa fees for exchange program',
      emoji: '✈️',
    ),
    Goal(
      id: _uuid.v4(),
      title: 'Course materials & supplies',
      category: 'student',
      target: 120.0,
      current: 20.0,
      deadline: t.add(const Duration(days: 45)).toIso8601String().split('T').first,
      createdAt: t,
      priority: 'low',
      description: 'Notebooks, stationery and lab supplies',
      emoji: '📝',
    ),
    Goal(
      id: _uuid.v4(),
      title: 'Emergency fund (student)',
      category: 'student',
      target: 600.0,
      current: 50.0,
      deadline: t.add(const Duration(days: 365)).toIso8601String().split('T').first,
      createdAt: t,
      priority: 'medium',
      description: 'Short-term emergency buffer for unexpected expenses',
      emoji: '🛟',
    ),
  ];
}

