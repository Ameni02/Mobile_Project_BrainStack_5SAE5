import 'package:flutter/material.dart';
import '../../models/goal_model.dart';
import '../../models/goals_data.dart';

class AddContributionDialog extends StatefulWidget {
  final Goal goal;
  final VoidCallback onSave;

  const AddContributionDialog({
    super.key,
    required this.goal,
    required this.onSave,
  });

  @override
  State<AddContributionDialog> createState() => _AddContributionDialogState();
}

class _AddContributionDialogState extends State<AddContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Money to ${widget.goal.emoji} ${widget.goal.title}"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: "Amount (TND) *",
                prefixText: 'TND ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final raw = value?.trim() ?? '';
                if (raw.isEmpty) return "Please enter an amount";
                final parsed = double.tryParse(raw);
                if (parsed == null) return "Enter valid number";
                if (parsed <= 0) return "Amount must be positive";
                if (parsed > 100000000) return "Amount too large";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: "Note (optional)",
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.length > 120) return 'Note max 120 chars';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final transaction = GoalTransaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                amount: double.parse(_amountController.text.trim()),
                date: DateTime.now(),
                note: _noteController.text.trim(),
              );
              await GoalsData.addContribution(widget.goal.id, transaction);
              Navigator.pop(context);
              widget.onSave();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Added TND ${_amountController.text.trim()} to ${widget.goal.title}!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
          ),
          child: const Text("Add Money"),
        ),
      ],
    );
  }
}