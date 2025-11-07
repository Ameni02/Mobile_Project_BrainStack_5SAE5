import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/quote_api_service.dart';
import '../services/http_helper.dart';

class ApiDevPage extends StatefulWidget {
  const ApiDevPage({super.key});

  @override
  State<ApiDevPage> createState() => _ApiDevPageState();
}

class _ApiDevPageState extends State<ApiDevPage> {
  String _quote = '';
  String _quoteRaw = '';
  String _rateRaw = '';
  bool _allowBadCerts = false;

  Future<void> _fetchQuote() async {
    setState(() => _quote = '');
    try {
      final client = HttpHelper.createClient();
      final q = await QuoteApiService.fetchRandomQuote(client: client);
      setState(() => _quote = q);
      final res = await client.get(Uri.parse('https://api.quotable.io/random'));
      setState(() => _quoteRaw = res.body);
    } catch (e) {
      setState(() => _quote = 'Error: $e');
    }
  }

  Future<void> _fetchRate() async {
    setState(() => _rateRaw = '');
    try {
      HttpHelper.allowBadCerts = _allowBadCerts;
      final client = HttpHelper.createClient();
      final res = await client.get(Uri.parse('https://api.exchangerate.host/latest?base=USD&symbols=EUR'));
      setState(() => _rateRaw = res.body);
    } catch (e) {
      setState(() => _rateRaw = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Dev')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: _fetchQuote, child: const Text('Fetch Quote + Raw')),
            const SizedBox(height: 12),
            Text(_quote.isEmpty ? '(no quote)' : _quote),
            const SizedBox(height: 12),
            Text(_quoteRaw.isEmpty ? '(no raw)' : _quoteRaw),
            const Divider(),
            SwitchListTile(
              title: const Text('Allow bad SSL certs (dev only)'),
              value: _allowBadCerts,
              onChanged: (v) => setState(() => _allowBadCerts = v),
            ),
            ElevatedButton(onPressed: _fetchRate, child: const Text('Fetch Rate Raw')),
            const SizedBox(height: 12),
            Text(_rateRaw.isEmpty ? '(no raw)' : _rateRaw),
          ],
        ),
      ),
    );
  }
}