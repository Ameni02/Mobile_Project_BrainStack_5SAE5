import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../DB/DB.dart'; // utilisation de la base unique

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Plus de base séparée, on réutilise DB.db
  Future<Database> get database async => await DB.db;

  // Méthodes CRUD sur tasks restent identiques
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
  }
}
