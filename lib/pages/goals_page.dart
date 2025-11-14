import 'package:flutter/material.dart';
import '../models/goals_data.dart';
import '../components/FinancialGoals/active_goals_tab.dart';
import '../components/FinancialGoals/completed_goals_tab.dart';
import '../components/FinancialGoals/add_goal_dialog.dart';
import '../models/goal_model.dart';
import '../components/FinancialGoals/quote_banner.dart';

// GoalsPage minimal version repaired

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  Future<void> _init() async {
    await GoalsData.load();
    await GoalsData.ensureSeeded();
    await GoalsData.migrateDeadlinesAndCompletion();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddGoal() {
    showDialog<Goal>(
      context: context,
      builder: (_) => AddGoalDialog(
        isOpen: true,
        onClose: () => Navigator.of(context).pop(),
        onSave: (g) async {
          if (GoalsData.goals.any((e) => e.id == g.id)) {
            await GoalsData.updateGoal(g);
          } else {
            await GoalsData.addGoal(g);
          }
          await GoalsData.migrateDeadlinesAndCompletion();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(onPressed: _openAddGoal, icon: const Icon(Icons.add)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Completed')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const QuoteBanner(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ActiveGoalsTab(filterCategory: 'All', sortBy: 'deadline', onRefresh: _init),
                      CompletedGoalsTab(onRefresh: _init),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
