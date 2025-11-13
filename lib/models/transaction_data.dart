// lib/models/transaction_data.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../DB/DB.dart'; // utilisation de la base centralisée

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
  final Map<String, dynamic>? extraFields;

  Transaction({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
    required this.color,
    required this.type,
    this.extraFields,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'date': date,
      'amount': amount,
      'icon': icon.codePoint,
      'color': color,
      'type': type.toString(),
      'extraFields': jsonEncode(extraFields ?? {}),
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      date: map['date'],
      amount: (map['amount'] is int) ? (map['amount'] as int).toDouble() : map['amount'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      color: map['color'],
      type: map['type'] == 'TransactionType.expense'
          ? TransactionType.expense
          : TransactionType.revenue,
      extraFields: (map['extraFields'] != null && (map['extraFields'] as String).isNotEmpty)
          ? Map<String, dynamic>.from(jsonDecode(map['extraFields']))
          : {},
    );
  }
}

class TransactionData {
  // Suppression de la gestion locale _db, on passe par DB.db
  static final List<Transaction> expenseTransactions = [];
  static final List<Transaction> revenueTransactions = [];

  // Initialize DB (call once in main)
  static Future<void> initDb() async {
    await DB.db; // assure l'ouverture de la base centrale
    await loadTransactions();
  }

  // Load all transactions from DB into lists
  static Future<void> loadTransactions() async {
    final database = await DB.db;
    final List<Map<String, dynamic>> maps =
        await database.query('transactions', orderBy: 'id DESC');

    expenseTransactions.clear();
    revenueTransactions.clear();

    for (var map in maps) {
      final t = Transaction.fromMap(map);
      if (t.type == TransactionType.expense) {
        expenseTransactions.add(t);
      } else {
        revenueTransactions.add(t);
      }
    }

    await _addStaticDataIfEmpty();
  }

  // Add transaction to DB and in-memory list
  static Future<void> addTransaction(Transaction transaction) async {
    final database = await DB.db;

    await database.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (transaction.type == TransactionType.expense) {
      expenseTransactions.insert(0, transaction);
    } else {
      revenueTransactions.insert(0, transaction);
    }
  }

  // Update transaction
  static Future<void> updateTransaction(Transaction updatedTransaction) async {
    final database = await DB.db;

    await database.update(
      'transactions',
      updatedTransaction.toMap(),
      where: 'id = ?',
      whereArgs: [updatedTransaction.id],
    );

    if (updatedTransaction.type == TransactionType.expense) {
      final index = expenseTransactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) expenseTransactions[index] = updatedTransaction;
    } else {
      final index = revenueTransactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) revenueTransactions[index] = updatedTransaction;
    }
  }

  // Delete by id
  static Future<void> deleteTransaction(int id) async {
    final database = await DB.db;

    await database.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    expenseTransactions.removeWhere((t) => t.id == id);
    revenueTransactions.removeWhere((t) => t.id == id);
  }

  // Delete by object (utile pour ton UI)
  static Future<void> deleteTransactionObject(Transaction transaction) async {
    await deleteTransaction(transaction.id);
  }

  // Add static data if DB is empty
  static Future<void> _addStaticDataIfEmpty() async {
    final database = await DB.db;
    final count = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM transactions')) ?? 0;
    if (count == 0) {
      final staticTransactions = [
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
          name: "Salary Deposit",
          category: "Income",
          date: "3 days ago",
          amount: 4500.0,
          icon: Icons.work,
          color: "#65C4A3",
          type: TransactionType.revenue,
        ),
        Transaction(
          id: 5,
          name: "Freelance Project",
          category: "Income",
          date: "5 days ago",
          amount: 850.0,
          icon: Icons.attach_money,
          color: "#4A90E2",
          type: TransactionType.revenue,
        ),
      ];

      for (var t in staticTransactions) {
        await addTransaction(t);
      }
    }
  }

  // Getters
  static List<Transaction> get allTransactions {
    final all = [...revenueTransactions, ...expenseTransactions];
    all.sort((a, b) => b.id.compareTo(a.id));
    return all;
  }

  static double get totalExpenses =>
      expenseTransactions.fold(0, (sum, t) => sum + t.amount);

  static double get totalRevenue =>
      revenueTransactions.fold(0, (sum, t) => sum + t.amount);

  static int nextId() {
    final all = [...expenseTransactions, ...revenueTransactions];
    if (all.isEmpty) return 1;
    return all.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
  }
}

/*class TransactionData {
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
}*/
