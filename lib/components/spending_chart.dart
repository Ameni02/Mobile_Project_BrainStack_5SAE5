import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/transaction_data.dart';
import '../constants/currency.dart';

class SpendingChart extends StatefulWidget {
  const SpendingChart({super.key});

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  List<ChartData> _data = [];
  double _totalAmount = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklySpending();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when the widget becomes visible again
    _loadWeeklySpending();
  }

  Future<void> _loadWeeklySpending() async {
    // Ensure transactions are loaded from database
    await TransactionData.loadTransactions();

    // Calculate weekly spending for last 7 days
    final now = DateTime.now();
    List<ChartData> weeklyData = [];
    double total = 0.0;

    for (int i = 6; i >= 0; i--) {
      final dayDate = DateTime(now.year, now.month, now.day - i);
      final label = DateFormat('EEE').format(dayDate);
      double amount = 0.0;

      for (var t in TransactionData.expenseTransactions) {
        DateTime parsed;
        try {
          // Try to parse ISO format date
          parsed = DateTime.parse(t.date);
        } catch (_) {
          // If parsing fails, check if it's a relative date string
          if (t.date.toLowerCase().contains('today')) {
            parsed = now;
          } else if (t.date.toLowerCase().contains('yesterday')) {
            parsed = now.subtract(const Duration(days: 1));
          } else {
            // Default to current date if we can't parse
            parsed = now;
          }
        }

        // Check if transaction date matches the day
        if (parsed.year == dayDate.year &&
            parsed.month == dayDate.month &&
            parsed.day == dayDate.day) {
          amount += t.amount;
        }
      }

      weeklyData.add(ChartData(day: label, amount: amount));
      total += amount;
    }

    if (mounted) {
      setState(() {
        _data = weeklyData;
        _totalAmount = total;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate max amount for chart scaling
    final maxAmount = _data.fold<double>(0.0, (p, e) => e.amount > p ? e.amount : p);
    final double maxY = (maxAmount * 1.3).clamp(10, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Weekly Spending",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatTnd(_totalAmount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _data.isEmpty
                ? const Center(
              child: Text(
                "No expenses this week",
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            )
                : LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _data.length) {
                          return const Text('');
                        }
                        return Text(
                          _data[idx].day,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.amount);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.accent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accent.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String day;
  final double amount;

  ChartData({
    required this.day,
    required this.amount,
  });
}
