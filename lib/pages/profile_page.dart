import 'package:flutter/material.dart';
import 'goals_page.dart';
import 'notes_page.dart';
import '../components/todo_list.dart';
import '../models/goals_data.dart';
import '../DB/DB.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _activeGoalsCount = 0;
  double _overallProgress = 0.0;
  int _totalNotes = 0;
  int _archivedNotes = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Goals, Notes, To-Do
    _loadGoalsSummary();
    _loadNotesSummary();
  }

  Future<void> _loadGoalsSummary() async {
    await GoalsData.load();
    setState(() {
      _activeGoalsCount = GoalsData.goals.where((g) => !g.isArchived && !g.isCompleted).length;
      _overallProgress = GoalsData.overallProgress;
    });
  }

  Future<void> _loadNotesSummary() async {
    try {
      final rows = await DB.getNotes();
      int archived = 0;
      for (final m in rows) {
        final v = m['isArchived'];
        bool isArchived;
        if (v is bool) {
          isArchived = v;
        } else if (v is int) {
          isArchived = v == 1;
        } else if (v is String) {
          isArchived = v == '1' || v.toLowerCase() == 'true';
        } else {
          isArchived = false;
        }
        if (isArchived) archived++;
      }
      if (mounted) {
        setState(() {
          _totalNotes = rows.length;
          _archivedNotes = archived;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _totalNotes = 0;
          _archivedNotes = 0;
        });
      }
    }
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
                color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    Icon(Icons.note, size: 16),
                    SizedBox(width: 4),
                    Text("Notes"),
                  ],
                ),
              ),
              Tab(
                icon: Icon(Icons.checklist, size: 18),
                text: "To-Do",
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsTab(),
                _buildNotesTab(), // ordre aligné
                _buildTodosTab(),
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
            const Text(
              "Tap to view and manage your goals",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
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
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotesPage()),
        );
        await _loadNotesSummary();
      },
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromRGBO(74, 144, 226, 0.1),
              const Color.fromRGBO(101, 196, 163, 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromRGBO(74, 144, 226, 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(74, 144, 226, 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.note,
                size: 48,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Notes",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap to view and manage your notes",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text('All', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Text('$_totalNotes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text('Archived', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Text('$_archivedNotes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    "View Notes",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildTabbedContent(),
                const SizedBox(height: 100), // espace pour la bottom nav
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _tabController.index = 0); // Goals
                },
                icon: Icon(
                  Icons.flag,
                  color: _tabController.index == 0 ? const Color(0xFF4A90E2) : const Color(0xFF6B7280),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _tabController.index = 1); // Notes
                },
                icon: Icon(
                  Icons.note,
                  color: _tabController.index == 1 ? const Color(0xFF4A90E2) : const Color(0xFF6B7280),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _tabController.index = 2); // To-Do
                },
                icon: Icon(
                  Icons.checklist,
                  color: _tabController.index == 2 ? const Color(0xFF4A90E2) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
