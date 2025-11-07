import 'package:flutter/material.dart';
import '../../models/goals_data.dart';

class SmartSuggestionsCard extends StatelessWidget {
  const SmartSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final urgentGoals = GoalsData.goals
        .where((g) => !g.isCompleted && g.daysRemaining < 30 && g.daysRemaining > 0)
        .toList();

    if (urgentGoals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(249, 115, 22, 0.1), // orange 0xF97316
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromRGBO(249, 115, 22, 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "💡 Smart Tip",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You have ${urgentGoals.length} goal(s) with less than 30 days remaining. Consider increasing your savings rate!",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
