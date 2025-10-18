import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaClient {
  final String baseUrl;
  final String model;

  OllamaClient({
    this.baseUrl = 'https://var-pale-flashers-requirement.trycloudflare.com',
    this.model = 'llama3.2-3b-instruct-q8_0:latest',
  });

  Future<String> generate(String prompt) async {
    final url = Uri.parse('$baseUrl/api/generate');
    final body = jsonEncode({
      "model": model,
      "prompt": prompt,
      "stream": false,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? '';
    } else {
      throw Exception('Ollama error ${response.statusCode}: ${response.body}');
    }
  }
}
