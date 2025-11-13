import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:country_picker/country_picker.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/services.dart';
import '../models/task_model.dart';
import '../services/database_helper.dart';

class TaskForm extends StatefulWidget {
  final DateTime selectedDate;

  /// 🔥 Maintenant compatible avec Dashboard
  final Function(Task) onSave;

  /// Si non nul → mode édition
  final Task? taskToEdit;

  const TaskForm({
    super.key,
    required this.selectedDate,
    required this.onSave,
    this.taskToEdit,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _startTime;

  bool _isHighPriority = false;
  String? _selectedCategory;

  String _selectedCountry = "Tunisia";
  String _countryCode = "TN";

  String? _weatherCondition;
  double? _temperature;
  String? _weatherTip;

  final Color mainBlue = const Color(0xFF4A90E2);
  final Color accent = const Color(0xFF7AA2F7);
  final Color softWhite = const Color(0xFFF9FAFC);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _loadWeatherData();

    // --------------------------------
    // 🔥 MODE ÉDITION
    // --------------------------------
    if (widget.taskToEdit != null) {
      final t = widget.taskToEdit!;

      _titleController.text = t.title;
      _descriptionController.text = t.description;
      _selectedCategory = t.category;

      _date = t.date;

      if (t.startTime != null) {
        final parts = t.startTime!.split(":");
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      _isHighPriority = t.priority == TaskPriority.high;
    } else {
      // Mode création
      _date = widget.selectedDate;
    }
  }

  // -------------------------------------------------------
  // 🌤 MÉTÉO CONTEXTUELLE
  // -------------------------------------------------------
  Future<void> _loadWeatherData() async {
    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];

      if (apiKey == null) return;

      final url =
          "https://api.openweathermap.org/data/2.5/weather?q=$_selectedCountry&appid=$apiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final cond = data['weather'][0]['main'] ?? "Clear";
        final temp = data['main']['temp']?.toDouble() ?? 0.0;

        setState(() {
          _temperature = temp;
          _weatherCondition = cond;

          if (cond.contains("Rain")) {
            _weatherTip = "🌧️ It’s raining — stay productive indoors.";
          } else if (cond.contains("Clear")) {
            _weatherTip = "☀️ Perfect sunny day for motivation!";
          } else if (cond.contains("Cloud")) {
            _weatherTip = "☁️ Calm sky — ideal for focus.";
          } else if (cond.contains("Snow")) {
            _weatherTip = "❄️ Cozy vibe — perfect for creative tasks.";
          } else {
            _weatherTip = "🌤️ Balanced weather — free choice!";
          }
        });

        _animController.forward(from: 0);
      }
    } catch (e) {
      debugPrint("Weather error: $e");
    }
  }

  // -------------------------------------------------------
  // 📆 CHOIX DATE
  // -------------------------------------------------------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  // -------------------------------------------------------
  // ⏰ CHOIX HEURE
  // -------------------------------------------------------
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  // -------------------------------------------------------
  // 🔥 SAUVER / UPDATE (unifiée)
  // -------------------------------------------------------
  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    if (_date == null) {
      _showError("Choose a date first.");
      return;
    }

    final newTask = Task(
      id: widget.taskToEdit?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory ?? "General",
      date: _date!,
      status: widget.taskToEdit?.status ?? TaskStatus.todo,
      priority: _isHighPriority ? TaskPriority.high : TaskPriority.normal,
      startTime:
      _startTime == null ? null : "${_startTime!.hour}:${_startTime!.minute}",
      endTime: null,
    );

    widget.onSave(newTask); // 🔥 Retourne la tâche au Dashboard
    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // -------------------------------------------------------
  // 🖼 UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: softWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(isEditing ? "Edit Task" : "Create Task",
            style:
            TextStyle(color: mainBlue, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _weatherCard(),
              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _inputField(
                      controller: _titleController,
                      label: "Task title",
                      icon: Icons.edit,
                      validator: (v) =>
                      v == null || v.isEmpty ? "Enter a title" : null,
                    ),
                    const SizedBox(height: 20),

                    _inputField(
                      controller: _descriptionController,
                      label: "Task description",
                      icon: Icons.description,
                      validator: (v) =>
                      v == null || v.isEmpty ? "Enter a description" : null,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 25),
                    _categoryChips(),

                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _picker("Choose date", Icons.calendar_today, _pickDate),
                        _picker("Choose time", Icons.access_time, _pickTime),
                      ],
                    ),

                    const SizedBox(height: 30),
                    _priorityButton(),

                    const SizedBox(height: 35),
                    _submitButton(isEditing),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // 🎨 UI WIDGETS
  // -------------------------------------------------------
  Widget _weatherCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF1E3A8A)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CountryFlag.fromCountryCode(_countryCode,
                  height: 22, width: 32),
              const SizedBox(width: 8),
              Text(_selectedCountry,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          if (_temperature != null)
            Text(
              "${_temperature!.toStringAsFixed(1)}°C • ${_weatherCondition ?? ''}",
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          if (_weatherTip != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_weatherTip!,
                  textAlign: TextAlign.center,
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _picker(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: mainBlue),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label, style: TextStyle(color: mainBlue))),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: mainBlue),
        filled: true,
        fillColor: Colors.grey.shade100,
        hintText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    final categories = [
      "💻 Project",
      "📅 Exam",
      "🏋️ Sport",
      "🎯 Personal Goal",
      "🧠 Revision",
      "📝 Notes"
    ];

    return Wrap(
      spacing: 8,
      children: categories.map((cat) {
        final selected = cat == _selectedCategory;
        return ChoiceChip(
          label: Text(cat,
              style: TextStyle(
                  color: selected ? Colors.white : mainBlue)),
          selected: selected,
          selectedColor: mainBlue,
          onSelected: (_) => setState(() => _selectedCategory = cat),
        );
      }).toList(),
    );
  }

  Widget _priorityButton() {
    return GestureDetector(
      onTap: () => setState(() => _isHighPriority = !_isHighPriority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: _isHighPriority
                ? [Colors.redAccent, Colors.orangeAccent]
                : [mainBlue, accent],
          ),
        ),
        child: Text(
          _isHighPriority ? "🔥 High Priority" : "⭐ Normal Priority",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _submitButton(bool isEditing) {
    return ElevatedButton.icon(
      onPressed: _saveTask,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)),
      ),
      icon: Icon(
          isEditing ? Icons.edit : Icons.check_circle,
          color: Colors.white),
      label: Text(
        isEditing ? "Update Task" : "Create Task",
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
