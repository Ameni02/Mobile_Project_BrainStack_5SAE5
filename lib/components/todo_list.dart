import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_helper.dart'; // ✅ on remplace LocalStorageService
import 'task_dashboard.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  List<Task> tasks = [];
  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  /// Charger toutes les tâches depuis SQLite
  Future<void> _loadTasks() async {
    final loaded = await db.getTasks();
    if (mounted) setState(() => tasks = loaded);
  }

  /// Ajouter une tâche (insérée dans la base)
  Future<void> _addTask(Task newTask) async {
    await db.insertTask(newTask);
    _loadTasks(); // recharger après ajout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: TaskDashboard(), // ✅ TaskDashboard charge déjà ses données SQLite
    );
  }
}
