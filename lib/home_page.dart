import 'package:flutter/material.dart';
import 'pages/analytics_page.dart';
import 'pages/transactions_page.dart';
import 'pages/profile_page.dart';
import 'components/balance_card.dart';
import 'components/portfolio_header.dart';
import 'components/quick_actions.dart';
import 'components/spending_chart.dart';
import 'components/recent_transactions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AnalyticsPage(),
    TransactionsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.attach_money_outlined), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Portfolio Header
            const PortfolioHeader(),
            
            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Balance Card
                  const BalanceCard(),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  const QuickActions(),
                  const SizedBox(height: 24),
                  
                  // Spending Chart
                  const SpendingChart(),
                  const SizedBox(height: 24),
                  
                  // Recent Transactions
                  const RecentTransactions(),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
