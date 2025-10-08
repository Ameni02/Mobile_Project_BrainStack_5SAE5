import 'package:flutter/material.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final List<Todo> _todos = [
    Todo(id: 1, text: "Review monthly budget", completed: false),
    Todo(id: 2, text: "Pay credit card bill", completed: true),
    Todo(id: 3, text: "Update investment portfolio", completed: false),
    Todo(id: 4, text: "Set up automatic savings", completed: false),
  ];

  final _newTodoController = TextEditingController();

  @override
  void dispose() {
    _newTodoController.dispose();
    super.dispose();
  }

  void _addTodo() {
    if (_newTodoController.text.trim().isNotEmpty) {
      setState(() {
        _todos.add(Todo(
          id: DateTime.now().millisecondsSinceEpoch,
          text: _newTodoController.text.trim(),
          completed: false,
        ));
        _newTodoController.clear();
      });
    }
  }

  void _toggleTodo(int id) {
    setState(() {
      _todos.forEach((todo) {
        if (todo.id == id) {
          todo.completed = !todo.completed;
        }
      });
    });
  }

  void _deleteTodo(int id) {
    setState(() {
      _todos.removeWhere((todo) => todo.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add Todo Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newTodoController,
                decoration: const InputDecoration(
                  hintText: "Add a new task...",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _addTodo(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTodo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Todo List
        if (_todos.isNotEmpty)
          ..._todos.map((todo) => _buildTodoItem(todo))
        else
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "No tasks yet. Add one to get started!",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTodoItem(Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: todo.completed,
              onChanged: (_) => _toggleTodo(todo.id),
              activeColor: const Color(0xFF4A90E2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo.text,
                style: TextStyle(
                  fontSize: 16,
                  color: todo.completed ? const Color(0xFF6B7280) : const Color(0xFF1A1A1A),
                  decoration: todo.completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _deleteTodo(todo.id),
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFFE53E3E),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Todo {
  final int id;
  final String text;
  bool completed;

  Todo({
    required this.id,
    required this.text,
    required this.completed,
  });
}
