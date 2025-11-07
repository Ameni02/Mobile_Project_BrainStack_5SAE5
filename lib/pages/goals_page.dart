import 'package:flutter/material.dart';
import '../models/goals_data.dart';
import '../models/goal_model.dart';
import '../components/FinancialGoals/active_goals_tab.dart';
import '../components/FinancialGoals/completed_goals_tab.dart';
import '../components/FinancialGoals/add_goal_dialog.dart';
import '../components/FinancialGoals/quote_banner.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDialogOpen = false;
  String _filterCategory = 'All';
  String _sortBy = 'deadline';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // load persisted goals
    GoalsData.load().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (_) => AddGoalDialog(
        isOpen: true,
        onClose: () {
          Navigator.of(context).pop();
          setState(() => _isDialogOpen = false);
        },
        onSave: (goal) async {
          // persist via GoalsData
          if (GoalsData.goals.any((g) => g.id == goal.id)) {
            await GoalsData.updateGoal(goal);
          } else {
            await GoalsData.addGoal(goal);
          }
          await GoalsData.load();
          Navigator.of(context).pop();
          setState(() => _isDialogOpen = false);
        },
      ),
    );
  }

  void _onRefresh() async {
    await GoalsData.load();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(onPressed: _onRefresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _openAddDialog, icon: const Icon(Icons.add))
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Completed')],
        ),
      ),
      body: Column(
        children: [
          const QuoteBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ActiveGoalsTab(filterCategory: _filterCategory, sortBy: _sortBy, onRefresh: _onRefresh),
                CompletedGoalsTab(onRefresh: _onRefresh),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
