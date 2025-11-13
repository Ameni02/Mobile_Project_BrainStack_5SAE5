import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const String apiKey = '9bfb4c10d3594b0d82de0706f0fb377f';
  static const String baseUrl = 'https://newsapi.org/v2';

  /// Récupère les dernières actualités de la catégorie « business »
  static Future<List<dynamic>> fetchBusinessNews({String country = 'us'}) async {
    final url = Uri.parse('$baseUrl/top-headlines?country=$country&category=business&apiKey=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['articles'] as List<dynamic>;
    } else {
      throw Exception('Erreur récupération des news: ${response.statusCode}');
    }
  }

  /// Recherche des articles selon un mot‑clé
  static Future<List<dynamic>> searchNews(String query) async {
    final url = Uri.parse('$baseUrl/everything?q=$query&sortBy=publishedAt&apiKey=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['articles'] as List<dynamic>;
    } else {
      throw Exception('Erreur récupération des news: ${response.statusCode}');
    }
  }
}
