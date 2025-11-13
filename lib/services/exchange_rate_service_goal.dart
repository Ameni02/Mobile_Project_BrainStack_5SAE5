import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_helper.dart';

class ExchangeRateServiceGoal {
  /// Retourne le taux de conversion pour base->target (ex: TND -> EUR)
  static Future<double> fetchRate(String base, String target, {http.Client? client}) async {
    client ??= HttpHelper.createClient();
    final b = base.toUpperCase();
    final t = target.toUpperCase();

    final providers = <Future<double> Function()>[
      () async {
        final url = Uri.parse('https://api.exchangerate.host/latest?base=$b&symbols=$t');
        final res = await client!.get(url);
        if (res.statusCode != 200) throw Exception('exchangerate.host ${res.statusCode}');
        final map = json.decode(res.body) as Map<String, dynamic>;
        final rates = map['rates'] as Map<String, dynamic>?;
        if (rates == null || rates.isEmpty) throw Exception('no rates');
        if (rates.containsKey(t)) return (rates[t] as num).toDouble();
        return (rates.entries.first.value as num).toDouble();
      },
      () async {
        final url = Uri.parse('https://api.frankfurter.app/latest?from=$b&to=$t');
        final res = await client!.get(url);
        if (res.statusCode != 200) throw Exception('frankfurter ${res.statusCode}');
        final map = json.decode(res.body) as Map<String, dynamic>;
        final rates = map['rates'] as Map<String, dynamic>?;
        if (rates == null || rates.isEmpty) throw Exception('no rates');
        if (rates.containsKey(t)) return (rates[t] as num).toDouble();
        return (rates.entries.first.value as num).toDouble();
      },
      () async {
        final url = Uri.parse('https://open.er-api.com/v6/latest/$b');
        final res = await client!.get(url);
        if (res.statusCode != 200) throw Exception('er-api ${res.statusCode}');
        final map = json.decode(res.body) as Map<String, dynamic>;
        final rates = map['rates'] as Map<String, dynamic>?;
        if (rates == null || rates.isEmpty) throw Exception('no rates');
        if (rates.containsKey(t)) return (rates[t] as num).toDouble();
        return (rates.entries.first.value as num).toDouble();
      },
    ];

    Object? lastError;
    for (final p in providers) {
      try {
        final r = await p();
        return r;
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Exchange API failure: $lastError');
  }

  /// Convert [amount] from [from] currency to [to] currency using fetchRate
  static Future<double> convert(double amount, String from, String to, {http.Client? client}) async {
    if (from.toUpperCase() == to.toUpperCase()) return amount;
    final rate = await fetchRate(from, to, client: client);
    return amount * rate;
  }
}