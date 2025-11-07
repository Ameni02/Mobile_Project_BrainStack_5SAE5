// ==================== profile_page.dart ====================
import 'package:flutter/material.dart';
import '../components/todo_list.dart';
import '../components/notes_list.dart';
import 'goals_page.dart';
import '../models/goals_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _activeGoalsCount = 0;
  double _overallProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGoalsSummary();
  }

  Future<void> _loadGoalsSummary() async {
    await GoalsData.load();
    setState(() {
      _activeGoalsCount = GoalsData.goals.where((g) => !g.isArchived && !g.isCompleted).length;
      _overallProgress = GoalsData.overallProgress;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Profile",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Manage your goals and tasks",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: Color(0xFF6B7280),
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTabbedContent() {
    return Container(
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
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF4A90E2),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF4A90E2),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag, size: 16),
                    SizedBox(width: 4),
                    Text("Goals"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checklist, size: 16),
                    SizedBox(width: 4),
                    Text("To-Do"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note, size: 16),
                    SizedBox(width: 4),
                    Text("Notes"),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsTab(),
                _buildTodosTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    final progressLabel = (_overallProgress).toStringAsFixed(0) + '%';
    return GestureDetector(
      onTap: () async {
        // Navigate and refresh summary when returning
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GoalsPage()),
        );
        await _loadGoalsSummary();
      },
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(74, 144, 226, 0.1),
              Color.fromRGBO(101, 196, 163, 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color.fromRGBO(74, 144, 226, 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromRGBO(74, 144, 226, 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag,
                size: 48,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Financial Goals",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap to view and manage your goals",
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            // Dynamic summary
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text('Active', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Text('$_activeGoalsCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text('Progress', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Text(progressLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View Goals",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodosTab() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: TodoList(),
    );
  }

  Widget _buildNotesTab() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: NotesList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildTabbedContent(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
