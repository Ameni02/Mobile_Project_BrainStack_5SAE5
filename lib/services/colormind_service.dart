import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ColormindService {
  /// Récupère une palette de 5 couleurs depuis Colormind.
  /// [model] peut être "default" (par défaut) ou "ui".
  static Future<List<Color>> getPalette({String? model}) async {
    final response = await http.post(
      Uri.parse('http://colormind.io/api/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": model ?? "default",
        "input": ["N", "N", "N", "N", "N"],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final colors = data["result"] as List<dynamic>;
      return colors.map<Color>((rgb) {
        return Color.fromRGBO(rgb[0] as int, rgb[1] as int, rgb[2] as int, 1.0);
      }).toList(growable: false);
    } else {
      throw Exception("Erreur lors du chargement des couleurs de Colormind");
    }
  }
}

