import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// A lightweight HTTP client for talking to your local or remote Ollama server.
class OllamaClient {
  final String baseUrl;
  final String model;

  OllamaClient({
    this.baseUrl = 'https://13-234-225-48.sslip.io',
    this.model = 'llama3.2-3b-instruct-q8_0:latest',
  });

  Future<String> generate(String prompt) async {
    final url = Uri.parse('$baseUrl/api/generate');
    final body = jsonEncode({
      "model": model,
      "prompt": prompt,
      "stream": false,
    });

    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']?.toString().trim() ?? '';
      } else {
        throw Exception(
            '⚠️ Server responded with ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('⏱️ Request timed out. Please check your connection.');
    } catch (e) {
      throw Exception('❌ Ollama request failed: $e');
    }
  }
}
