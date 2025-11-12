import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple Hugging Face Inference API client for text generation.
///
/// Usage:
///   final svc = HuggingFaceService();
///   svc.setApiKey('hf_xxx');
///   final out = await svc.generateSmartGoal('I want to better manage my time');
///
/// Notes:
/// - Default model is `google/flan-t5-small` (good for instruction-following and small budgets).
/// - You can pass another model name when calling `generateSmartGoal`.
/// - The service expects an API key stored via `setApiKey`. For production, keep the key in secure storage.
class HuggingFaceService {
  final http.Client _client;
  String? _apiKey;

  HuggingFaceService({http.Client? client}) : _client = client ?? http.Client();

  void setApiKey(String apiKey) => _apiKey = apiKey;

  Map<String, String> get _headers {
    if (_apiKey == null) throw StateError('Hugging Face API key not set. Call setApiKey(...) first.');
    return {
      'Authorization': 'Bearer ${_apiKey!}',
      'Content-Type': 'application/json',
    };
  }

  /// Generate a SMART-formulated goal from a free-text input.
  ///
  /// Parameters:
  /// - `input`: original user sentence, e.g. "I want to better manage my time"
  /// - `model`: HF model id (default: `google/flan-t5-small`)
  /// - `maxNewTokens`: max tokens to generate
  /// - `temperature`: sampling temperature
  ///
  /// Returns the raw text output from the model (trimmed).
  Future<String> generateSmartGoal(
    String input, {
    String model = 'google/flan-t5-small',
    int maxNewTokens = 128,
    double temperature = 0.2,
  }) async {
    final prompt = _buildPrompt(input);
    // New official endpoint per Hugging Face notice: use outer.huggingface.co/hf-inference
    // Example: POST https://outer.huggingface.co/hf-inference/models/{model}
    final uri = Uri.parse('https://outer.huggingface.co/hf-inference/models/$model');

    final body = jsonEncode({
      'inputs': prompt,
      'parameters': {
        'max_new_tokens': maxNewTokens,
        'temperature': temperature,
        'return_full_text': false,
      },
      // 'options': {'use_cache': false}, // optional
    });

    final res = await _client.post(uri, headers: _headers, body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      // HF Inference returns either a list of {generated_text: ...} or a plain string depending on model.
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0]['generated_text'] != null) {
          return (decoded[0]['generated_text'] as String).trim();
        }
        if (decoded is Map && decoded['generated_text'] != null) {
          return (decoded['generated_text'] as String).trim();
        }
      } catch (_) {
        // not JSON or unexpected shape, return raw body
      }
      return res.body.trim();
    }

    // Build a richer error message for diagnostics
    final status = res.statusCode;
    final bodyText = res.body;
    final headersText = res.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    var hint = '';
    if (status == 401 || status == 403) {
      hint = 'Authentication error: check your HF API key (401/403).';
    } else if (status == 404) {
      hint = 'Model not found (404) — check model id: $model';
    } else if (status == 503) {
      hint = 'Model unavailable or loading (503) — try again later or use a lighter model.';
    } else if (status == 410) {
      hint = 'Deprecated API endpoint (410). The old API is no longer supported; please use the new endpoint https://outer.huggingface.co/hf-inference/models/{model} or update your client.';
    }

    throw Exception('HuggingFace generation failed: status=$status\n$hint\nheaders:\n$headersText\nbody:\n$bodyText');
  }

  String _buildPrompt(String input) {
    // English prompt template to instruct the model to return a single SMART goal sentence.
    return '''Rewrite the following objective so that it is a SMART goal (Specific, Measurable, Achievable, Realistic, Time-bound).

Input: "$input"

Expected output: A single sentence starting with "SMART Goal:" followed by the reformulated objective in English (short and precise).
''';
  }

  void dispose() {
    _client.close();
  }
}
