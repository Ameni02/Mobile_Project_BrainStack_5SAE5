import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Simple wrapper around flutter_secure_storage for storing API keys and secrets.
class SecureStorageService {
  static const _hfKey = 'hf_api_key';
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> writeHfKey(String key) async {
    try {
      await _storage.write(key: _hfKey, value: key);
    } on MissingPluginException catch (_) {
      // Plugin not available on this platform (e.g., during some tests or unsupported runtime).
      // Fall back silently — the value can still be provided via --dart-define at runtime.
      // ignore: avoid_print
      print('flutter_secure_storage not available: write operation skipped');
    } on PlatformException catch (e) {
      // Log and rethrow if necessary
      // ignore: avoid_print
      print('secure storage write failed: ${e.message}');
      rethrow;
    }
  }

  /// Read HF key from secure storage; if not present, fall back to the compile-time
  /// environment variable HF_API_KEY passed via `--dart-define=HF_API_KEY=...`.
  Future<String?> readHfKey() async {
    try {
      final stored = await _storage.read(key: _hfKey);
      if (stored != null && stored.isNotEmpty) return stored;
    } on MissingPluginException catch (_) {
      // Plugin not available. Will fallback to compile-time env below.
      // ignore: avoid_print
      print('flutter_secure_storage not available: falling back to env var');
    } on PlatformException catch (e) {
      // Log and continue to fallback
      // ignore: avoid_print
      print('secure storage read failed: ${e.message}');
    }

    // Fallback: check compile-time environment variable. This allows local testing
    // without committing secrets. To provide the key when running locally:
    // flutter run --dart-define=HF_API_KEY=hf_xxx
    const envKey = String.fromEnvironment('HF_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) return envKey;

    // Final fallback: check for a local file at project root named `.hf_token`.
    // This file is intended for local development only. It should be added to .gitignore.
    try {
      final file = File('.hf_token');
      if (await file.exists()) {
        final contents = (await file.readAsString()).trim();
        if (contents.isNotEmpty) return contents;
      }
    } catch (e) {
      // ignore IO errors and continue returning null
      // ignore: avoid_print
      print('Unable to read .hf_token: $e');
    }

    return null;
  }

  Future<void> deleteHfKey() async {
    try {
      await _storage.delete(key: _hfKey);
    } on MissingPluginException catch (_) {
      // ignore
      // ignore: avoid_print
      print('flutter_secure_storage not available: delete skipped');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('secure storage delete failed: ${e.message}');
      rethrow;
    }
  }
}
