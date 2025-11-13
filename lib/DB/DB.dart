import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert'; // pour json.encode
import '../models/Notes_data.dart';

class DB {
  static Database? _db;
  static Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await openDatabase(
      join(await getDatabasesPath(), 'finance_dashboard.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, createdAt TEXT, updatedAt TEXT, categoryId INTEGER, isImportant INTEGER, isArchived INTEGER, isPinned INTEGER)',
        );
        await db.execute(
          'CREATE TABLE categoriesNote(id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT, couleurHex TEXT)',
        );
        // Création de la table goals pour les Financial Goals (stocke aussi le JSON complet en colonne data)
        await db.execute('''
          CREATE TABLE goals (
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
        await db.insert('categoriesNote', {'nom': 'Personnel', 'couleurHex': '#2196F3'});
        await db.insert('categoriesNote', {'nom': 'Travail', 'couleurHex': '#FF9800'});
        await db.insert('categoriesNote', {'nom': 'Important', 'couleurHex': '#F44336'});
        // Peupler la table goals si vide lors de la création
        await _seedGoals(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS categoriesNote(id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT, couleurHex TEXT)',
          );
          // Peupler si vide (catégories)
          final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categoriesNote')) ?? 0;
          if (count == 0) {
            await db.insert('categoriesNote', {'nom': 'Personnel', 'couleurHex': '#2196F3'});
            await db.insert('categoriesNote', {'nom': 'Travail', 'couleurHex': '#FF9800'});
            await db.insert('categoriesNote', {'nom': 'Important', 'couleurHex': '#F44336'});
          }
          // Migration: créer la table goals si elle n'existe pas
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
        }
        if (oldVersion < 3) {
          // Peupler si vide (goals)
          final countGoals = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM goals')) ?? 0;
          if (countGoals == 0) {
            await _seedGoals(db);
          }
        }
      },
    );
    print('Chemin de la base de données: ${_db!.path}');
    return _db!;
  }

  // Insère des objectifs par défaut pour la table goals si elle est vide
  static Future<void> _seedGoals(Database db) async {
    final now = DateTime.now();
    String fmt(DateTime d) => d.toIso8601String().split('T').first;
    final seeds = [
      {
        'id': 'seed_student_1',
        'title': 'Buy textbooks',
        'category': 'student',
        'target': 250.0,
        'current': 0.0,
        'deadline': fmt(now.add(const Duration(days: 30))),
        'createdAt': now.toIso8601String(),
        'priority': 'high',
        'description': 'Purchase required textbooks for the semester',
        'emoji': '\uD83D\uDCDA',
      },
      {
        'id': 'seed_student_2',
        'title': 'Laptop fund',
        'category': 'student',
        'target': 800.0,
        'current': 100.0,
        'deadline': fmt(now.add(const Duration(days: 180))),
        'createdAt': now.toIso8601String(),
        'priority': 'high',
        'description': 'Save for a new laptop for coursework',
        'emoji': '\uD83D\uDCBB',
      },
      {
        'id': 'seed_student_3',
        'title': 'Study abroad application fees',
        'category': 'student',
        'target': 500.0,
        'current': 0.0,
        'deadline': fmt(now.add(const Duration(days: 90))),
        'createdAt': now.toIso8601String(),
        'priority': 'medium',
        'description': 'Application and visa fees for exchange program',
        'emoji': '\u2708\uFE0F',
      },
      {
        'id': 'seed_student_4',
        'title': 'Course materials & supplies',
        'category': 'student',
        'target': 120.0,
        'current': 20.0,
        'deadline': fmt(now.add(const Duration(days: 45))),
        'createdAt': now.toIso8601String(),
        'priority': 'low',
        'description': 'Notebooks, stationery and lab supplies',
        'emoji': '\uD83D\uDCDD',
      },
      {
        'id': 'seed_student_5',
        'title': 'Emergency fund (student)',
        'category': 'student',
        'target': 600.0,
        'current': 50.0,
        'deadline': fmt(now.add(const Duration(days: 365))),
        'createdAt': now.toIso8601String(),
        'priority': 'medium',
        'description': 'Short-term emergency buffer for unexpected expenses',
        'emoji': '\uD83D\uDEDf',
      },
    ];

    for (final g in seeds) {
      final jsonData = json.encode({
        ...g,
        'milestones': [],
        'contributions': [],
        'isCompleted': false,
        'isArchived': false,
      });
      await db.insert(
        'goals',
        {
          'id': g['id'],
          'title': g['title'],
          'category': g['category'],
          'target': g['target'],
          'current': g['current'],
          'deadline': g['deadline'],
          'createdAt': g['createdAt'],
          'priority': g['priority'],
          'description': g['description'],
          'emoji': g['emoji'],
          'data': jsonData,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // ignore si déjà présent
      );
    }
  }


  static Future<void> addNotes(String title, String content, {int? categoryId}) async {
    final database = await db;
    await database.insert(
      'notes',
      {
        'title': title,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
        // Suppression de updatedAt initial pour distinguer ajout vs modification
        'updatedAt': null,
        'categoryId': categoryId,
        'isImportant': 0,
        'isArchived': 0,
        'isPinned': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getNotes() async {
    final database = await db;
    final notes = await database.query(
      'notes',
      orderBy: 'isPinned DESC, COALESCE(updatedAt, createdAt) DESC, createdAt DESC',
    );

    List<Map<String, dynamic>> notesWithCategories = [];
    for (var note in notes) {
      Map<String, dynamic> noteData = Map.from(note);
      if (note['categoryId'] != null) {
        final categories = await database.query(
          'categoriesNote',
          where: 'id = ?',
          whereArgs: [note['categoryId']],
        );
        if (categories.isNotEmpty) {
          noteData['category'] = categories.first;
        }
      }
      notesWithCategories.add(noteData);
    }

    return notesWithCategories;
  }

  static Future<void> updateNote(int id, {
    String? title,
    String? content,
    int? categoryId,
    bool? isImportant,
    bool? isArchived,
    bool? isPinned,
  }) async {
    final database = await db;
    Map<String, dynamic> updates = {
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;
    if (categoryId != null) updates['categoryId'] = categoryId;
    if (isImportant != null) updates['isImportant'] = isImportant ? 1 : 0;
    if (isArchived != null) updates['isArchived'] = isArchived ? 1 : 0;
    if (isPinned != null) updates['isPinned'] = isPinned ? 1 : 0;

    await database.update(
      'notes',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteNotes(int id) async {
    final database = await db;
    await database.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== FONCTIONS POUR LES CATÉGORIES ==========

  static Future<int> insertCategory(CategorieNote category) async {
    final database = await db;
    return await database.insert(
      'categoriesNote',
      {
        'nom': category.nom,
        'couleurHex': category.couleurHex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<CategorieNote>> getAllCategories() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query('categoriesNote', orderBy: 'nom ASC');
    return List.generate(maps.length, (i) {
      return CategorieNote(
        id: maps[i]['id'],
        nom: maps[i]['nom'],
        couleurHex: maps[i]['couleurHex'],
      );
    });
  }

  static Future<void> deleteCategory(int id) async {
    final database = await db;
    await database.update(
      'notes',
      {'categoryId': null},
      where: 'categoryId = ?',
      whereArgs: [id],
    );
    await database.delete(
      'categoriesNote',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateCategory(CategorieNote category) async {
    final database = await db;
    await database.update(
      'categoriesNote',
      {
        'nom': category.nom,
        'couleurHex': category.couleurHex,
      },
      where: 'id = ?'
,
      whereArgs: [category.id],
    );
  }
}