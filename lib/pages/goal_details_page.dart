import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/goal_model.dart';
import '../models/goals_data.dart';
import '../components/FinancialGoals/add_contribution_dialog.dart';
import '../components/finance/converted_amount.dart';

class GoalDetailsPage extends StatefulWidget {
  final Goal goal;
  const GoalDetailsPage({super.key, required this.goal});

  @override
  State<GoalDetailsPage> createState() => _GoalDetailsPageState();
}

class _GoalDetailsPageState extends State<GoalDetailsPage> {
  late Goal _goal;
  final NumberFormat _moneyFormat = NumberFormat.currency(symbol: 'TND ', decimalDigits: 2);
  final String _displayCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  Future<void> _reloadGoalFromStore() async {
    await GoalsData.load();
    final updated = GoalsData.goals.firstWhere((g) => g.id == _goal.id, orElse: () => _goal);
    if (mounted) {
      setState(() => _goal = updated);
    }
  }

  Future<void> _addContribution() async {
    await showDialog(
      context: context,
      builder: (_) => AddContributionDialog(goal: _goal, onSave: () async {
        // Reload goals and refresh UI after contribution added
        await _reloadGoalFromStore();
      }),
    );
  }

  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete goal'),
        content: const Text("Are you sure you want to delete this goal? This action can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await GoalsData.deleteGoal(_goal.id);
      await GoalsData.load();
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal deleted')));
    }
  }

  Future<void> _showEditDialog() async {
    final titleCtrl = TextEditingController(text: _goal.title);
    final targetCtrl = TextEditingController(text: _goal.target.toStringAsFixed(2));
    final descCtrl = TextEditingController(text: _goal.description);
    final emojiCtrl = TextEditingController(text: _goal.emoji);
    DateTime? pickedDate = DateTime.tryParse(_goal.deadline);

    await showDialog(
      context: context,
      builder: (context) {
        String? dialogError;
        return StatefulBuilder(builder: (context, setStateDialog) {
          String? error = dialogError;
          return AlertDialog(
            title: const Text('Edit Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Target amount'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: pickedDate == null
                            ? const Text('No deadline')
                            : Text(DateFormat.yMMMd().format(pickedDate!)),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final d = await showDatePicker(
                            context: context,
                            initialDate: pickedDate ?? now,
                            firstDate: DateTime(now.year - 5),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (d != null) setStateDialog(() => pickedDate = d);
                        },
                        child: const Text('Pick date'),
                      ),
                      if (pickedDate != null)
                        IconButton(onPressed: () => setStateDialog(() => pickedDate = null), icon: const Icon(Icons.clear)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
                  const SizedBox(height: 8),
                  TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji')),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  // validate
                  final t = double.tryParse(targetCtrl.text.replaceAll(',', '.'));
                  if (titleCtrl.text.trim().isEmpty) {
                    setStateDialog(() => dialogError = 'Title is required');
                    return;
                  }
                  if (t == null || t < 0) {
                    setStateDialog(() => dialogError = 'Target must be a positive number');
                    return;
                  }

                  final updated = _goal.copyWith(
                    title: titleCtrl.text.trim(),
                    target: t,
                    description: descCtrl.text.trim(),
                    emoji: emojiCtrl.text.trim().isEmpty ? _goal.emoji : emojiCtrl.text.trim(),
                    deadline: pickedDate != null ? DateFormat('yyyy-MM-dd').format(pickedDate!) : _goal.deadline,
                  );

                  await GoalsData.updateGoal(updated);
                  await GoalsData.load();
                  if (mounted) {
                    setState(() => _goal = updated);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal updated')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _shareGoal() async {
    final summary = StringBuffer()
      ..writeln(_goal.title)
      ..writeln('Progress: ${_goal.progress.toStringAsFixed(0)}%')
      ..writeln('Saved: ${_formatCurrency(_goal.current)} / ${_formatCurrency(_goal.target)}')
      ..writeln('Remaining: ${_formatCurrency((_goal.target - _goal.current).clamp(0.0, double.infinity))}');
    await Clipboard.setData(ClipboardData(text: summary.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal summary copied to clipboard')));
  }

  String _formatCurrency(double value) => _moneyFormat.format(value);

  String get _percentageLabel => '${_goal.progress.toStringAsFixed(0)}%';

  String get _daysLabel {
    final days = _goal.daysRemaining;
    if (days == 0) return 'No time left / No deadline';
    return '$days day(s) left';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_goal.target - _goal.current).clamp(0.0, double.infinity);
    final dailyNeeded = _goal.dailySavingsNeeded();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_goal.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(_goal.title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareGoal,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteGoal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContribution,
        label: const Text('Add contribution'),
        icon: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_goal.emoji, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_goal.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Chip(label: Text(_goal.category)),
                                  Chip(label: Text(_goal.priority.toUpperCase())),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Saved', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            ConvertedAmount(amount: _goal.current, fromCurrency: 'TND', toCurrencies: ['USD','EUR'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Target', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            ConvertedAmount(amount: _goal.target, fromCurrency: 'TND', toCurrencies: ['USD','EUR'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_goal.progress / 100.0).clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF4A90E2)),
                          ),
                        )),
                        const SizedBox(width: 12),
                        Text(_percentageLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _InfoTile(label: 'Remaining', value: _formatCurrency(remaining))),
                        Expanded(child: _InfoTile(label: 'Daily needed', value: _formatCurrency(dailyNeeded))),
                        Expanded(child: _InfoTile(label: 'Deadline', value: _daysLabel)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_goal.description.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('Notes', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(_goal.description),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Contributions history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _goal.contributions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            const Text('No contributions yet', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _addContribution,
                              icon: const Icon(Icons.add),
                              label: const Text('Add first contribution'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: _goal.contributions.reversed.map((t) {
                          return ListTile(
                            leading: Icon(t.amount >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: t.amount >= 0 ? Colors.green : Colors.red),
                            title: Text('${t.amount.toStringAsFixed(2)}'),
                            subtitle: Text(DateFormat.yMMMd().format(t.date)),
                            trailing: Text(t.note, maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({Key? key, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
