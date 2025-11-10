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
        // ignore provider error and try next
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

  /// Fetch a quote related to [theme]. Not all public providers support theme search.
  /// We attempt providers that allow querying; otherwise, fall back to a small curated list.
  static Future<String> fetchThemedQuote(String theme, {http.Client? client}) async {
    client ??= HttpHelper.createClient();
    final t = theme.toLowerCase();

    // Attempt providers with search capabilities
    final providers = <Future<String> Function()>[
      () async {
        // quotable supports tags and search
        final q = Uri.parse('https://api.quotable.io/random?tags=$t');
        final res = await client!.get(q);
        if (res.statusCode != 200) throw Exception('quotable themed ${res.statusCode}');
        final map = json.decode(res.body) as Map<String, dynamic>;
        final content = map['content'] as String? ?? '';
        final author = map['author'] as String? ?? '';
        if (content.isEmpty) throw Exception('empty');
        return content + (author.isNotEmpty ? ' — $author' : '');
      },
      () async {
        // zenquotes has an endpoint for keyword search via quotes API? Fallback to random
        final res = await client!.get(Uri.parse('https://zenquotes.io/api/quotes'));
        if (res.statusCode != 200) throw Exception('zenquotes themed ${res.statusCode}');
        final list = json.decode(res.body) as List<dynamic>;
        // try to pick one that contains the theme word
        final found = list.cast<Map<String, dynamic>>().firstWhere(
          (m) => (m['q'] ?? '').toString().toLowerCase().contains(t) || (m['a'] ?? '').toString().toLowerCase().contains(t),
          orElse: () => {},
        );
        if (found.isEmpty) throw Exception('not found');
        return '${found['q'] ?? ''}${(found['a'] != null && found['a'].toString().isNotEmpty) ? ' — ${found['a']}' : ''}';
      },
    ];

    for (final p in providers) {
      try {
        final r = await p();
        if (r.isNotEmpty) return r;
      } catch (_) {}
    }

    // fallback curated list for common themes
    final curated = <String, List<String>>{
      'goals': [
        'A goal without a plan is just a wish. — Antoine de Saint-Exupéry',
        'The secret of getting ahead is getting started. — Mark Twain',
        'Discipline is the bridge between goals and accomplishment. — Jim Rohn',
        'Small daily improvements are the key to staggering long-term results. — Unknown',
      ],
      'motivation': [
        'The only way to do great work is to love what you do. — Steve Jobs',
        'Start where you are. Use what you have. Do what you can. — Arthur Ashe',
        'It always seems impossible until it is done. — Nelson Mandela',
      ],
      'saving': [
        'Do not save what is left after spending, but spend what is left after saving. — Warren Buffett',
        'A penny saved is a penny earned. — Benjamin Franklin',
      ],
    };

    final list = curated[t] ?? curated.entries.expand((e) => e.value).toList();
    final idx = DateTime.now().millisecondsSinceEpoch % list.length;
    return list[idx];
  }
}