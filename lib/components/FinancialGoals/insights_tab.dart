import 'package:flutter/material.dart';
import 'progress_chart_card.dart';
import 'category_breakdown_card.dart';
import 'savings_projection_card.dart';
import 'motivational_card.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ProgressChartCard(),
        SizedBox(height: 24),
        CategoryBreakdownCard(),
        SizedBox(height: 24),
        SavingsProjectionCard(),
        SizedBox(height: 24),
        MotivationalCard(),
      ],
    );
  }
}