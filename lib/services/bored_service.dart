import 'dart:convert';
import 'package:http/http.dart' as http;

class BoredService {
  Future<Map<String, dynamic>?> getSuggestion() async {
    final res = await http.get(Uri.parse("https://www.boredapi.com/api/activity"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }
}
