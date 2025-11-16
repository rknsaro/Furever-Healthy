// lib/identify_breed.dart
// ignore_for_file: unused_field
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import 'data/pet_guide_data.dart';
import 'identify_breed_picker_io.dart'
    if (dart.library.html) 'identify_breed_picker_web.dart';
import 'models/pet_breed.dart';
import 'services/pet_guide_storage.dart';
import 'my_pets/edit_pet_info.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);
const _screenBg = Color(0xFFF6F8FB);
const _geminiApiKey = 'AIzaSyDhC2nuwO2mvDCAnVII_Q81oKItEqsvNW4';

class GeminiException implements Exception {
  final int? statusCode;
  final String message;

  const GeminiException({this.statusCode, required this.message});

  @override
  String toString() => message;
}

class IdentifyBreedScreen extends StatefulWidget {
  const IdentifyBreedScreen({super.key});

  @override
  State<IdentifyBreedScreen> createState() => _IdentifyBreedScreenState();
}

class _IdentifyBreedScreenState extends State<IdentifyBreedScreen> {
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  String? _selectedImageMimeType;
  bool _isIdentifying = false;

  GenerativeModel? _model;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await pickImageBytes();
      if (picked != null) {
        // Validate file type
        final fileName = picked.name.toLowerCase();
        if (!fileName.endsWith('.jpg') &&
            !fileName.endsWith('.jpeg') &&
            !fileName.endsWith('.png')) {
          _showAlert(
            'Invalid File Type',
            'Please upload only .jpg, .jpeg, or .png image files.',
          );
          return;
        }

        setState(() {
          _selectedImageBytes = picked.bytes;
          _selectedFileName = picked.name;
          _selectedImageMimeType = _inferMimeType(picked.name);
        });
      }
    } catch (e) {
      _showAlert('Failed to pick image', e.toString());
    }
  }

  void _retryUpload() {
    setState(() {
      _selectedImageBytes = null;
      _selectedFileName = null;
      _selectedImageMimeType = null;
    });
    _pickImage();
  }

  Future<void> _identifyBreed() async {
    if (_isIdentifying) return; // Prevent multiple calls
    
    if (_selectedImageBytes == null) {
      _showAlert(
        'Please upload an image',
        'Select a pet photo before identifying the breed.',
      );
      return;
    }

    setState(() => _isIdentifying = true);

    // Show loading spinner dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: _mintDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: _mint),
                SizedBox(width: 20),
                Text(
                  'Identifying breed...',
                  style: TextStyle(
                    color: _screenBg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 🔹 Ask Gemini to identify the animal type and breed
      final prompt = """
      Analyze this image and return a JSON object only in this format:

      {
        "animal_type": "cat or dog or other",
        "breed": "breed name or 'unknown'",
        "breed_group": "breed group (e.g., Sporting, Working, Toy, etc.)",
        "size": "size (e.g., Small, Medium, Large, Medium-large)",
        "life_span": "typical life span (e.g., 10-12 years)",
        "description": "brief 2-3 sentence description of this breed's temperament and traits",
        "characteristics": {
          "Friendliness": 85,
          "Trainability": 90,
          "Energy Level": 80,
          "Shedding": 70
        },
        "care_guide": {
          "nutrition": "detailed nutrition advice with specific dietary needs",
          "grooming": "detailed grooming requirements and frequency",
          "exercise": "detailed exercise needs and activity recommendations",
          "health": "common health issues and preventive care recommendations"
        }
      }

      Important: 
      - Characteristics values should be integers from 0-100
      - Provide accurate breed information based on the image
      - Be detailed in care_guide sections (at least 2-3 sentences each)
      Only output valid JSON.
      """;

      final responseText = kIsWeb
          ? await _generateResponseWeb(prompt)
          : await _generateResponseNonWeb(prompt);

      Navigator.of(context).pop(); // Close spinner

      final text = responseText.trim();
      if (text.isEmpty) {
        _showAlert('Error', 'No response received from the AI.');
        return;
      }

      // Clean and parse JSON safely
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      late final Map<String, dynamic> data;
      try {
        data = jsonDecode(cleaned);
      } catch (e) {
        _showAlert('Error', 'Invalid response format from AI.');
        return;
      }

      final animalType = (data['animal_type'] ?? '').toString().toLowerCase();
      if (animalType != 'cat' && animalType != 'dog') {
        _showAlert(
          'Upload Correct Pet',
          'This image appears to be a $animalType. Please upload a photo of a cat or dog for breed identification.',
        );
        return;
      }

      await _maybeUpdatePetGuide(animalType, data);

      // Prompt for pet name, then navigate to EditPetInfoPage
      if (context.mounted) {
        final breedName = data['breed'] ?? 'Unknown Breed';
        final petName = await _promptPetName(context, breedName);
        if (petName != null && petName.isNotEmpty && context.mounted) {
          final petType = animalType == 'dog' ? 0 : 1;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPetInfoPage(
                petName: petName,
                petType: petType,
                breedFromIdentification: data['breed'] ?? 'Unknown Breed',
                imageBytesFromIdentification: _selectedImageBytes!,
                isFromBreedIdentification: true,
              ),
            ),
          );
        }
      }
    } on GeminiException catch (e) {
      Navigator.of(context).pop();
      _showAlert('Error', e.message);
    } catch (e) {
      Navigator.of(context).pop();
      _showAlert('Error', e.toString());
    } finally {
      setState(() => _isIdentifying = false);
    }
  }

  Future<void> _maybeUpdatePetGuide(
    String animalTypeLower,
    Map<String, dynamic> data,
  ) async {
    final breedName = (data['breed'] ?? '').toString();
    if (breedName.isEmpty) {
      return;
    }

    final isDog = animalTypeLower == 'dog';
    final canonicalName = isDog
        ? resolveTopDogCanonicalName(breedName)
        : resolveTopCatCanonicalName(breedName);

    if (canonicalName == null) {
      return;
    }

    final petBreed = _petBreedFromData(
      canonicalName: canonicalName,
      animalTypeLower: animalTypeLower,
      data: data,
    );

    await PetGuideStorage.instance.saveBreedOverride(petBreed);
  }

  PetBreed _petBreedFromData({
    required String canonicalName,
    required String animalTypeLower,
    required Map<String, dynamic> data,
  }) {
    final characteristics = _extractMap(data['characteristics']);
    final careGuide = _extractMap(data['care_guide']);

    return PetBreed.fromMap({
      'name': canonicalName,
      'animalType': animalTypeLower == 'dog' ? 'Dog' : 'Cat',
      'breedGroup': data['breed_group'] ?? 'Unknown',
      'size': data['size'] ?? 'Unknown',
      'lifeSpan': data['life_span'] ?? 'Unknown',
      'description': data['description'] ?? '',
      'characteristics': characteristics,
      'careGuide': careGuide,
    });
  }

  Map<String, dynamic> _extractMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  String _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/jpeg';
  }

  Future<String> _generateResponseNonWeb(String prompt) async {
    final model = _model;
    if (model == null) {
      throw StateError('Gemini model not initialized for this platform.');
    }
    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart(_selectedImageMimeType ?? 'image/jpeg', _selectedImageBytes!),
      ]),
    ]);
    return response.text ?? '';
  }

  Future<String> _generateResponseWeb(String prompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    );

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': _selectedImageMimeType ?? 'image/jpeg',
                'data': base64Encode(_selectedImageBytes!),
              },
            },
          ],
        },
      ],
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _geminiApiKey,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message =
          'Gemini request failed with status ${response.statusCode}.';
      try {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        final errorData = error['error'] as Map<String, dynamic>?;
        final backendMessage = errorData?['message'] as String?;
        final status = errorData?['status'] as String?;
        if (status == 'UNAVAILABLE' || response.statusCode == 503) {
          message =
              'Gemini is temporarily overloaded. Please try again in a few moments.';
        } else if (backendMessage != null && backendMessage.isNotEmpty) {
          message = backendMessage;
        }
      } catch (_) {
        // Ignore JSON parsing issues and keep default message
      }
      throw GeminiException(statusCode: response.statusCode, message: message);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return '';
    }

    final parts =
        (candidates.first['content']?['parts'] as List<dynamic>?) ?? const [];
    final buffer = StringBuffer();
    for (final part in parts) {
      final text = part['text'] as String?;
      if (text != null) {
        buffer.write(text);
      }
    }
    return buffer.toString();
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptPetName(BuildContext context, String breedName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Pet Name',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _mint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _mint.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, color: _mint, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Your pet is a $breedName!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mintDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Enter your pet's name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop(name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _mint,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    bool shouldExit = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF112F15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Identification',
          style: TextStyle(
            color: Color(0xFFF6F8FB),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to go back? This will cancel the breed identification process.',
          style: TextStyle(color: Color(0xFFF6F8FB)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              shouldExit = false;
            },
            child: const Text(
              'No',
              style: TextStyle(
                color: Color(0xFFF6F8FB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              shouldExit = true;
            },
            child: const Text(
              'Yes',
              style: TextStyle(
                color: Color(0xFFF6F8FB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return shouldExit;
  }

  Widget _buildImageUploader() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF112F15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: (_selectedImageBytes == null && !_isIdentifying)
              ? _pickImage
              : null,
          borderRadius: BorderRadius.circular(12),
          child: _selectedImageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        'Error loading image',
                        style: TextStyle(color: Color(0xB3FFFFFF)),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: Colors.white70, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
          ),
          child: Icon(icon, size: 30, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6F994A), Color(0xFF112F15)],
            stops: [0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Back Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () async {
                        final shouldExit = await _showExitConfirmation();
                        if (shouldExit && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(child: Center(child: _buildImageUploader())),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      icon: Icons.refresh,
                      onPressed: _isIdentifying ? null : _retryUpload,
                    ),
                    _buildActionButton(
                      icon: Icons.check,
                      onPressed: _isIdentifying ? null : _identifyBreed,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
