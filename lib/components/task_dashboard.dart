import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/database_helper.dart';
import 'calendar_page.dart';
import 'task_form.dart';

class TaskDashboard extends StatefulWidget {
  const TaskDashboard({super.key});

  @override
  State<TaskDashboard> createState() => _TaskDashboardState();
}

class _TaskDashboardState extends State<TaskDashboard>
    with SingleTickerProviderStateMixin {

  TaskPriority? _selectedPriorityFilter;

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  List<Task> tasks = [];

  final Color mainBlue = const Color(0xFF1D2E53);
  final Color accentPink = const Color(0xFFFF7BAC);
  final Color softOrange = const Color(0xFFFFA34D);
  final Color doneGreen = const Color(0xFF4BE0B0);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final db = DatabaseHelper();
    final loaded = await db.getTasks();
    setState(() => tasks = loaded);

    final urgentTasks = _getUrgentTasks(loaded);

    if (urgentTasks.isNotEmpty) {
      _animController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        _showUrgentPopup(urgentTasks);
      });
    } else {
      _animController.reset();
    }
  }

  List<Task> _getUrgentTasks(List<Task> tasks) {
    final now = DateTime.now();
    return tasks.where((t) {
      if (t.status == TaskStatus.done) return false;
      final diff = t.date.difference(now).inDays;
      return diff <= 1 && diff >= 0;
    }).toList();
  }

  /// Popup urgent
  void _showUrgentPopup(List<Task> urgentTasks) {
    final task = urgentTasks.first;
    final diff = task.date.difference(DateTime.now()).inDays;
    final label = diff == 0 ? "today" : "tomorrow";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notification_important_rounded,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 10),
                Text("Urgent Task Alert",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: mainBlue,
                        fontSize: 20)),
                const SizedBox(height: 10),
                Text(
                  "\"${task.title}\" is due $label!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description.isEmpty
                      ? "Don't forget to complete it."
                      : task.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("Got it!"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    elevation: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Update task status
  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final db = DatabaseHelper();
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      date: task.date,
      startTime: task.startTime,
      status: newStatus,
      priority: task.priority,
    );

    await db.updateTask(updatedTask);
    _loadTasks();
  }

  double _calculateProgress() {
    if (tasks.isEmpty) return 0;
    int done = tasks.where((t) => t.status == TaskStatus.done).length;
    return done / tasks.length;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ----------------------------------------
  //  DELETE POPUP
  // ----------------------------------------
  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Delete Task",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete \"${task.title}\" ?",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              final db = DatabaseHelper();
              await db.deleteTask(task.id!);
              Navigator.pop(context);
              _loadTasks();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------
  //  EDIT TASK
  // ----------------------------------------
  void _editTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskForm(
          selectedDate: task.date,
          taskToEdit: task, // IMPORTANT
          onSave: (updatedTask) async {
            final db = DatabaseHelper();

            await db.updateTask(updatedTask);
            _loadTasks();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final completed = tasks.where((t) => t.status == TaskStatus.done).length;
    final total = tasks.length;
    final percent = (progress * 100).toStringAsFixed(0);
    final urgentTasks = _getUrgentTasks(tasks);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------
            //   HEADER
            // ----------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello 👋",
                          style: TextStyle(
                            fontSize: 18,
                            color: mainBlue.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 4),
                      Text("My Tasks",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: mainBlue,
                          )),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CalendarPage(
                            selectedDate: DateTime.now(),
                            onBack: () {
                              Navigator.pop(context);
                              _loadTasks();
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainBlue,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 18),
                    label: const Text("My Calendar",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ],
              ),
            ),

            // ----------------------------------------
            //  CONTENT
            // ----------------------------------------
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (urgentTasks.isNotEmpty)
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.redAccent, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "⚠️ ${urgentTasks.length} urgent task(s) due soon!",
                                  style: TextStyle(
                                    color: mainBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showUrgentPopup(urgentTasks),
                                child: const Icon(Icons.visibility_outlined,
                                    color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // PROGRESS CIRCLE
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 130,
                                height: 130,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  color: mainBlue,
                                ),
                              ),
                              Text(
                                "$percent%",
                                style: TextStyle(
                                    color: mainBlue,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$completed of $total tasks completed",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PRIORITY FILTER
                    _priorityFilter(),
                    const SizedBox(height: 20),

                    // SECTIONS (todo / in progress / done)
                    _buildDragTargetSection("To-Do", TaskStatus.todo, mainBlue),
                    _buildDragTargetSection(
                        "In Progress", TaskStatus.inProgress, softOrange),
                    _buildDragTargetSection(
                        "Done", TaskStatus.done, doneGreen),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------
  // PRIORITY FILTER
  // ----------------------------------------
  Widget _priorityFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _filterChip("High 🔥", TaskPriority.high, Colors.redAccent),
        _filterChip("Normal ⭐", TaskPriority.normal, Colors.blueAccent),
        _filterChip("All", null, mainBlue),
      ],
    );
  }

  Widget _filterChip(String label, TaskPriority? p, Color color) {
    final selected = _selectedPriorityFilter == p;

    return GestureDetector(
      onTap: () => setState(() => _selectedPriorityFilter = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------
  // DRAG & DROP SECTIONS
  // ----------------------------------------
  Widget _buildDragTargetSection(
      String title, TaskStatus status, Color color) {

    final list = tasks.where((t) {
      final matchesStatus = t.status == status;
      final matchesPriority = _selectedPriorityFilter == null ||
          t.priority == _selectedPriorityFilter;
      return matchesStatus && matchesPriority;
    }).toList();

    return DragTarget<Task>(
      onAccept: (task) => _updateTaskStatus(task, status),
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? color.withOpacity(0.08)
                : Colors.white,
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
              Row(
                children: [
                  Icon(Icons.folder_special_outlined, color: color),
                  const SizedBox(width: 8),
                  Text(
                    "$title (${list.length})",
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "No tasks yet.",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              else
                Column(
                  children: list.map((t) {
                    return Draggable<Task>(
                      data: t,
                      feedback: Transform.scale(
                        scale: 1.08,
                        child: Material(
                          color: Colors.transparent,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                minWidth: 250, maxWidth: 300),
                            child: _taskCard(t, color, isDragging: true),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              minWidth: 250, maxWidth: 300),
                          child: _taskCard(t, color),
                        ),
                      ),
                      child: _taskCard(t, color),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------
  //   TASK CARD
  // ----------------------------------------
  Widget _taskCard(Task t, Color color, {bool isDragging = false}) {
    final isUrgent =
        t.date.difference(DateTime.now()).inDays <= 1 &&
            t.status != TaskStatus.done;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDragging ? color.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? Colors.redAccent.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: isUrgent
            ? Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 45,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    style: TextStyle(
                        color: mainBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 4),

                if (t.description.isNotEmpty)
                  Text(
                    t.description,
                    style:
                    TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
              ],
            ),
          ),

          // -------------------
          //   SMALL BUTTONS
          // -------------------
          Row(
            children: [
              // EDIT
              Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                  onPressed: () => _editTask(t),
                ),
              ),
              const SizedBox(width: 6),

              // DELETE
              Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(t),
                ),
              ),
            ],
          ),

          if (isUrgent)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 22),
            ),
        ],
      ),
    );
  }
}
