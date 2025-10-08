import 'package:flutter/material.dart';

enum TransactionType { expense, revenue }

class Transaction {
  final int id;
  final String name;
  final String category;
  final String date;
  final double amount;
  final IconData icon;
  final String color;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class TransactionData {
  static final List<Transaction> expenseTransactions = [
    Transaction(
      id: 1,
      name: "Amazon Purchase",
      category: "Shopping",
      date: "Today, 2:30 PM",
      amount: 89.99,
      icon: Icons.shopping_bag,
      color: "#65C4A3",
      type: TransactionType.expense,
    ),
    Transaction(
      id: 2,
      name: "Starbucks",
      category: "Food & Drink",
      date: "Today, 9:15 AM",
      amount: 12.5,
      icon: Icons.coffee,
      color: "#4A90E2",
      type: TransactionType.expense,
    ),
    Transaction(
      id: 3,
      name: "Electric Bill",
      category: "Utilities",
      date: "Yesterday",
      amount: 145.0,
      icon: Icons.flash_on,
      color: "#7ED321",
      type: TransactionType.expense,
    ),
    Transaction(
      id: 4,
      name: "Restaurant",
      category: "Food & Drink",
      date: "Yesterday",
      amount: 67.8,
      icon: Icons.restaurant,
      color: "#50E3C2",
      type: TransactionType.expense,
    ),
    Transaction(
      id: 5,
      name: "Gas Station",
      category: "Transportation",
      date: "2 days ago",
      amount: 52.0,
      icon: Icons.local_gas_station,
      color: "#9013FE",
      type: TransactionType.expense,
    ),
  ];

  static final List<Transaction> revenueTransactions = [
    Transaction(
      id: 6,
      name: "Salary Deposit",
      category: "Income",
      date: "3 days ago",
      amount: 4500.0,
      icon: Icons.work,
      color: "#65C4A3",
      type: TransactionType.revenue,
    ),
    Transaction(
      id: 7,
      name: "Freelance Project",
      category: "Income",
      date: "5 days ago",
      amount: 850.0,
      icon: Icons.attach_money,
      color: "#65C4A3",
      type: TransactionType.revenue,
    ),
    Transaction(
      id: 8,
      name: "Investment Return",
      category: "Investment",
      date: "1 week ago",
      amount: 320.5,
      icon: Icons.trending_up,
      color: "#65C4A3",
      type: TransactionType.revenue,
    ),
  ];

  static List<Transaction> get allTransactions {
    final all = [...revenueTransactions, ...expenseTransactions];
    all.sort((a, b) => b.id.compareTo(a.id));
    return all;
  }

  static double get totalExpenses => 
      expenseTransactions.fold(0, (sum, transaction) => sum + transaction.amount);
  
  static double get totalRevenue => 
      revenueTransactions.fold(0, (sum, transaction) => sum + transaction.amount);
}
