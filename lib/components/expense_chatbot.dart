import 'package:flutter/material.dart';

class ExpenseChatbot extends StatefulWidget {
  const ExpenseChatbot({super.key});

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
      final reply = _getReply(text.toLowerCase());
      setState(() {
        _messages.insert(0, {'text': reply, 'isUser': false});
      });
    });
  }

  String _getReply(String input) {
    if (input.contains('save') || input.contains('saving') || input.contains('budget')) {
      return 'Start by tracking all spending, set a monthly budget, automate savings, and cut recurring subscriptions you don\'t use.';
    }
    if (input.contains('receipt') || input.contains('expense') || input.contains('receipt')) {
      return 'Keep receipts for business expenses, attach them to transactions, note purpose and attendees, and follow your company policy for reimbursement.';
    }
    if (input.contains('reduce') || input.contains('cut') || input.contains('spend less')) {
      return 'Focus on high-impact categories (subscriptions, dining out, transport), set limits, and try alternatives like cooking at home and using public transport.';
    }
    if (input.contains('invest') || input.contains('investing')) {
      return 'Maintain an emergency fund first, then invest regularly via low-cost index funds and dollar-cost average.';
    }
    // default: provide a short list of tips
    return 'Here are quick tips: 1) Track everything 2) Set a budget 3) Automate savings 4) Review subscriptions monthly. Ask me about any of these.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.92;
    final dialogHeight = size.height * 0.72;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Color(0xFFF3F4F6),
                ),
                child: Row(
                  children: [
                    const Expanded(child: Text('Expense Helper', style: TextStyle(fontWeight: FontWeight.bold))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
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
                                color: m['isUser'] ? const Color(0xFF4A90E2) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                m['text'],
                                style: TextStyle(color: m['isUser'] ? Colors.white : Colors.black87),
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
                          decoration: const InputDecoration(hintText: 'Ask a question...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _send(_controller.text),
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


