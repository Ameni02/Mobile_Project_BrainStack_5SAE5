import 'package:flutter/material.dart';

class MotivationalCard extends StatelessWidget {
  const MotivationalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final motivationalQuotes = [
      "You're doing great! Keep up the momentum.",
      "Small steps lead to big achievements!",
      "Every dollar saved is a step closer to your dreams.",
      "Financial freedom is within your reach!",
      "Stay focused, stay determined!",
    ];

    final randomQuote = motivationalQuotes[DateTime.now().day % motivationalQuotes.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade100, Colors.purple.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "💪 Keep Going!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            randomQuote,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
