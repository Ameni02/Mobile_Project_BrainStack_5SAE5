import 'package:flutter/material.dart';
import '../models/goals_data.dart';
import '../components/FinancialGoals/active_goals_tab.dart';
import '../components/FinancialGoals/completed_goals_tab.dart';
import '../components/FinancialGoals/add_goal_dialog.dart';
import '../components/FinancialGoals/quote_banner.dart';
import '../services/goal_export_service.dart';
import 'dart:io';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  late TabController _tabController;
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
    // open add dialog
    showDialog(
      context: context,
      builder: (_) => AddGoalDialog(
        isOpen: true,
        onClose: () {
          Navigator.of(context).pop();
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
        },
      ),
    );
  }

  void _onRefresh() async {
    await GoalsData.load();
    setState(() {});
  }

  // Export functions: CSV / Excel / PDF
  Future<void> _exportAndShare(BuildContext context, String format) async {
    try {
      if (GoalsData.goals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No goals to export')));
        return;
      }

      File file;
      switch (format) {
        case 'csv':
          file = await GoalExportService.exportCsv(GoalsData.goals);
          break;
        case 'excel':
          file = await GoalExportService.exportExcel(GoalsData.goals);
          break;
        case 'pdf':
          file = await GoalExportService.exportPdf(GoalsData.goals);
          break;
        default:
          throw Exception('Unknown export format: $format');
      }

      await GoalExportService.shareFile(file, subject: 'My goals export');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported and shared: ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool empty = GoalsData.goals.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(onPressed: _onRefresh, icon: const Icon(Icons.refresh)),
          // Export menu: CSV / Excel / PDF
          PopupMenuButton<String>(
            tooltip: 'Export goals',
            icon: const Icon(Icons.download),
            onSelected: (v) => _exportAndShare(context, v),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'excel', child: Text('Export Excel')),
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
          ),
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
