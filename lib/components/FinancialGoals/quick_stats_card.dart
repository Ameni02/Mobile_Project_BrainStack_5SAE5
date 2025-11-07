import 'package:flutter/material.dart';
import '../../models/goals_data.dart';

class QuickStatsCard extends StatelessWidget {
  const QuickStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final activeGoals = GoalsData.goals.where((g) => !g.isCompleted && !g.isArchived).toList();
    final totalTarget = activeGoals.fold<double>(0, (sum, g) => sum + g.target);
    final totalCurrent = activeGoals.fold<double>(0, (sum, g) => sum + g.current);
    final totalRemaining = totalTarget - totalCurrent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF65C4A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(74, 144, 226, 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Total Goals Progress",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                "${GoalsData.overallProgress.toStringAsFixed(0)}%",
                "Overall",
                Icons.trending_up,
              ),
              _buildStatItem(
                "\$${totalCurrent.toStringAsFixed(0)}",
                "Saved",
                Icons.savings,
              ),
              _buildStatItem(
                "\$${totalRemaining.toStringAsFixed(0)}",
                "Remaining",
                Icons.flag,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
