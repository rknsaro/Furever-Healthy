// lib/identify_breed.dart
// ignore_for_file: unused_field
import 'dart:convert';
import 'dart:typed_data';
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'breed_detail_screen.dart';
import 'identify_breed_picker_io.dart'
    if (dart.library.html) 'identify_breed_picker_web.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);
const _screenBg = Color(0xFFF6F8FB);

class IdentifyBreedScreen extends StatefulWidget {
  const IdentifyBreedScreen({super.key});

  @override
  State<IdentifyBreedScreen> createState() => _IdentifyBreedScreenState();
}

class _IdentifyBreedScreenState extends State<IdentifyBreedScreen> {
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isIdentifying = false;

  final _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: 'AIzaSyCsFXMHJmZwB1nwvACe9sy2WV8HDxZLsAg', // Replace this
  );

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
    });
    _pickImage();
  }

  Future<void> _identifyBreed() async {
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

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', _selectedImageBytes!),
        ]),
      ]);

      Navigator.of(context).pop(); // Close spinner

      final text = response.text?.trim() ?? '';
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

      // Navigate to detailed breed screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BreedDetailScreen(
              imageBytes: _selectedImageBytes!,
              breed: data['breed'] ?? 'Unknown Breed',
              breedGroup: data['breed_group'] ?? 'Unknown',
              size: data['size'] ?? 'Unknown',
              lifeSpan: data['life_span'] ?? 'Unknown',
              description: data['description'] ?? 'No description available.',
              characteristics: Map<String, int>.from(
                (data['characteristics'] as Map<String, dynamic>?) ?? {},
              ),
              careGuide: Map<String, dynamic>.from(
                (data['care_guide'] as Map<String, dynamic>?) ?? {},
              ),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showAlert('Error', e.toString());
    } finally {
      setState(() => _isIdentifying = false);
    }
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
          onTap: (_selectedImageBytes == null) ? _pickImage : null,
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
    required VoidCallback onPressed,
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
                      onPressed: _retryUpload,
                    ),
                    _buildActionButton(
                      icon: Icons.check,
                      onPressed: _identifyBreed,
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
