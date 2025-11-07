import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Utility to create http.Client instances.
/// In production you should NOT set [allowBadCerts] to true.
class HttpHelper {
  static bool allowBadCerts = false;

  static http.Client createClient({http.Client? override}) {
    if (override != null) return override;
    if (!allowBadCerts) return http.Client();

    final ioc = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }
}
