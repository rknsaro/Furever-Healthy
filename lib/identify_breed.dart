// lib/identify_breed.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// conditional import: picks the web implementation when building for web,
// and the IO implementation otherwise.
import 'identify_breed_picker_io.dart'
    if (dart.library.html) 'identify_breed_picker_web.dart';

class IdentifyBreedScreen extends StatefulWidget {
  const IdentifyBreedScreen({super.key});

  @override
  State<IdentifyBreedScreen> createState() => _IdentifyBreedScreenState();
}

class _IdentifyBreedScreenState extends State<IdentifyBreedScreen> {
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isIdentifying = false;

  Future<void> _pickImage() async {
    try {
      final picked = await pickImageBytes();
      if (picked != null) {
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
      _showAlert('Please upload an image', 'Select a pet photo before identifying the breed.');
      return;
    }

    setState(() => _isIdentifying = true);

    // Show loading dialog (non-dismissible)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  color: Color(0xFF6F994A), // spinner color
                ),
                SizedBox(width: 20),
                Text('Identifying breed...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Simulated delay — replace with actual API call later
      await Future.delayed(const Duration(seconds: 2));

      final fileNameDisplay = _selectedFileName ?? 'selected image';
      Navigator.of(context).pop(); // close spinner
      _showAlert('Breed Identified',
          'Simulated result for $fileNameDisplay\n(Replace with real API result.)');
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
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF112F15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Identification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to go back? This will cancel the breed identification process.',
          style: TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              shouldExit = false;
            },
            child: const Text(
              'Stay',
              style: TextStyle(
                color: Color(0xFFB0DDA2),
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
              'Exit',
              style: TextStyle(
                color: Colors.redAccent,
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
          color: const Color(0xFF2E4133),
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
                        style: TextStyle(color: Colors.white70),
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

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed}) {
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
                // Header: Back Button + Centered Title
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
                    // const Expanded(
                    //   child: Center(
                    //     child: Text(
                    //       'Identify Pet Breed',
                    //       style: TextStyle(
                    //         color: Colors.white,
                    //         fontSize: 20,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(width: 48), // Spacer to balance back button
                  ],
                ),
                const SizedBox(height: 16),

                // Image uploader
                Expanded(child: Center(child: _buildImageUploader())),
                const SizedBox(height: 30),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(icon: Icons.refresh, onPressed: _retryUpload),
                    _buildActionButton(icon: Icons.check, onPressed: _identifyBreed),
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
