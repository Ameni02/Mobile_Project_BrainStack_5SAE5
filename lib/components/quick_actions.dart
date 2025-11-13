import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../pages/news_page.dart';
import '../pages/crypto_page.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickAction(
        icon: Icons.article_outlined,
        label: "News",
        color: AppColors.chart3,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewsPage()),
          );
        },
      ),
      QuickAction(
        icon: Icons.currency_bitcoin_outlined,
        label: "Crypto",
        color: AppColors.chart4,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CryptoPage()),
          );
        },
      ),
    ];

    return Row(
      children: actions
          .map((action) => Expanded(
        child: _buildActionButton(context, action),
      ))
          .toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
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
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
