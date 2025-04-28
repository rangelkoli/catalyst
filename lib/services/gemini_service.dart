import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey; // Your Gemini API key

  GeminiService(this.apiKey);

  Future<String?> generateText(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    } else {
      print('Gemini API error: \\${response.body}');
      return null;
    }
  }
}
