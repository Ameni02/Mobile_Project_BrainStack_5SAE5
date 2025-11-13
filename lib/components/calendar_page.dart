import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/database_helper.dart';
import '../services/bored_service.dart';
import 'task_form.dart';

class CalendarPage extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onBack;

  const CalendarPage({
    super.key,
    required this.selectedDate,
    required this.onBack,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  List<Task> _tasks = [];
  final Color mainBlue = const Color(0xFF1D2E53);

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final db = DatabaseHelper();
    final tasks = await db.getTasks();
    if (mounted) setState(() => _tasks = tasks);
  }

  // ================================
  // 🔥 Sélection d’un jour
  // ================================
  Future<void> _onDaySelected(DateTime day) async {
    setState(() => _selectedDay = day);

    await _loadTasks();

    final tasksForDay = _tasks.where((t) =>
    t.date.year == day.year &&
        t.date.month == day.month &&
        t.date.day == day.day).toList();

    // Aucune tâche
    if (tasksForDay.isEmpty) {
      final suggestion = await BoredService().getSuggestion();
      final message = suggestion?["activity"] ??
          "You have no tasks today ✨ Enjoy your free time!";
      _showNoTaskPopup(message);
    }
  }

  // ======================
  // ✨ Popup : no tasks
  // ======================
  void _showNoTaskPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.80,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 50, color: Colors.orange),
                const SizedBox(height: 12),

                Text(
                  "No Tasks for This Day",
                  style: TextStyle(
                    fontSize: 20,
                    color: mainBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close",
                          style: TextStyle(fontSize: 15)),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskForm(
                              selectedDate: _selectedDay,
                              onSave: (task) async {
                                final db = DatabaseHelper();
                                await db.insertTask(task);
                                Navigator.pop(context);
                                _loadTasks();
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Create Task",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================
  // UI PRINCIPALE
  // ======================
  @override
  Widget build(BuildContext context) {
    final days =
    List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: mainBlue),
          onPressed: widget.onBack,
        ),
        title: Text(
          "Today",
          style: TextStyle(
            color: mainBlue,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        // -------------------
        // BUTTON ADD TASK
        // -------------------
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskForm(
                      selectedDate: _selectedDay,
                      onSave: (task) async {
                        final db = DatabaseHelper();
                        await db.insertTask(task);
                        Navigator.pop(context);
                        _loadTasks();
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainBlue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Add Task",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),

      // -----------------------
      // BODY
      // -----------------------
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "Productive Day, Nour ☀️",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ======================
          // BARRE DES 7 JOURS
          // ======================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: days.map((d) {
                final isSelected =
                    d.day == _selectedDay.day &&
                        d.month == _selectedDay.month;

                return GestureDetector(
                  onTap: () => _onDaySelected(d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? mainBlue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(d),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${d.day}",
                          style: TextStyle(
                            color:
                            isSelected ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),
          Expanded(child: _buildTimeline()),
        ],
      ),
    );
  }

  // =================================
  // TIMELINE
  // =================================
  Widget _buildTimeline() {
    final startHour = 8;
    final endHour = 22;

    final colors = [
      const Color(0xFFBEE1E6),
      const Color(0xFFFFB5A7),
      const Color(0xFFFFD6A5),
      const Color(0xFFBDE0FE),
    ];

    final tasksForDay = _tasks.where((t) =>
    t.date.year == _selectedDay.year &&
        t.date.month == _selectedDay.month &&
        t.date.day == _selectedDay.day).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: (endHour - startHour) + 1,
      itemBuilder: (context, i) {
        final hour = startHour + i;

        final timeLabel =
            "${hour > 12 ? hour - 12 : hour} ${hour >= 12 ? "PM" : "AM"}";

        final tasksAtThisHour = tasksForDay.where((t) {
          if (t.startTime == null) return false;
          final parts = t.startTime!.split(":");
          final taskHour = int.tryParse(parts[0]) ?? 0;
          return taskHour == hour;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeLabel,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),

            if (tasksAtThisHour.isEmpty)
              Container(
                height: 25,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Colors.grey.shade200, width: 1.2),
                  ),
                ),
              )
            else
              Column(
                children: tasksAtThisHour.map((t) {
                  final color = colors[Random().nextInt(colors.length)];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),

                        if (t.description.isNotEmpty)
                          Text(
                            t.description,
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 13),
                          ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              "${t.startTime ?? ""}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),

                            const Spacer(),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                t.category ?? "General",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}
