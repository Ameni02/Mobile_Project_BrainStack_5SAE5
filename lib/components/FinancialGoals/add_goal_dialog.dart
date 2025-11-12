import 'package:flutter/material.dart';
import '../../services/secure_storage_service.dart';
import 'package:flutter/services.dart';
import '../../models/goal_model.dart';
import '../../services/huggingface_service.dart';

class AddGoalDialog extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Function(Goal) onSave;
  final Goal? initial;

  const AddGoalDialog({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onSave,
    this.initial,
  });

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isGeneratingSmartGoal = false;

  String _selectedCategory = 'Electronics';
  String _selectedPriority = 'medium';
  String _selectedEmoji = '🎯';
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));

  final List<String> _categories = [
    'Electronics',
    'Travel',
    'Savings',
    'Health',
    'Education',
    'Entertainment',
    'Other'
  ];

  final List<String> _priorities = ['low', 'medium', 'high'];

  final List<String> _emojis = [
    '🎯', '💻', '✈️', '🏠', '🚗', '💰',
    '📱', '🎓', '💪', '🎮', '📚', '🛡️'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs si un goal initial est fourni (édition)
    if (widget.initial != null) {
      final g = widget.initial!;
      _titleController.text = g.title;
      _targetController.text = g.target.toStringAsFixed(0);
      _descriptionController.text = g.description;
      _selectedCategory = g.category;
      _selectedPriority = g.priority;
      _selectedEmoji = g.emoji;
      try {
        final parts = g.deadline.split('-');
        if (parts.length == 3) {
          final y = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final d = int.parse(parts[2]);
          _selectedDeadline = DateTime(y, m, d);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 500),
          // Remplaced the inner white Container with Material to ensure
          // TextField has a Material ancestor (fixes "No Material widget found").
          child: Material(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Create New Goal",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Emoji Selector
                      const Text(
                        "Choose an emoji",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _emojis.map((emoji) => InkWell(
                          onTap: () => setState(() => _selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedEmoji == emoji
                                    ? const Color(0xFF4A90E2)
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Goal Title *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? "Please enter a title" : null,
                      ),
                      const SizedBox(height: 16),

                      // Category
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: "Category *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value ?? _selectedCategory),
                      ),
                      const SizedBox(height: 16),

                      // Target Amount
                      TextFormField(
                        controller: _targetController,
                        decoration: const InputDecoration(
                          labelText: "Target Amount *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return "Please enter an amount";
                          if (double.tryParse(value) == null) return "Enter valid number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Priority
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: "Priority *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.priority_high),
                        ),
                        items: _priorities.map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority.toUpperCase()),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedPriority = value ?? _selectedPriority),
                      ),
                      const SizedBox(height: 16),

                      // Deadline
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDeadline,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) {
                            setState(() => _selectedDeadline = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Deadline *",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            "${_selectedDeadline.year}-${_selectedDeadline.month.toString().padLeft(2, '0')}-${_selectedDeadline.day.toString().padLeft(2, '0')}",
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: "Description (optional)",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: _isGeneratingSmartGoal
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : IconButton(
                                    tooltip: 'Reformuler en SMART',
                                    icon: const Icon(Icons.auto_fix_high),
                                    onPressed: () async {
                                      // Use title if description empty
                                      final input = _descriptionController.text.trim().isEmpty ? _titleController.text.trim() : _descriptionController.text.trim();
                                      if (input.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title or description first')));
                                        return;
                                      }

                                      setState(() => _isGeneratingSmartGoal = true);
                                      try {
                                        final storage = SecureStorageService();
                                        String? apiKey = await storage.readHfKey();
                                        if (apiKey == null || apiKey.isEmpty) {
                                          // Ask for API key
                                          final keys = await showDialog<String?>(
                                            context: context,
                                            builder: (ctx) {
                                              final kCtrl = TextEditingController();
                                              return AlertDialog(
                                                title: const Text('Hugging Face API Key'),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text('Enter your Hugging Face Inference API key (hf_...)'),
                                                    TextField(controller: kCtrl, decoration: const InputDecoration(labelText: 'API Key')),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
                                                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(kCtrl.text), child: const Text('Save')),
                                                ],
                                              );
                                            },
                                          );
                                          if (keys != null && keys.isNotEmpty) {
                                            apiKey = keys;
                                            await storage.writeHfKey(apiKey);
                                          }
                                        }

                                        if (apiKey == null || apiKey.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hugging Face API key not provided.')));
                                        } else {
                                          final svc = HuggingFaceService();
                                          svc.setApiKey(apiKey);
                                          final generated = await svc.generateSmartGoal(input);
                                          svc.dispose();
                                          if (generated.isNotEmpty) {
                                            // Post-process: keep single-line and ensure prefix
                                            var out = generated.trim().replaceAll('\n', ' ');
                                            if (!out.startsWith('SMART Goal')) {
                                              out = 'SMART Goal: ' + out;
                                            }
                                            _descriptionController.text = out;
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMART goal generated.')));
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No output from model')));
                                          }
                                        }
                                      } catch (e, st) {
                                        // Log to console for debugging
                                        // ignore: avoid_print
                                        print('Hugging Face generation error: $e');
                                        // ignore: avoid_print
                                        print(st);

                                        // Prepare a short snippet of the stack trace (avoid huge dialogs)
                                        final stStr = st.toString();
                                        final snippet = stStr.length > 1000 ? stStr.substring(0, 1000) : stStr;

                                        // Show a dialog with the full error so user/dev can inspect it
                                        await showDialog<void>(
                                          context: context,
                                          builder: (ctx) {
                                            return AlertDialog(
                                              title: const Text('Generation failed'),
                                              content: SingleChildScrollView(
                                                child: Text('$e\n\n$snippet'),
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                                              ],
                                            );
                                          },
                                        );

                                        // also show a brief snackbar
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generation failed: ${e.toString()}')));
                                      } finally {
                                        setState(() => _isGeneratingSmartGoal = false);
                                      }
                                    },
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onClose,
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final isEdit = widget.initial != null;
                                  final id = isEdit ? widget.initial!.id : DateTime.now().millisecondsSinceEpoch.toString();
                                  final createdAt = isEdit ? widget.initial!.createdAt : DateTime.now();
                                  final existingContributions = isEdit ? widget.initial!.contributions : <GoalTransaction>[];
                                  final existingMilestones = isEdit ? widget.initial!.milestones : <Milestone>[];

                                  final newGoal = Goal(
                                    id: id,
                                    title: _titleController.text,
                                    category: _selectedCategory,
                                    target: double.parse(_targetController.text),
                                    current: isEdit ? widget.initial!.current : 0,
                                    deadline: "${_selectedDeadline.year}-${_selectedDeadline.month.toString().padLeft(2, '0')}-${_selectedDeadline.day.toString().padLeft(2, '0')}",
                                    createdAt: createdAt,
                                    priority: _selectedPriority,
                                    description: _descriptionController.text,
                                    emoji: _selectedEmoji,
                                    contributions: existingContributions,
                                    milestones: existingMilestones,
                                    isCompleted: isEdit ? widget.initial!.isCompleted : false,
                                    isArchived: isEdit ? widget.initial!.isArchived : false,
                                  );
                                  widget.onSave(newGoal);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isEdit ? "Goal updated" : "Goal created successfully!")),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(widget.initial != null ? "Save Changes" : "Create Goal"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
