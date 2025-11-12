// Script d'utilitaire pour insérer des goals thématiques "student" dans la base.
// Usage (depuis la racine du projet):
// dart run tools/seed_student_goals.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:brain_stack/models/goal_model.dart';

String _fmtDate(DateTime dt) => dt.toIso8601String().split('T').first;

Future<void> main(List<String> args) async {
  try {
    // Initialise sqlite ffi pour pouvoir exécuter le script hors d'un runtime Flutter.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    print('Initialisation DB (sqflite ffi) ...');

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = p.join(dbPath, 'goals.db');
    print('DB path = $path');
    final db = await databaseFactory.openDatabase(path);

    // Create table if missing (schema must match GoalDbService._createDB)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT,
        target REAL NOT NULL,
        current REAL NOT NULL,
        deadline TEXT,
        createdAt TEXT,
        priority TEXT,
        description TEXT,
        emoji TEXT,
        data TEXT NOT NULL
      )
    ''');

    final now = DateTime.now();
    final sampleGoals = <Goal>[
      Goal(
        id: 'student_${now.millisecondsSinceEpoch}_1',
        title: 'Buy textbooks',
        category: 'student',
        target: 250.0,
        current: 0.0,
        deadline: _fmtDate(now.add(const Duration(days: 30))),
        createdAt: now,
        priority: 'high',
        description: 'Purchase required textbooks for the semester',
        emoji: '📚',
      ),
      Goal(
        id: 'student_${now.millisecondsSinceEpoch}_2',
        title: 'Laptop fund',
        category: 'student',
        target: 800.0,
        current: 100.0,
        deadline: _fmtDate(now.add(const Duration(days: 180))),
        createdAt: now,
        priority: 'high',
        description: 'Save for a new laptop for coursework',
        emoji: '💻',
      ),
      Goal(
        id: 'student_${now.millisecondsSinceEpoch}_3',
        title: 'Study abroad application fees',
        category: 'student',
        target: 500.0,
        current: 0.0,
        deadline: _fmtDate(now.add(const Duration(days: 90))),
        createdAt: now,
        priority: 'medium',
        description: 'Application and visa fees for exchange program',
        emoji: '✈️',
      ),
      Goal(
        id: 'student_${now.millisecondsSinceEpoch}_4',
        title: 'Course materials & supplies',
        category: 'student',
        target: 120.0,
        current: 20.0,
        deadline: _fmtDate(now.add(const Duration(days: 45))),
        createdAt: now,
        priority: 'low',
        description: 'Notebooks, stationery and lab supplies',
        emoji: '📝',
      ),
      Goal(
        id: 'student_${now.millisecondsSinceEpoch}_5',
        title: 'Emergency fund (student)',
        category: 'student',
        target: 600.0,
        current: 50.0,
        deadline: _fmtDate(now.add(const Duration(days: 365))),
        createdAt: now,
        priority: 'medium',
        description: 'Short-term emergency buffer for unexpected expenses',
        emoji: '🛟',
      ),
    ];

    print('Ajout de ${sampleGoals.length} goals...');
    var added = 0;
    for (final g in sampleGoals) {
      final existing = await db.query('goals', where: 'id = ?', whereArgs: [g.id]);
      if (existing.isEmpty) {
        final map = g.toMap();
        await db.insert(
          'goals',
          {
            'id': g.id,
            'title': g.title,
            'category': g.category,
            'target': g.target,
            'current': g.current,
            'deadline': g.deadline,
            'createdAt': g.createdAt.toIso8601String(),
            'priority': g.priority,
            'description': g.description,
            'emoji': g.emoji,
            'data': json.encode(map),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        added++;
        print('  - ajouté: ${g.title} (id=${g.id})');
      } else {
        print('  - ignoré (existe): ${g.title} (id=${g.id})');
      }
    }

    final total = await db.rawQuery('SELECT COUNT(*) as c FROM goals');
    final totalCount = (total.first['c'] as int?) ?? 0;
    print('\nOpération terminée. Total goals en base: $totalCount (ajoutés: $added)');

    await db.close();
  } catch (e, s) {
    print('Erreur lors du seed: $e');
    print(s);
    exit(2);
  }
}
