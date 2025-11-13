import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PortfolioHeader extends StatelessWidget {
  final String? username;

  const PortfolioHeader({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          // Avatar and User Info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    // Show initial (first char) of username or fallback
                    (username != null && username!.isNotEmpty) ? username![0].toUpperCase() : 'JD',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Jordan Davis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

        ],
      ),
    );
  }
}
