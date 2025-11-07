import 'package:flutter/material.dart';
import '../../models/goal_model.dart';

class CompletedGoalCard extends StatelessWidget {
  final Goal goal;

  const CompletedGoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(16, 185, 129, 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromRGBO(16, 185, 129, 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${goal.emoji} ${goal.title}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Completed • ${goal.target.toStringAsFixed(0)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}