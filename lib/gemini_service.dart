import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // ✅ Use the v1 endpoint and your supported model
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1';
  static String _model = 'gemini-2.5-flash'; // <-- updated model

  static Future<String> getAIResponse(String userMessage) async {
    if (_apiKey.isEmpty) {
      return 'API key is missing. Please check your .env file.';
    }

    final url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {
                  "text":
                      "You are a helpful veterinary assistant for a pet care app. Provide clear, concise, and friendly advice. Always recommend seeing a vet if symptoms are severe."
                },
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ??
            'Sorry, I could not understand your question.';
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error']['message'] ?? 'Unknown error';
        return 'Error: $errorMessage';
      }
    } catch (e) {
      return 'Something went wrong. Please try again later.';
    }
  }
}
