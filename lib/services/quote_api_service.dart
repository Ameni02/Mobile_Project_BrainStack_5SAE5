import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _quoteStorageKey = 'quote_api_last';

class QuoteApiService {
  /// Fetch a random inspirational quote using a chain of public providers.
  /// Falls back to cached quote or a default if all providers fail.
  static Future<String> fetchRandomQuote({http.Client? client}) async {
    client ??= HttpHelper.createClient();

    final providers = <Future<String> Function()>[
      () async {
        final res = await client!.get(Uri.parse('https://api.quotable.io/random'));
        if (res.statusCode != 200) throw Exception('quotable error ${res.statusCode}');
        final map = json.decode(res.body) as Map<String, dynamic>;
        final content = map['content'] as String? ?? '';
        final author = map['author'] as String? ?? '';
        return content + (author.isNotEmpty ? ' — $author' : '');
      },
      () async {
        final res = await client!.get(Uri.parse('https://zenquotes.io/api/random'));
        if (res.statusCode != 200) throw Exception('zenquotes error ${res.statusCode}');
        final list = json.decode(res.body) as List<dynamic>;
        if (list.isEmpty) throw Exception('zenquotes empty');
        final m = list.first as Map<String, dynamic>;
        return '${m['q'] ?? ''}${(m['a'] != null && m['a'].toString().isNotEmpty) ? ' — ${m['a']}' : ''}';
      },
      () async {
        final res = await client!.get(Uri.parse('https://type.fit/api/quotes'));
        if (res.statusCode != 200) throw Exception('type.fit error ${res.statusCode}');
        final list = json.decode(res.body) as List<dynamic>;
        if (list.isEmpty) throw Exception('type.fit empty');
        final idx = DateTime.now().millisecondsSinceEpoch % list.length;
        final m = list[idx] as Map<String, dynamic>;
        return '${m['text'] ?? ''}${(m['author'] != null && m['author'].toString().isNotEmpty) ? ' — ${m['author']}' : ''}';
      },
    ];

    Object? lastError;

    for (final provider in providers) {
      try {
        final q = await provider();
        // cache
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_quoteStorageKey, q);
        } catch (_) {}
        if (q.isNotEmpty) return q;
      } catch (e) {
        lastError = e;
      }
    }

    // try cached
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_quoteStorageKey);
      if (cached != null && cached.isNotEmpty) return cached;
    } catch (_) {}

    return 'Save consistently. Small steps add up.';
  }
}