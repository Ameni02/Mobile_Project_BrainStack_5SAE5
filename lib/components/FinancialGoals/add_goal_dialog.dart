import 'package:flutter/material.dart';
import '../../models/goal_model.dart';

class AddGoalDialog extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Function(Goal) onSave;
  final Goal? initial;
  const AddGoalDialog({super.key, required this.isOpen, required this.onClose, required this.onSave, this.initial});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _category = 'Electronics';
  String _priority = 'medium';
  String _emoji = '🎯';
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));

  final _categories = const ['Electronics','Travel','Savings','Health','Education','Entertainment','Other'];
  final _priorities = const ['low','medium','high'];
  final _emojis = const ['🎯','💻','✈️','🏠','🚗','💰','📱','🎓','💪','🎮','📚','🛡️'];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final g = widget.initial!;
      _titleCtrl.text = g.title;
      _targetCtrl.text = g.target.toString();
      _descCtrl.text = g.description;
      _category = g.category;
      _priority = g.priority;
      _emoji = g.emoji;
      try { _deadline = DateTime.parse(g.deadline); } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final min = DateTime(now.year, now.month, now.day);
    final init = _deadline.isBefore(min) ? min : _deadline;
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: min,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final today = DateTime.now();
    final min = DateTime(today.year, today.month, today.day);
    if (_deadline.isBefore(min)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deadline must be today or later')));
      return;
    }
    final edit = widget.initial != null;
    final id = edit ? widget.initial!.id : DateTime.now().millisecondsSinceEpoch.toString();
    final goal = Goal(
      id: id,
      title: _titleCtrl.text.trim(),
      category: _category,
      target: double.parse(_targetCtrl.text.trim()),
      current: edit ? widget.initial!.current : 0,
      deadline: "${_deadline.year}-${_deadline.month.toString().padLeft(2,'0')}-${_deadline.day.toString().padLeft(2,'0')}",
      createdAt: edit ? widget.initial!.createdAt : DateTime.now(),
      priority: _priority,
      description: _descCtrl.text.trim(),
      emoji: _emoji,
      contributions: edit ? widget.initial!.contributions : const [],
      milestones: edit ? widget.initial!.milestones : const [],
      isCompleted: edit ? widget.initial!.isCompleted : false,
      isArchived: edit ? widget.initial!.isArchived : false,
    );
    await widget.onSave(goal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(editTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Choose an emoji', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _emojis.map((e) => InkWell(
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: _emoji == e ? const Color(0xFF4A90E2) : Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                  validator: (v){
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Please enter a title';
                    if (s.length < 3) return 'Title too short';
                    if (s.length > 60) return 'Title max 60 chars';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(()=> _category = v ?? _category),
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v){
                    final raw = v?.trim() ?? '';
                    if (raw.isEmpty) return 'Please enter an amount';
                    final d = double.tryParse(raw);
                    if (d == null) return 'Enter valid number';
                    if (d <= 0) return 'Amount must be > 0';
                    if (d > 100000000) return 'Amount too large';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _priority,
                  items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                  onChanged: (v) => setState(()=> _priority = v ?? _priority),
                  decoration: const InputDecoration(
                    labelText: 'Priority *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDeadline,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Deadline *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text("${_deadline.year}-${_deadline.month.toString().padLeft(2,'0')}-${_deadline.day.toString().padLeft(2,'0')}"),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (v){
                    final s = v?.trim() ?? '';
                    if (s.length > 300) return 'Description max 300 chars';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onClose,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(widget.initial == null ? 'Create Goal' : 'Save Changes'),
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

  String get editTitle => widget.initial == null ? 'Create New Goal' : 'Edit Goal';
}
