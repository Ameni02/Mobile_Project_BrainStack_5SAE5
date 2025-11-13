import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoService {
  static const String priceApiUrl = 'https://api.coingecko.com/api/v3/simple/price';
  static const String ohlcApiUrl = 'https://api.coingecko.com/api/v3/coins';

  /// Récupère les prix actuels
  static Future<Map<String, dynamic>> getCryptoPrices({
    required List<String> ids,
    required List<String> vsCurrencies,
  }) async {
    final url = Uri.parse(
      '$priceApiUrl?ids=${ids.join(',')}&vs_currencies=${vsCurrencies.join(',')}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch crypto prices');
    }
  }

  /// Récupère les données historiques pour le graphique (OHLC)
  static Future<List<Map<String, dynamic>>> getHistoricalData(
      String cryptoId, String vsCurrency, int days) async {
    final url = Uri.parse(
      '$ohlcApiUrl/$cryptoId/ohlc?vs_currency=$vsCurrency&days=$days',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => {
        'time': e[0],
        'open': e[1],
        'high': e[2],
        'low': e[3],
        'close': e[4],
      }).toList();
    } else {
      throw Exception('Failed to fetch historical data');
    }
  }
}
