import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  static Future<String> getAIResponse(String userMessage) async {
    if (_apiKey.isEmpty) {
      return 'API key is missing. Please check your .env file.';
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
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
