import 'package:flutter/material.dart';
import '../models/transaction_data.dart';
import '../models/profile_data.dart';
import '../theme/app_colors.dart';

class ExpenseChatbot extends StatefulWidget {
  final bool inline;

  const ExpenseChatbot({super.key, this.inline = false});

  @override
  State<ExpenseChatbot> createState() => _ExpenseChatbotState();
}

class _ExpenseChatbotState extends State<ExpenseChatbot> {
  final _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.insert(0, {'text': text.trim(), 'isUser': true});
    });
    _controller.clear();

    Future.delayed(const Duration(milliseconds: 250), () {
      () async {
        final reply = await _getReply(text.toLowerCase());
        setState(() {
          _messages.insert(0, {'text': reply, 'isUser': false});
        });
      }();
    });
  }

  Future<String> _getReply(String input) async {
    final lower = input.toLowerCase();

    // Try to load local transactions (no-op if already loaded)
    try {
      await TransactionData.loadTransactions();
    } catch (_) {
      // ignore DB errors and fall back to generic responses
    }

    // Totals queries
    if (lower.contains('total expense') ||
        lower.contains('total expenses') ||
        lower.contains('total spent') ||
        lower.contains('how much have i spent') ||
        lower.contains('how much did i spend')) {
      final total = TransactionData.totalExpenses;
      return 'Your total expenses are \$${total.toStringAsFixed(2)}.';
    }

    if (lower.contains('total income') ||
        lower.contains('total revenue') ||
        lower.contains('how much did i earn') ||
        lower.contains('income total')) {
      final rev = TransactionData.totalRevenue;
      return 'Your total income is \$${rev.toStringAsFixed(2)}.';
    }

    // Helper to match category tokens (matches partial words like "food" in "Food & Drink")
    bool _categoryMatches(String category, String query) {
      final tokens = category.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty);
      for (var t in tokens) {
        if (query.contains(t)) return true;
      }
      return false;
    }

    // Check expense categories mentioned in query
    final categories = TransactionData.expenseTransactions.map((t) => t.category).toSet().toList();
    final matched = <String>[];
    for (var cat in categories) {
      if (_categoryMatches(cat, lower)) matched.add(cat);
    }

    if (matched.isNotEmpty) {
      if (lower.contains('compare') && matched.length >= 2) {
        final a = matched[0];
        final b = matched[1];
        final sumA = TransactionData.expenseTransactions.where((t) => t.category == a).fold(0.0, (s, t) => s + t.amount);
        final sumB = TransactionData.expenseTransactions.where((t) => t.category == b).fold(0.0, (s, t) => s + t.amount);
        return 'Comparison: You spent \$${sumA.toStringAsFixed(2)} on $a vs \$${sumB.toStringAsFixed(2)} on $b.';
      }

      final cat = matched[0];
      final sum = TransactionData.expenseTransactions.where((t) => t.category == cat).fold(0.0, (s, t) => s + t.amount);
      return 'You spent \$${sum.toStringAsFixed(2)} on $cat in recent transactions.';
    }

    // Profile queries
    if (lower.contains('goal') || lower.contains('objective') || lower.contains('progress')) {
      final prog = ProfileData.overallProgress;
      final emergency = ProfileData.objectives.isNotEmpty ? ProfileData.objectives.first.progress : 0.0;
      return 'Your overall savings progress is ${prog.toStringAsFixed(1)}%. Emergency fund progress: ${emergency.toStringAsFixed(1)}%.';
    }

    // Generic responses (fallback)
    if (lower.contains('save') || lower.contains('saving') || lower.contains('budget')) {
      return 'Start by tracking all spending, set a monthly budget, automate savings, and cut recurring subscriptions you dont use.';
    }
    if (lower.contains('receipt') || lower.contains('expense')) {
      return 'Keep receipts for business expenses, attach them to transactions, note purpose and attendees, and follow your company policy for reimbursement.';
    }
    if (lower.contains('reduce') || lower.contains('cut') || lower.contains('spend less')) {
      return 'Focus on high-impact categories (subscriptions, dining out, transport), set limits, and try alternatives like cooking at home and using public transport.';
    }
    if (lower.contains('invest') || lower.contains('investing')) {
      return 'Maintain an emergency fund first, then invest regularly via low-cost index funds and dollar-cost average.';
    }

    return 'Here are quick tips: 1) Track everything 2) Set a budget 3) Automate savings 4) Review subscriptions monthly. Ask me about any of these.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.92;
    final dialogHeight = size.height * 0.72;
    final content = SizedBox(
      width: dialogWidth,
      height: dialogHeight,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: AppColors.secondary,
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('Expense Helper', style: TextStyle(fontWeight: FontWeight.bold))),
                  if (!widget.inline) IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _messages.isEmpty
                  ? const Center(child: Text('Ask me about saving money or expensing best practices.'))
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        return Align(
                          alignment: m['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: m['isUser'] ? AppColors.primary : AppColors.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m['text'],
                              style: TextStyle(color: m['isUser'] ? AppColors.primaryForeground : AppColors.textPrimary),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                    child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderLight)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _send(_controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.inline) {
      // When embedded inline (e.g., Analytics page), don't wrap in Dialog
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: content,
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: content,
    );
  }
}


