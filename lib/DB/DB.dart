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
      version: 6,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, createdAt TEXT, updatedAt TEXT, categoryId INTEGER, isImportant INTEGER, isArchived INTEGER, isPinned INTEGER)',
        );
        await db.execute(
          'CREATE TABLE categoriesNote(id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT, couleurHex TEXT)',
        );
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
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            category TEXT,
            date TEXT,
            startTime TEXT,
            endTime TEXT,
            status TEXT,
            priority TEXT
          )
        ''');
        // Nouvelle table transactions
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY,
            name TEXT,
            category TEXT,
            date TEXT,
            amount REAL,
            icon INTEGER,
            color TEXT,
            type TEXT,
            extraFields TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            fullName TEXT,
            role TEXT,
            createdAt TEXT
          )
        ''');
        // Seed des catégories notes
        await db.insert('categoriesNote', {'nom': 'Personal', 'couleurHex': '#2196F3'});
        await db.insert('categoriesNote', {'nom': 'Work', 'couleurHex': '#FF9800'});
        await db.insert('categoriesNote', {'nom': 'Important', 'couleurHex': '#F44336'});
        // Seed goals
        await _seedGoals(db);

        try {
          await db.insert('users', {
            'username': 'Ghassen',
            'password': 'admin123*',
            'fullName': 'Ghassen Ben Aissa',
            'role': 'admin',
            'createdAt': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        } catch (_) {}
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS categoriesNote(id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT, couleurHex TEXT)',
          );
          final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categoriesNote')) ?? 0;
          if (count == 0) {
            await db.insert('categoriesNote', {'nom': 'Personal', 'couleurHex': '#2196F3'});
            await db.insert('categoriesNote', {'nom': 'Work', 'couleurHex': '#FF9800'});
            await db.insert('categoriesNote', {'nom': 'Important', 'couleurHex': '#F44336'});
          }
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
          final countGoals = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM goals')) ?? 0;
          if (countGoals == 0) {
            await _seedGoals(db);
          }
        }
        if (oldVersion < 4) {
          // Création de la table tasks si elle n'existe pas
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tasks(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              description TEXT,
              category TEXT,
              date TEXT,
              startTime TEXT,
              endTime TEXT,
              status TEXT,
              priority TEXT
            )
          ''');
          // Vérifier présence de la colonne priority (pour anciennes installations de tasks sans priority)
          final columns = await db.rawQuery("PRAGMA table_info(tasks)");
          final hasPriority = columns.any((c) => c['name'] == 'priority');
          if (!hasPriority) {
            try {
              await db.execute("ALTER TABLE tasks ADD COLUMN priority TEXT DEFAULT 'normal'");
            } catch (_) {}
          }
        }
        if (oldVersion < 5) {
          // Ajout table transactions
          await db.execute('''
              CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY,
                name TEXT,
                category TEXT,
                date TEXT,
                amount REAL,
                icon INTEGER,
                color TEXT,
                type TEXT,
                extraFields TEXT
              )
            ''');
        }
        if (oldVersion < 6) {
          // Ajout table users
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT UNIQUE,
              password TEXT,
              fullName TEXT,
              role TEXT,
              createdAt TEXT
            )
          ''');
          // Seed default user if none exists
          final countUsers = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
          if (countUsers == 0) {
            try {
              await db.insert('users', {
                'username': 'Ghassen',
                'password': 'admin123*',
                'fullName': 'Ghassen Ben Aissa',
                'role': 'admin',
                'createdAt': DateTime.now().toIso8601String(),
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            } catch (_) {}
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
        'current': 150.0,
        'deadline': fmt(now.add(const Duration(days: 45))),
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
        'priority': 'high',
        'description': 'Purchase required textbooks for the semester',
        'emoji': '\uD83D\uDCDA',
        'contributions': [
          {'id': 'c_bt_1', 'amount': 100.0, 'date': now.subtract(const Duration(days: 2)).toIso8601String(), 'note': 'Initial deposit'},
          {'id': 'c_bt_2', 'amount': 50.0, 'date': now.subtract(const Duration(days: 1)).toIso8601String(), 'note': 'Part-time job'},
        ],
      },
      {
        'id': 'seed_student_2',
        'title': 'Laptop fund',
        'category': 'student',
        'target': 800.0,
        'current': 300.0,
        'deadline': fmt(now.add(const Duration(days: 200))),
        'createdAt': now.subtract(const Duration(days: 10)).toIso8601String(),
        'priority': 'high',
        'description': 'Save for a new laptop for coursework',
        'emoji': '\uD83D\uDCBB',
        'contributions': [
          {'id': 'c_lf_1', 'amount': 100.0, 'date': now.subtract(const Duration(days: 9)).toIso8601String(), 'note': 'First saving'},
          {'id': 'c_lf_2', 'amount': 200.0, 'date': now.subtract(const Duration(days: 4)).toIso8601String(), 'note': 'Scholarship part'},
        ],
      },
      {
        'id': 'seed_student_3',
        'title': 'Study abroad application fees',
        'category': 'student',
        'target': 500.0,
        'current': 250.0,
        'deadline': fmt(now.add(const Duration(days: 100))),
        'createdAt': now.subtract(const Duration(days: 6)).toIso8601String(),
        'priority': 'medium',
        'description': 'Application and visa fees for exchange program',
        'emoji': '\u2708\uFE0F',
        'contributions': [
          {'id': 'c_sa_1', 'amount': 250.0, 'date': now.subtract(const Duration(days: 5)).toIso8601String(), 'note': 'Parents support'},
        ],
      },
      {
        'id': 'seed_student_4',
        'title': 'Course materials & supplies',
        'category': 'student',
        'target': 120.0,
        'current': 120.0,
        'deadline': fmt(now.add(const Duration(days: 50))),
        'createdAt': now.subtract(const Duration(days: 15)).toIso8601String(),
        'priority': 'low',
        'description': 'Notebooks, stationery and lab supplies',
        'emoji': '\uD83D\uDCDD',
        'contributions': [
          {'id': 'c_cm_1', 'amount': 20.0, 'date': now.subtract(const Duration(days: 14)).toIso8601String(), 'note': 'First'},
          {'id': 'c_cm_2', 'amount': 100.0, 'date': now.subtract(const Duration(days: 7)).toIso8601String(), 'note': 'Allowance'},
        ],
        'isCompleted': true,
      },
      {
        'id': 'seed_student_5',
        'title': 'Emergency fund (student)',
        'category': 'student',
        'target': 600.0,
        'current': 610.0,
        'deadline': fmt(now.add(const Duration(days: 370))),
        'createdAt': now.subtract(const Duration(days: 60)).toIso8601String(),
        'priority': 'medium',
        'description': 'Short-term emergency buffer for unexpected expenses',
        'emoji': '\uD83D\uDEDf',
        'contributions': [
          {'id': 'c_ef_1', 'amount': 300.0, 'date': now.subtract(const Duration(days: 55)).toIso8601String(), 'note': 'Initial'},
          {'id': 'c_ef_2', 'amount': 310.0, 'date': now.subtract(const Duration(days: 20)).toIso8601String(), 'note': 'Savings push'},
        ],
        'isCompleted': true,
      },
    ];

    for (final g in seeds) {
      final jsonData = json.encode({
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
        'milestones': [],
        'contributions': g['contributions'] ?? [],
        'isCompleted': g['isCompleted'] ?? false,
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
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ========== USER HELPERS ==========
  static Future<int> addUser(String username, String password, {String? fullName, String? role}) async {
    final database = await db;
    return await database.insert(
      'users',
      {
        'username': username,
        'password': password,
        'fullName': fullName,
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final database = await db;
    final users = await database.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (users.isNotEmpty) return users.first;
    return null;
  }

  static Future<bool> validateUser(String username, String password) async {
    final user = await getUserByUsername(username);
    if (user == null) return false;
    return user['password'] == password;
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