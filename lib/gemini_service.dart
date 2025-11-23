import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // ✅ Use the v1 endpoint and your supported model
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1';
  static final String _model = 'gemini-2.5-flash'; // <-- updated model

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
                      "You are a helpful veterinary assistant for a pet care app. Provide clear, concise, and friendly advice. Always recommend seeing a vet if symptoms are severe.",
                },
                {"text": userMessage},
              ],
            },
          ],
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

  /// Fetches breed information from Gemini API
  /// Returns a JSON string with breed details
  static Future<String> getBreedInformation(String breedName) async {
    if (_apiKey.isEmpty) {
      throw Exception('API key is missing. Please check your .env file.');
    }

    final url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';

    // Check if breed name indicates mixed breed
    final breedLower = breedName.toLowerCase();
    final isMixedBreed =
        breedLower.contains('mixed') ||
        breedLower.contains('mix') ||
        breedLower.contains('mutt') ||
        breedLower == 'aspin' ||
        breedLower == 'puspin' ||
        breedLower.contains('domestic shorthair') ||
        breedLower.contains('domestic longhair');

    final prompt =
        """
      Provide detailed information about the pet breed "$breedName". 
      Return ONLY a valid JSON object in this exact format (no markdown, no code blocks, just JSON):

      {
        "animal_type": "cat or dog",
        "breed_group": "${isMixedBreed ? 'Mixed' : 'breed group (e.g., Sporting, Working, Toy, etc. For cats, use specific breed group or Mixed)'}",
        "size": "size category (e.g., Small, Medium, Large, Medium-Large. For cats, use Small, Medium, or Large)",
        "life_span": "typical life span range (e.g., 12-15 years, 10-14 years)",
        "description": "brief 2-3 sentence description of this breed's temperament, traits, and characteristics",
        "characteristics": {
          "Friendliness": 85,
          "Trainability": 90,
          "Energy Level": 80,
          "Shedding": 70,
          "Grooming Needs": 60,
          "Exercise Needs": 75
        },
        "care_guide": {
          "nutrition": "detailed nutrition advice with specific dietary needs, feeding frequency, and food recommendations (at least 3-4 sentences)",
          "grooming": "detailed grooming requirements, frequency, and specific care instructions (at least 3-4 sentences)",
          "exercise": "detailed exercise needs, activity recommendations, and play requirements (at least 3-4 sentences)",
          "health": "common health issues, preventive care recommendations, and health monitoring tips (at least 3-4 sentences)"
        }
      }

      Important: 
      - Characteristics values should be integers from 0-100
      - Provide accurate and detailed information
      - If the breed is a mixed breed, use "Mixed" for breed_group (NOT "Unknown")
      - For mixed breeds, provide general information appropriate for that type of pet
      - Only output valid JSON, no additional text
    """;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] ?? '';

        // Clean the response (remove markdown code blocks if present)
        String cleaned = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        // Try to parse to validate it's valid JSON
        jsonDecode(cleaned);

        return cleaned;
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error']['message'] ?? 'Unknown error';
        throw Exception('Error: $errorMessage');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON response from AI. Please try again.');
      }
      rethrow;
    }
  }
}
