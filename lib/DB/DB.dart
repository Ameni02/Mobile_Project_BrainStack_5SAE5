import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/Notes_data.dart';

class DB {
  static Database? _db;
  static Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await openDatabase(
      join(await getDatabasesPath(), 'finance_dashboard.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, createdAt TEXT, updatedAt TEXT, categoryId INTEGER, isImportant INTEGER, isArchived INTEGER, isPinned INTEGER)',
        );
        await db.execute(
          'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT, couleurHex TEXT)',
        );
        await db.insert('categories', {'nom': 'Personnel', 'couleurHex': '#2196F3'});
        await db.insert('categories', {'nom': 'Travail', 'couleurHex': '#FF9800'});
        await db.insert('categories', {'nom': 'Important', 'couleurHex': '#F44336'});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS categories(id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT, couleurHex TEXT)',
          );
          await db.insert('categories', {'nom': 'Personnel', 'couleurHex': '#2196F3'});
          await db.insert('categories', {'nom': 'Travail', 'couleurHex': '#FF9800'});
          await db.insert('categories', {'nom': 'Important', 'couleurHex': '#F44336'});
        }
      },
    );
    print('Chemin de la base de données: ${_db!.path}');
    return _db!;
  }


  static Future<void> addNotes(String title, String content, {int? categoryId}) async {
    final database = await db;
    await database.insert(
      'notes',
      {
        'title': title,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
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
    final notes = await database.query('notes', orderBy: 'createdAt DESC');

    List<Map<String, dynamic>> notesWithCategories = [];
    for (var note in notes) {
      Map<String, dynamic> noteData = Map.from(note);
      if (note['categoryId'] != null) {
        final categories = await database.query(
          'categories',
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
      'categories',
      {
        'nom': category.nom,
        'couleurHex': category.couleurHex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<CategorieNote>> getAllCategories() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query('categories', orderBy: 'nom ASC');

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
    // Supprimer la catégorie
    await database.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateCategory(CategorieNote category) async {
    final database = await db;
    await database.update(
      'categories',
      {
        'nom': category.nom,
        'couleurHex': category.couleurHex,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }
}