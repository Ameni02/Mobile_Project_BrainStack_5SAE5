import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      Transaction(
        id: 1,
        name: "Amazon Purchase",
        category: "Shopping",
        date: "Today, 2:30 PM",
        amount: -89.99,
        icon: Icons.shopping_bag,
        color: AppColors.chart1,
      ),
      Transaction(
        id: 2,
        name: "Starbucks",
        category: "Food & Drink",
        date: "Today, 9:15 AM",
        amount: -12.5,
        icon: Icons.coffee,
        color: AppColors.chart2,
      ),
      Transaction(
        id: 3,
        name: "Electric Bill",
        category: "Utilities",
        date: "Yesterday",
        amount: -145.0,
        icon: Icons.flash_on,
        color: AppColors.chart3,
      ),
      Transaction(
        id: 4,
        name: "Restaurant",
        category: "Food & Drink",
        date: "Yesterday",
        amount: -67.8,
        icon: Icons.restaurant,
        color: AppColors.chart4,
      ),
      Transaction(
        id: 5,
        name: "Gas Station",
        category: "Transportation",
        date: "2 days ago",
        amount: -52.0,
        icon: Icons.local_gas_station,
        color: AppColors.chart5,
      ),
    ];

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
          const Text(
            "Recent Transactions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...transactions.map((transaction) => _buildTransactionItem(transaction)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: transaction.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${transaction.category} • ${transaction.date}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${transaction.amount < 0 ? '-' : '+'}\$${transaction.amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: transaction.amount < 0 ? AppColors.textPrimary : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class Transaction {
  final int id;
  final String name;
  final String category;
  final String date;
  final double amount;
  final IconData icon;
  final Color color;

  Transaction({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
    required this.color,
  });
}
