import 'package:flutter/material.dart';
import '../../models/goals_data.dart';

class SavingsProjectionCard extends StatelessWidget {
  const SavingsProjectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final activeGoals = GoalsData.goals.where((g) => !g.isCompleted).toList();
    final totalDailyNeeded = activeGoals.fold<double>(
      0,
      (sum, goal) => sum + goal.dailySavingsNeeded(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🎯 Savings Recommendation",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromRGBO(74, 144, 226, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Daily savings needed:",
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      "${totalDailyNeeded.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Weekly savings needed:",
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      "${(totalDailyNeeded * 7).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "💡 Tip: Set up automatic transfers to stay on track!",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
