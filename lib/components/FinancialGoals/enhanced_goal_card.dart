import 'package:flutter/material.dart';
import '../../models/goal_model.dart';
import '../../pages/goal_details_page.dart';
import 'add_contribution_dialog.dart';

class EnhancedGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onRefresh;

  const EnhancedGoalCard({
    super.key,
    required this.goal,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColors = {
      'high': Colors.red,
      'medium': Colors.orange,
      'low': Colors.green,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailsPage(goal: goal),
              ),
            ).then((_) => onRefresh());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(goal.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            goal.category,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          (priorityColors[goal.priority]!.red),
                          (priorityColors[goal.priority]!.green),
                          (priorityColors[goal.priority]!.blue),
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal.priority.toUpperCase(),
                        style: TextStyle(
                          color: priorityColors[goal.priority],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.progress / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      goal.progress >= 75
                          ? Colors.green
                          : goal.progress >= 50
                          ? Colors.blue
                          : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TND ${goal.current.toStringAsFixed(0)} / TND ${goal.target.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "${goal.progress.toStringAsFixed(0)}% complete",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${goal.daysRemaining} days left",
                          style: TextStyle(
                            color: goal.daysRemaining < 30 ? Colors.red : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Due: ${goal.deadline}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      context,
                      Icons.add_circle_outline,
                      "Add Money",
                          () => _showAddContribution(context),
                    ),
                    _buildActionButton(
                      context,
                      Icons.analytics_outlined,
                      "Details",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GoalDetailsPage(goal: goal),
                          ),
                        ).then((_) => onRefresh());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4A90E2), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4A90E2),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContribution(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddContributionDialog(
        goal: goal,
        onSave: () => onRefresh(),
      ),
    );
  }
}
