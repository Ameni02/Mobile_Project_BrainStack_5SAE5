import 'package:intl/intl.dart';
/// Configuration centralisée de la devise utilisée dans l'application.
class CurrencyConfig {
  static const String code = 'TND';
  static const String symbol = 'TND '; // espace pour séparation visuelle
}

String formatTnd(num value) {
  final fmt = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND ');
  return fmt.format(value);
}