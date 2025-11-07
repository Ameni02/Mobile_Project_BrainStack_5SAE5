import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:brain_stack/services/quote_api_service.dart';

void main() {
  test('fetchRandomQuote parses response', () async {
    final mockClient = MockClient((request) async {
      final body = json.encode({'content': 'Save a little each day', 'author': 'Tester'});
      return http.Response(body, 200);
    });

    final q = await QuoteApiService.fetchRandomQuote(client: mockClient);
    expect(q, contains('Save a little each day'));
    expect(q, contains('Tester'));
  });
}
