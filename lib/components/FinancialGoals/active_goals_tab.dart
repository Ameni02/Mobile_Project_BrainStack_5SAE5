import 'package:flutter/material.dart';
import '../../models/goal_model.dart';
import '../../models/goals_data.dart';
import 'quick_stats_card.dart';
import 'smart_suggestions_card.dart';
import 'enhanced_goal_card.dart';

class ActiveGoalsTab extends StatelessWidget {
  final String filterCategory;
  final String sortBy;
  final VoidCallback onRefresh;

  const ActiveGoalsTab({
    super.key,
    required this.filterCategory,
    required this.sortBy,
    required this.onRefresh,
  });

  List<Goal> get _filteredGoals {
    var goals = GoalsData.goals.where((g) => !g.isArchived && !g.isCompleted).toList();

    if (filterCategory != 'All') {
      goals = goals.where((g) => g.category == filterCategory).toList();
    }

    switch (sortBy) {
      case 'progress':
        goals.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case 'priority':
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        goals.sort((a, b) => priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!));
        break;
      default:
        goals.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    }

    return goals;
  }

  @override
  Widget build(BuildContext context) {
    final activeGoals = _filteredGoals;

    if (activeGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No Active Goals",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start your savings journey today!",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const QuickStatsCard(),
        const SizedBox(height: 16),
        const SmartSuggestionsCard(),
        const SizedBox(height: 24),
        ...activeGoals.map((goal) => EnhancedGoalCard(
          goal: goal,
          onRefresh: onRefresh,
        )),
      ],
    );
  }
}
