import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_data.dart';

class AlphaVantageService {
  static const String apiKey = 'JYPMGG7TC0TX280A';
  static const String baseUrl = 'https://www.alphavantage.co/query';

  // Get real stock price
  static Future<double?> getStockPrice(String symbol) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$apiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final quote = data['Global Quote'] as Map<String, dynamic>?;
        if (quote != null && quote['05. price'] != null) {
          return double.tryParse(quote['05. price'].toString());
        }
      }
    } catch (e) {
      debugPrint('Error getting stock price: $e');
    }
    return null;
  }

  // Get real exchange rate
  static Future<double?> getExchangeRate(String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?function=CURRENCY_EXCHANGE_RATE&from_currency=$from&to_currency=$to&apikey=$apiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rateData = data['Realtime Currency Exchange Rate'] as Map<String, dynamic>?;
        if (rateData != null && rateData['5. Exchange Rate'] != null) {
          return double.tryParse(rateData['5. Exchange Rate'].toString());
        }
      }
    } catch (e) {
      debugPrint('Error getting exchange rate: $e');
    }
    return null;
  }

  // Generate realistic financial transactions as Transaction objects compatible with Transaction model
  static Future<List<Transaction>> generateRealTransactionsAsModel() async {
    final List<Transaction> transactions = [];

    final double? usdToEur = await getExchangeRate('USD', 'EUR');
    final double? usdToGbp = await getExchangeRate('USD', 'GBP');
    final double? applePrice = await getStockPrice('AAPL');
    final double? googlePrice = await getStockPrice('GOOGL');

    final now = DateTime.now();

    // Apple purchase (expense / investment)
    transactions.add(Transaction(
      id: now.millisecondsSinceEpoch,
      name: 'Apple Stock Purchase',
      category: 'Investments',
      date: now.subtract(const Duration(days: 1)).toIso8601String(),
      amount: -1000.00,
      icon: Icons.attach_money,
      color: '#65C4A3',
      type: TransactionType.expense,
      extraFields: {
        'symbol': 'AAPL',
        'currentPrice': applePrice,
        'units': (applePrice != null && applePrice > 0) ? (1000.0 / applePrice) : null,
        'status': 'completed',
      },
    ));

    // Hotel booking in Paris (foreign)
    transactions.add(Transaction(
      id: now.millisecondsSinceEpoch + 1,
      name: 'Hotel Booking Paris',
      category: 'Travel',
      date: now.subtract(const Duration(days: 2)).toIso8601String(),
      amount: -150.00,
      icon: Icons.hotel,
      color: '#4A90E2',
      type: TransactionType.expense,
      extraFields: {
        'originalAmount': -150.00,
        'originalCurrency': 'USD',
        'convertedAmount': usdToEur != null ? -150.00 * usdToEur : -136.95,
        'convertedCurrency': 'EUR',
        'exchangeRate': usdToEur,
        'status': 'completed',
      },
    ));

    // Google purchase
    transactions.add(Transaction(
      id: now.millisecondsSinceEpoch + 2,
      name: 'Google Stock Purchase',
      category: 'Investments',
      date: now.subtract(const Duration(days: 3)).toIso8601String(),
      amount: -500.00,
      icon: Icons.attach_money,
      color: '#7ED321',
      type: TransactionType.expense,
      extraFields: {
        'symbol': 'GOOGL',
        'currentPrice': googlePrice,
        'units': (googlePrice != null && googlePrice > 0) ? (500.0 / googlePrice) : null,
        'status': 'completed',
      },
    ));

    // London shopping (foreign)
    transactions.add(Transaction(
      id: now.millisecondsSinceEpoch + 3,
      name: 'London Shopping',
      category: 'Shopping',
      date: now.subtract(const Duration(days: 4)).toIso8601String(),
      amount: -75.00,
      icon: Icons.shopping_bag,
      color: '#9013FE',
      type: TransactionType.expense,
      extraFields: {
        'originalAmount': -75.00,
        'originalCurrency': 'USD',
        'convertedAmount': usdToGbp != null ? -75.00 * usdToGbp : -59.25,
        'convertedCurrency': 'GBP',
        'exchangeRate': usdToGbp,
        'status': 'completed',
      },
    ));

    // Monthly salary (income)
    transactions.add(Transaction(
      id: now.millisecondsSinceEpoch + 4,
      name: 'Monthly Salary',
      category: 'Income',
      date: now.subtract(const Duration(days: 5)).toIso8601String(),
      amount: 2500.00,
      icon: Icons.work,
      color: '#65C4A3',
      type: TransactionType.revenue,
      extraFields: {
        'status': 'completed',
      },
    ));

    return transactions;
  }

  // Persist generated transactions into your app's TransactionData (DB + in-memory lists)
  static Future<void> persistGeneratedTransactions() async {
    final txs = await generateRealTransactionsAsModel();
    for (final t in txs) {
      try {
        await TransactionData.addTransaction(t);
      } catch (e) {
        debugPrint('Error persisting transaction id=${t.id}: $e');
      }
    }
  }
}


