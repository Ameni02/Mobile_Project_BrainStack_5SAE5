import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickAction(
        icon: Icons.arrow_upward,
        label: "Send",
        color: AppColors.accent,
      ),
      QuickAction(
        icon: Icons.arrow_downward,
        label: "Request",
        color: AppColors.primary,
      ),
      QuickAction(
        icon: Icons.sync_alt,
        label: "Exchange",
        color: AppColors.chart3,
      ),
      QuickAction(
        icon: Icons.savings_outlined,
        label: "Save",
        color: AppColors.chart4,
      ),
    ];

    return Row(
      children: actions.map((action) => Expanded(
        child: _buildActionButton(action),
      )).toList(),
    );
  }

  Widget _buildActionButton(QuickAction action) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: action.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            action.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;

  QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });
}
