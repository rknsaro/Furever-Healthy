// lib/my_pets/almost_done.dart
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../home_page.dart';

const _mint = Color(0xFF6F994A);

class AlmostDoneScreen extends StatefulWidget {
  final String petName;
  final int petType; // 0 = dog, 1 = cat
  final String? breed;
  final int? gender; // 0 = male, 1 = female
  final DateTime? birthDate;
  final String? weight;
  final String? description;
  final XFile? pickedPhoto;
  final Uint8List? pickedBytes;

  const AlmostDoneScreen({
    super.key,
    required this.petName,
    required this.petType,
    this.breed,
    this.gender,
    this.birthDate,
    this.weight,
    this.description,
    this.pickedPhoto,
    this.pickedBytes,
  });

  @override
  State<AlmostDoneScreen> createState() => _AlmostDoneScreenState();
}

class _AlmostDoneScreenState extends State<AlmostDoneScreen> {
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Playful, Energetic and completely a sweetheart',
  );
  int? _isSpayedNeutered; // 0 for Yes, 1 for No
  bool _isSaving = false;
  final List<String> _medicalConcerns = [
    'Skin Allergies',
    'Ear Infections',
    'Digestive Issues',
    'Parasites',
    'Heart Disease',
    'Urinary Problems',
  ];
  final Set<String> _selectedConcerns = {};

  @override
  void initState() {
    super.initState();
    _isSpayedNeutered = 1; // Default to 'No' as per screenshot
    if (widget.description != null && widget.description!.isNotEmpty) {
      _descriptionController.text = widget.description!;
    }
    _descriptionController.addListener(() {
      setState(() {}); // Update character count
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 125,
              decoration: const BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Almost Done!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Let's add your first pet, tell us about your friend",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            // Pet Description
                            Text(
                              'Describe ${widget.petName}, what\'s he like?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: _mint, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _descriptionController,
                                maxLines: 4,
                                maxLength: 250,
                                decoration: InputDecoration(
                                  hintText:
                                      'Describe ${widget.petName}, what\'s he like?',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  counterText:
                                      '${_descriptionController.text.length}/250',
                                  counterStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Separator
                            Container(
                              height: 1,
                              color: Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                            ),

                            // Spayed or Neutered
                            Text(
                              'Is ${widget.petName} Spayed or Neutered?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _isSpayedNeutered = 0),
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: _isSpayedNeutered == 0
                                            ? _mint
                                            : Colors.white,
                                        border: Border.all(
                                          color: _mint,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Yes',
                                          style: TextStyle(
                                            color: _isSpayedNeutered == 0
                                                ? Colors.white
                                                : _mint,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _isSpayedNeutered = 1),
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: _isSpayedNeutered == 1
                                            ? _mint
                                            : Colors.white,
                                        border: Border.all(
                                          color: _mint,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No',
                                          style: TextStyle(
                                            color: _isSpayedNeutered == 1
                                                ? Colors.white
                                                : _mint,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Separator
                            Container(
                              height: 1,
                              color: Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                            ),

                            // Medical Concerns
                            Text(
                              'What ${widget.petName}\'s Medical Concerns?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _medicalConcerns.map((concern) {
                                final isSelected = _selectedConcerns.contains(
                                  concern,
                                );
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedConcerns.remove(concern);
                                      } else {
                                        _selectedConcerns.add(concern);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? _mint : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? _mint
                                            : Colors.grey.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      concern,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle add concern logic
                                  // You can add a dialog or bottom sheet here
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _mint,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  '+Add concern',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Navigation
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                color: _mint,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _dot(false),
                              const SizedBox(width: 8),
                              _dot(false),
                              const SizedBox(width: 8),
                              _dot(true),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _isSaving ? null : _saveAndNavigateToHome,
                            child: _isSaving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(_mint),
                                    ),
                                  )
                                : Text(
                                    'Done',
                                    style: TextStyle(
                                      color: _isSaving ? Colors.grey : _mint,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? _mint : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Future<void> _saveAndNavigateToHome() async {
    if (_isSaving) return; // Prevent multiple calls
    
    setState(() => _isSaving = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to save pet data')),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      String? imageUrl;
      String? storagePath;

      if (widget.pickedBytes != null || widget.pickedPhoto != null) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          storagePath = 'pet_images/${user.uid}/$timestamp.jpg';
          final storageRef = FirebaseStorage.instance.ref().child(storagePath);

          UploadTask? uploadTask;
          if (widget.pickedBytes != null) {
            uploadTask = storageRef.putData(
              widget.pickedBytes!,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else if (!kIsWeb && widget.pickedPhoto != null) {
            final file = File(widget.pickedPhoto!.path);
            uploadTask = storageRef.putFile(
              file,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else {
            storagePath = null;
            uploadTask = null;
          }

          if (uploadTask != null) {
            final snapshot = await uploadTask.whenComplete(() {});
            imageUrl = await snapshot.ref.getDownloadURL();
          }
        } catch (e) {
          print('Error uploading pet image: $e');
          storagePath = null;
        }
      }

      final gender = widget.gender == null
          ? 'Unknown'
          : (widget.gender == 0 ? 'Male' : 'Female');
      final species = widget.petType == 0 ? 'Dog' : 'Cat';

      // Prepare pet data
      final petData = {
        'userId': user.uid,
        'name': widget.petName,
        'breed': widget.breed ?? 'Unknown',
        'gender': gender,
        'speciesType': species,
        'weight': widget.weight ?? '',
        'spayedNeutered': _isSpayedNeutered == 0 ? 'Yes' : 'No',
        'medicalConcerns': _selectedConcerns.toList(),
        'description': _descriptionController.text.trim(),
        'imageAsset': 'assets/${widget.petType == 0 ? 'dog' : 'cat'}.png',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (widget.birthDate != null)
          'birthDate': Timestamp.fromDate(widget.birthDate!),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (storagePath != null) 'imageStoragePath': storagePath,
      };

      // Save to Firebase
      await FirebaseFirestore.instance.collection('petInfos').add(petData);

      // Show snackbar and navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All Set! Welcome to the family ${widget.petName}!'),
            backgroundColor: _mint,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to home page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving pet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
