import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analytics_data.dart';
import '../models/transaction_data.dart';
import '../theme/app_colors.dart';
import '../components/expense_chatbot.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<MonthlyData> _monthlyData = [];
  List<WeeklySpending> _weeklySpending = [];
  List<CategoryData> _categoryData = [];
  double _totalExpenses = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load transactions and compute analytics
    TransactionData.loadTransactions().then((_) {
      _computeAnalytics();
    });
  }

  void _computeAnalytics() {
    final now = DateTime.now();
    final all = TransactionData.allTransactions;

    // Totals
    _totalExpenses = TransactionData.totalExpenses;
    _totalRevenue = TransactionData.totalRevenue;

    // Monthly - last 6 months
    List<MonthlyData> monthly = [];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i);
      final label = DateFormat('MMM').format(monthDate);
      double exp = 0;
      double rev = 0;
      for (var t in all) {
        DateTime parsed;
        try {
          parsed = DateTime.parse(t.date);
        } catch (_) {
          parsed = now;
        }
        if (parsed.year == monthDate.year && parsed.month == monthDate.month) {
          if (t.type == TransactionType.expense) exp += t.amount;
          else rev += t.amount;
        }
      }
      monthly.add(MonthlyData(month: label, expenses: exp, revenue: rev));
    }
    _monthlyData = monthly;

    // Weekly - last 7 days
    List<WeeklySpending> weekly = [];
    for (int i = 6; i >= 0; i--) {
      final dayDate = DateTime(now.year, now.month, now.day - i);
      final label = DateFormat('EEE').format(dayDate);
      double amount = 0;
      for (var t in TransactionData.expenseTransactions) {
        DateTime parsed;
        try {
          parsed = DateTime.parse(t.date);
        } catch (_) {
          parsed = now;
        }
        if (parsed.year == dayDate.year && parsed.month == dayDate.month && parsed.day == dayDate.day) {
          amount += t.amount;
        }
      }
      weekly.add(WeeklySpending(day: label, amount: amount));
    }
    _weeklySpending = weekly;

    // Category - expenses by category
    final Map<String, double> catMap = {};
    for (var t in TransactionData.expenseTransactions) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    }
    _categoryData = catMap.entries.map((e) => CategoryData(name: e.key, value: e.value, color: "#65C4A3")).toList();

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),
                
                // Summary Stats
                _buildSummaryStats(),
                const SizedBox(height: 24),
                
                // Charts Card
                _buildChartsCard(),
                const SizedBox(height: 24),
                
                // Spending Insights
                _buildSpendingInsights(),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Analytics",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Track your financial progress",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  showDialog(context: context, builder: (_) => const ExpenseChatbot());
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF6B7280)),
                tooltip: 'Expense Helper',
              ),
              const Icon(
                Icons.settings_outlined,
                color: Color(0xFF6B7280),
                size: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            title: "Net Income",
            value: "\$${(_totalRevenue - _totalExpenses).toStringAsFixed(0)}",
            subtitle: "Last 6 months",
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            title: "Savings Rate",
            value: "${(_totalRevenue == 0 ? 0 : ((_totalRevenue - _totalExpenses) / _totalRevenue * 100)).toStringAsFixed(1)}%",
            subtitle: "Of total income",
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
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
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsCard() {
    return Container(
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
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Financial Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicator: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              tabs: const [
                Tab(text: "Monthly"),
                Tab(text: "Weekly"),
                Tab(text: "Category"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonthlyChart(),
                _buildWeeklyChart(),
                _buildCategoryChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (_monthlyData.fold(0.0, (s, d) => s + d.expenses + d.revenue) * 0.6).clamp(1000, 100000),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= _monthlyData.length) return const Text('');
                  return Text(
                    _monthlyData[value.toInt()].month,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _monthlyData.asMap().entries.map((entry) {
            int index = entry.key;
            MonthlyData data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.expenses,
                  color: AppColors.textPrimary,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: data.revenue,
                  color: AppColors.textSecondary,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                (value.toInt() < 0 || value.toInt() >= _weeklySpending.length) ? '' : _weeklySpending[value.toInt()].day,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _weeklySpending.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.amount);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF4A90E2),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF4A90E2),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF4A90E2).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: _categoryData.isEmpty ? [] : _categoryData.asMap().entries.map((entry) {
            CategoryData data = entry.value;
            double total = _categoryData.fold(0, (sum, item) => sum + item.value);
            double percentage = total == 0 ? 0 : (data.value / total) * 100;
            
            return PieChartSectionData(
              color: Color(int.parse(data.color.replaceAll('#', '0xFF'))),
              value: data.value,
              title: '${data.name}\n${percentage.toStringAsFixed(0)}%',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSpendingInsights() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Spending Insights",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          ...AnalyticsData.insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(SpendingInsight insight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(int.parse(insight.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.icon == "trending_down" ? Icons.trending_down : Icons.calendar_today,
              color: Color(int.parse(insight.color.replaceAll('#', '0xFF'))),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

