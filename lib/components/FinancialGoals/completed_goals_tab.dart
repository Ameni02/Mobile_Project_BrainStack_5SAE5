import 'package:flutter/material.dart';
import '../../models/goals_data.dart';
import 'achievement_banner.dart';
import 'completed_goal_card.dart';

class CompletedGoalsTab extends StatelessWidget {
  final VoidCallback? onRefresh;

  const CompletedGoalsTab({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final completedGoals = GoalsData.goals.where((g) => g.isCompleted).toList();

    if (completedGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No completed goals yet",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "Keep working on your active goals!",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AchievementBanner(completedCount: completedGoals.length),
        const SizedBox(height: 16),
        ...completedGoals.map((goal) => CompletedGoalCard(goal: goal)),
      ],
    );
  }
}
