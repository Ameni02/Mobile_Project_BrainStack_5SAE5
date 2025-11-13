import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/transaction_data.dart';

/// Simple Twilio helper.
/// Replace the placeholder values below with your account SID, auth token and numbers.
class TwilioService {
  // TODO: Replace these with your real credentials or provide a secure config.



  /// Send a generic SMS message via Twilio REST API.
  static Future<bool> sendSms({required String to, required String from, required String body}) async {
    try {
      final creds = base64Encode(utf8.encode('$accountSid:$authToken'));
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Basic $creds',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': to,
          'From': from,
          'Body': body,
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('Twilio SMS failed: ${response.statusCode} ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Twilio sendSms error: $e');
      return false;
    }
  }

  /// Convenience: send an expense notification built from a Transaction model.
  static Future<bool> sendExpenseNotification(Transaction t) async {
    final amountStr = t.amount.toStringAsFixed(2);
    final description = t.name.isNotEmpty ? t.name : 'Expense';
    final category = t.category;
    final body = 'Expense recorded: $category • \$$amountStr\nDescription: $description';
    return await sendSms(to: toNumber, from: fromNumber, body: body);
  }
}


