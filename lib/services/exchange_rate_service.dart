import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String apiKey = "79569758a929aab1152c4cfede161f8c";
  static const String baseUrl = "https://api.exchangerate.host";

  /// 🔹 Récupère le taux de change entre deux devises
  static Future<double?> getExchangeRate(String from, String to) async {
    final url = Uri.parse('$baseUrl/convert?from=$from&to=$to&amount=1&access_key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["result"] != null) {
          return data["result"].toDouble();
        } else {
          print("Erreur API: ${data["error"]}");
          return null;
        }
      } else {
        print("Erreur HTTP: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur lors du chargement du taux de change: $e");
      return null;
    }
  }

  /// 🔹 Convertit un montant d’une devise à une autre
  static Future<double?> convertCurrency(double amount, String from, String to) async {
    final url = Uri.parse('$baseUrl/convert?from=$from&to=$to&amount=$amount&access_key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["result"] != null) {
          return data["result"].toDouble();
        } else {
          print("Erreur API: ${data["error"]}");
          return null;
        }
      } else {
        print("Erreur HTTP: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur lors du chargement du taux de change: $e");
      return null;
    }
  }
}
