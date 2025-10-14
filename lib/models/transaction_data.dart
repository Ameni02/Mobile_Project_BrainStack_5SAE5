import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  final Map<String, dynamic>? extraFields; // ✅ Ajout


  Transaction({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
    required this.color,
    required this.type,
    this.extraFields, // ✅ Ajout

  });
}

class TransactionData {
  static final List<Transaction> expenseTransactions = [];
  static final List<Transaction> revenueTransactions = [];

  // Convertir Transaction en Map
  static Map<String, dynamic> transactionToMap(Transaction t) {
    return {
      'id': t.id,
      'name': t.name,
      'category': t.category,
      'date': t.date,
      'amount': t.amount,
      'icon': t.icon.codePoint,
      'color': t.color,
      'type': t.type.toString(),
      'extraFields': t.extraFields ?? {}, // ✅ Ajout

    };
  }

  // Convertir Map en Transaction
  static Transaction mapToTransaction(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      date: map['date'],
      amount: map['amount'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      color: map['color'],
      type: map['type'] == 'TransactionType.expense'
          ? TransactionType.expense
          : TransactionType.revenue,
      extraFields: Map<String, dynamic>.from(map['extraFields'] ?? {}), // ✅ Ajout important

    );
  }

  // Sauvegarder les listes dans SharedPreferences
  static Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    final expenseList =
    expenseTransactions.map((t) => jsonEncode(transactionToMap(t))).toList();
    final revenueList =
    revenueTransactions.map((t) => jsonEncode(transactionToMap(t))).toList();

    await prefs.setStringList('expenseTransactions', expenseList);
    await prefs.setStringList('revenueTransactions', revenueList);
  }

  // Charger les listes depuis SharedPreferences
  static Future<void> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    final expenseList = prefs.getStringList('expenseTransactions') ?? [];
    final revenueList = prefs.getStringList('revenueTransactions') ?? [];

    expenseTransactions.clear();
    revenueTransactions.clear();

    expenseTransactions
        .addAll(expenseList.map((e) => mapToTransaction(jsonDecode(e))));
    revenueTransactions
        .addAll(revenueList.map((e) => mapToTransaction(jsonDecode(e))));

    // Ajouter les données statiques si les listes sont vides
    await _addStaticDataIfEmpty();
  }

  // Ajouter une transaction et sauvegarder
  static Future<void> addTransaction(Transaction transaction) async {
    if (transaction.type == TransactionType.expense) {
      expenseTransactions.add(transaction);
    } else {
      revenueTransactions.add(transaction);
    }
    await saveTransactions();
  }

  // Ajouter des données statiques
  static Future<void> _addStaticDataIfEmpty() async {
    if (expenseTransactions.isEmpty && revenueTransactions.isEmpty) {
      expenseTransactions.addAll([
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
      ]);

      revenueTransactions.addAll([
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
      ]);

      await saveTransactions();
    }
  }

  // Supprimer une transaction par ID et sauvegarder
  static Future<void> deleteTransaction(int id, TransactionType type) async {
    if (type == TransactionType.expense) {
      expenseTransactions.removeWhere((t) => t.id == id);
    } else {
      revenueTransactions.removeWhere((t) => t.id == id);
    }
    await saveTransactions();
  }

  static Future<void> deleteTransactionObject(Transaction transaction) async {
    if (transaction.type == TransactionType.expense) {
      expenseTransactions.remove(transaction);
    } else {
      revenueTransactions.remove(transaction);
    }
    await saveTransactions();
  }



  // Getter pour toutes les transactions
  static List<Transaction> get allTransactions {
    final all = [...revenueTransactions, ...expenseTransactions];
    all.sort((a, b) => b.id.compareTo(a.id));
    return all;
  }

  // Mettre à jour une transaction existante
  static Future<void> updateTransaction(Transaction updatedTransaction) async {
    if (updatedTransaction.type == TransactionType.revenue) {
      final index = revenueTransactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) {
        revenueTransactions[index] = updatedTransaction;
      }
    } else if (updatedTransaction.type == TransactionType.expense) {
      final index = expenseTransactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) {
        expenseTransactions[index] = updatedTransaction;
      }
    }

    // Sauvegarde dans SharedPreferences
    await saveTransactions();
  }


  // Totaux
  static double get totalExpenses =>
      expenseTransactions.fold(0, (sum, t) => sum + t.amount);

  static double get totalRevenue =>
      revenueTransactions.fold(0, (sum, t) => sum + t.amount);
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
