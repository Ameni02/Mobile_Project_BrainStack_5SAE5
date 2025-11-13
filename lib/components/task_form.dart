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
  final Task? taskToEdit; // ✅ si non nul, on est en mode édition

  const TaskForm({
    super.key,
    required this.selectedDate,
    this.taskToEdit,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> with SingleTickerProviderStateMixin {
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

  final Color mainBlue = const Color(0xFF1D2E53);
  final Color accent = const Color(0xFF7AA2F7);
  final Color softWhite = const Color(0xFFF9FAFC);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadWeatherData();

    // ✅ Pré-remplir si édition
    if (widget.taskToEdit != null) {
      final t = widget.taskToEdit!;
      _titleController.text = t.title;
      _descriptionController.text = t.description;
      _selectedCategory = t.category;
      _date = t.date;
      if (t.startTime != null) {
        final parts = t.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  // 🌦️ MÉTÉO CONTEXTUELLE
  Future<void> _loadWeatherData() async {
    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      final url =
          "https://api.openweathermap.org/data/2.5/weather?q=$_selectedCountry&appid=$apiKey&units=metric";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final condition = data['weather'][0]['main'] ?? "Clear";
        final temp = data['main']['temp']?.toDouble() ?? 0.0;

        setState(() {
          _temperature = temp;
          _weatherCondition = condition;

          if (condition.contains("Rain")) {
            _weatherTip = "🌧️ It’s raining — try planning an indoor task today.";
          } else if (condition.contains("Clear")) {
            _weatherTip = "☀️ Perfect sunny day — go outside and accomplish your goals!";
          } else if (condition.contains("Cloud")) {
            _weatherTip = "☁️ Cloudy sky — calm moment for planning or focus work.";
          } else if (condition.contains("Snow")) {
            _weatherTip = "❄️ Cozy day — warm tasks like reading or coding at home.";
          } else if (condition.contains("Thunderstorm")) {
            _weatherTip = "⛈️ Stay safe — great time for online or indoor projects.";
          } else if (condition.contains("Mist") || condition.contains("Fog")) {
            _weatherTip = "🌫️ Misty weather — ideal for reflection or organization.";
          } else {
            _weatherTip = "🌤️ Balanced weather — free choice for your next task.";
          }
        });

        _animController.forward(from: 0);
      }
    } catch (e) {
      debugPrint("Weather load error: $e");
    }
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (country) {
        setState(() {
          _selectedCountry = country.name;
          _countryCode = country.countryCode;
        });
        _loadWeatherData();
      },
    );
  }

  // 🧩 VALIDATION DES CHAMPS
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) return "Please enter a title.";
    if (value.length < 3) return "Too short — minimum 3 letters.";
    if (value.length > 30) return "Too long — max 30 letters.";
    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value)) {
      return "Invalid characters — letters only please.";
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) return "Please describe your task briefly.";
    if (value.length < 5) return "Description too short.";
    if (value.length > 200) return "Too long — max 200 characters.";
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: mainBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: mainBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  // 💾 SAUVEGARDE / MISE À JOUR
  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      if (_date == null) {
        _showError("Please choose a date first.");
        return;
      }

      final db = DatabaseHelper();

      if (widget.taskToEdit != null) {
        // 🔄 Mise à jour
        final updatedTask = Task(
          id: widget.taskToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory ?? "General",
          date: _date!,
          startTime: "${_startTime?.hour ?? 0}:${_startTime?.minute ?? 0}",
          endTime: "${(_startTime?.hour ?? 0) + 1}:${_startTime?.minute ?? 0}",
          status: widget.taskToEdit!.status,
        );
        await db.updateTask(updatedTask);
        HapticFeedback.mediumImpact();
        _showSuccessPopup(isUpdate: true);
      } else {
        // ➕ Création
        final newTask = Task(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory ?? "General",
          date: _date!,
          startTime: "${_startTime?.hour ?? 0}:${_startTime?.minute ?? 0}",
          endTime: "${(_startTime?.hour ?? 0) + 1}:${_startTime?.minute ?? 0}",
          status: TaskStatus.todo,
        );
        await db.insertTask(newTask);
        HapticFeedback.mediumImpact();
        _showSuccessPopup(isUpdate: false);
      }
    }
  }

  // ✅ POPUP DE SUCCÈS
  void _showSuccessPopup({bool isUpdate = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUpdate ? Icons.edit_rounded : Icons.check_circle,
                    color: isUpdate ? Colors.orangeAccent : Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isUpdate
                        ? "Task Updated Successfully!"
                        : "Task Created Successfully!",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text("Continue",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // 🧱 UI BUILD
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;
    return Scaffold(
      backgroundColor: softWhite,
      appBar: AppBar(
        title: Text(isEditing ? "Edit Task" : "Create Task"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: mainBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeatherCard(),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputField(
                      controller: _titleController,
                      label: "Task title",
                      icon: Icons.edit,
                      validator: _validateTitle,
                    ),
                    const SizedBox(height: 20),
                    _inputField(
                      controller: _descriptionController,
                      label: "Task description",
                      icon: Icons.description_outlined,
                      validator: _validateDescription,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 25),
                    Text("Category",
                        style: TextStyle(
                            color: mainBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        "💻 Project",
                        "📅 Exam",
                        "🏋️ Sport",
                        "🎯 Personal Goal",
                        "🧠 Revision",
                        "📝 Notes"
                      ].map((cat) {
                        final selected = cat == _selectedCategory;
                        return ChoiceChip(
                          label: Text(cat,
                              style: TextStyle(
                                  color: selected ? Colors.white : mainBlue)),
                          selected: selected,
                          selectedColor: mainBlue,
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _pickerButton(
                            "Choose date", Icons.calendar_today, _pickDate),
                        _pickerButton(
                            "Choose time", Icons.access_time, _pickTime),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildPriorityButton(),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.center,
                      child: _buildCreateButton(isEditing),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 WIDGETS DESIGN

  Widget _buildWeatherCard() {
    final gradientColors = _weatherCondition == "Rain"
        ? [const Color(0xFF1E293B), const Color(0xFF334155)]
        : [const Color(0xFF0F172A), const Color(0xFF1E3A8A)];

    return GestureDetector(
      onTap: _pickCountry,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CountryFlag.fromCountryCode(_countryCode, height: 22, width: 32),
              const SizedBox(width: 8),
              Text(_selectedCountry,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white),
            ]),
            const SizedBox(height: 10),
            if (_temperature != null)
              Text("${_temperature!.toStringAsFixed(1)}°C • ${_weatherCondition ?? ''}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18))
            else
              const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            if (_weatherTip != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _weatherTip!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pickerButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(children: [
          Icon(icon, color: mainBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: mainBlue))),
        ]),
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
        hintText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPriorityButton() {
    return GestureDetector(
      onTap: () => setState(() => _isHighPriority = !_isHighPriority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHighPriority
                ? [Colors.redAccent, Colors.orangeAccent]
                : [mainBlue, accent],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _isHighPriority ? "🔥 High Priority" : "⭐ Normal Priority",
          style:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isEditing) {
    return ElevatedButton.icon(
      onPressed: _saveTask,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 6,
        shadowColor: Colors.black26,
      ),
      icon: Icon(
        isEditing ? Icons.edit : Icons.check_circle_outline,
        color: Colors.white,
      ),
      label: Text(
        isEditing ? "Update Task" : "Create Task",
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
