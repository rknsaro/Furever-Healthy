import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _mint = Color(0xFF6F994A);

class EditPetProfilePage extends StatefulWidget {
  final String? petId;
  final String? petName;

  const EditPetProfilePage({super.key, this.petId, this.petName});

  @override
  State<EditPetProfilePage> createState() => _EditPetProfilePageState();
}

class _EditPetProfilePageState extends State<EditPetProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final List<String> _medicalConcerns = [];
  final ImagePicker _picker = ImagePicker();

  String? _gender;
  String? _speciesType;
  String? _spayedNeutered;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUploadingImage = false;
  bool _isDeleting = false;

  XFile? _pickedPhoto;
  Uint8List? _pickedBytes;
  String? _imageUrl;
  String? _imageAsset;
  String? _imageStoragePath;
  String? _petDocumentId;

  @override
  void initState() {
    super.initState();
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setDefaultValues();
        setState(() => _isLoadingData = false);
        return;
      }

      if (widget.petId != null) {
        final docRef = FirebaseFirestore.instance
            .collection('petInfos')
            .doc(widget.petId);
        final doc = await docRef.get();
        if (doc.exists && doc.data() != null) {
          _petDocumentId = doc.id;
          _populateFields(Map<String, dynamic>.from(doc.data()!));
        } else {
          _setDefaultValues();
        }
      } else {
        final petName = widget.petName ?? 'Spencer';
        final query = await FirebaseFirestore.instance
            .collection('petInfos')
            .where('userId', isEqualTo: user.uid)
            .where('name', isEqualTo: petName)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final docSnapshot = query.docs.first;
          _petDocumentId = docSnapshot.id;
          _populateFields(Map<String, dynamic>.from(docSnapshot.data()));
        } else {
          _setDefaultValues(petName);
        }
      }
    } catch (e) {
      print('Error loading pet data: $e');
      _setDefaultValues();
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  void _setDefaultValues([String? name]) {
    _nameController.text = name ?? 'Spencer';
    _breedController.text = 'Golden Retriever';
    _weightController.text = '12.5 kg';
    _gender = 'Male';
    _speciesType = 'Dog';
    _spayedNeutered = 'No';
    _medicalConcerns.clear();
    _medicalConcerns.add('Dental Diseases');
    _imageAsset = 'assets/spencer.jpeg';
    _imageUrl = null;
    _imageStoragePath = null;
    _petDocumentId = null;
  }

  void _populateFields(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _breedController.text = data['breed'] ?? '';
    _weightController.text = data['weight'] ?? '';
    _gender = data['gender'] ?? 'Male';
    _speciesType = data['speciesType'] ?? 'Dog';
    _spayedNeutered = data['spayedNeutered'] ?? 'No';
    if (data['medicalConcerns'] != null) {
      _medicalConcerns
        ..clear()
        ..addAll(List<String>.from(data['medicalConcerns']));
    }
    _imageUrl = data['imageUrl'] as String?;
    _imageAsset = data['imageAsset'] as String?;
    _imageStoragePath = data['imageStoragePath'] as String?;
  }

  Future<void> _pickNewPhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedPhoto = file;
          _pickedBytes = bytes;
        });
      } else {
        setState(() {
          _pickedPhoto = file;
          _pickedBytes = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildPlaceholderAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.white,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/dog.png',
        width: size * 0.6,
        height: size * 0.6,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildEditableAvatarContent(double size) {
    if (_pickedBytes != null) {
      return Image.memory(
        _pickedBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    if (_pickedPhoto != null && !kIsWeb) {
      return Image.file(
        File(_pickedPhoto!.path),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(
        _imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(size),
      );
    }

    if (_imageAsset != null && _imageAsset!.isNotEmpty) {
      return Image.asset(
        _imageAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(size),
      );
    }

    return _buildPlaceholderAvatar(size);
  }

  Future<void> _savePetData() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a pet name')));
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploadingImage = _pickedPhoto != null || _pickedBytes != null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? updatedImageUrl = _imageUrl;
      String? updatedImageStoragePath = _imageStoragePath;
      String? updatedImageAsset = _imageAsset;

      if (_pickedPhoto != null || _pickedBytes != null) {
        try {
          if (_imageStoragePath != null && _imageStoragePath!.isNotEmpty) {
            try {
              await FirebaseStorage.instance.ref(_imageStoragePath!).delete();
            } catch (e) {
              print('Failed to delete old image: $e');
            }
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final storagePath = 'pet_images/${user.uid}/$timestamp.jpg';
          final storageRef = FirebaseStorage.instance.ref(storagePath);

          UploadTask uploadTask;
          if (_pickedBytes != null) {
            uploadTask = storageRef.putData(
              _pickedBytes!,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else {
            final file = File(_pickedPhoto!.path);
            uploadTask = storageRef.putFile(
              file,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          }

          final snapshot = await uploadTask.whenComplete(() {});
          updatedImageUrl = await snapshot.ref.getDownloadURL();
          updatedImageStoragePath = storagePath;
          updatedImageAsset = null;
        } catch (e) {
          print('Error uploading new pet photo: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload photo: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }

      final petData = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'breed': _breedController.text.trim(),
        'gender': _gender ?? 'Male',
        'speciesType': _speciesType ?? 'Dog',
        'weight': _weightController.text.trim(),
        'spayedNeutered': _spayedNeutered ?? 'No',
        'medicalConcerns': _medicalConcerns,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (updatedImageUrl != null) {
        petData['imageUrl'] = updatedImageUrl;
      } else {
        petData.remove('imageUrl');
      }

      if (updatedImageStoragePath != null) {
        petData['imageStoragePath'] = updatedImageStoragePath;
      } else {
        petData.remove('imageStoragePath');
      }

      if (updatedImageAsset != null) {
        petData['imageAsset'] = updatedImageAsset;
      } else {
        petData['imageAsset'] = FieldValue.delete();
      }

      DocumentReference docRef;

      if (widget.petId != null) {
        // Update existing pet by ID
        docRef = FirebaseFirestore.instance
            .collection('petInfos')
            .doc(widget.petId);
        petData['petID'] = docRef.id;
        await docRef.update(petData);
        _petDocumentId = docRef.id;
        print('Updated pet with ID: ${widget.petId}');
      } else {
        // Check if pet with this name exists for this user
        final querySnapshot = await FirebaseFirestore.instance
            .collection('petInfos')
            .where('userId', isEqualTo: user.uid)
            .where('name', isEqualTo: _nameController.text.trim())
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Update existing pet
          docRef = querySnapshot.docs.first.reference;
          petData['petID'] = docRef.id;
          await docRef.update(petData);
          _petDocumentId = docRef.id;
          print('Updated existing pet: ${_nameController.text.trim()}');
        } else {
          // Create new pet
          petData['createdAt'] = FieldValue.serverTimestamp();
          docRef = FirebaseFirestore.instance.collection('petInfos').doc();
          petData['petID'] = docRef.id;
          await docRef.set(petData);
          _petDocumentId = docRef.id;
          print(
            'Created new pet: ${_nameController.text.trim()} with ID: ${docRef.id}',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _pickedPhoto = null;
        _pickedBytes = null;
        _imageUrl = updatedImageUrl;
        _imageStoragePath = updatedImageStoragePath;
        _imageAsset = updatedImageAsset;
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      print('Error saving pet data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving pet data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _confirmDeletePet() async {
    if (_petDocumentId == null && widget.petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pet to remove.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove pet'),
        content: const Text(
          'Are you sure you want to remove this pet permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePet();
    }
  }

  Future<void> _deletePet() async {
    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You need to be signed in to remove a pet.');
      }

      String? documentId = _petDocumentId ?? widget.petId;
      DocumentReference<Map<String, dynamic>>? docRef;

      if (documentId != null) {
        docRef = FirebaseFirestore.instance
            .collection('petInfos')
            .doc(documentId);
        final doc = await docRef.get();
        if (!doc.exists) {
          docRef = null;
        }
      }

      if (docRef == null) {
        final query = await FirebaseFirestore.instance
            .collection('petInfos')
            .where('userId', isEqualTo: user.uid)
            .where('name', isEqualTo: _nameController.text.trim())
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          docRef = query.docs.first.reference;
        }
      }

      if (docRef == null) {
        throw Exception('Could not find this pet in the database.');
      }

      if (_imageStoragePath != null && _imageStoragePath!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(_imageStoragePath!).delete();
        } catch (e) {
          print('Failed to delete image from storage: $e');
        }
      }

      await docRef.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet removed successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Error deleting pet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove pet: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _toggleGender() {
    setState(() {
      _gender = _gender == 'Male' ? 'Female' : 'Male';
    });
  }

  void _toggleSpeciesType() {
    setState(() {
      _speciesType = _speciesType == 'Dog' ? 'Cat' : 'Dog';
    });
  }

  void _toggleSpayedNeutered() {
    setState(() {
      _spayedNeutered = _spayedNeutered == 'Yes' ? 'No' : 'Yes';
    });
  }

  void _showAddConcernDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Medical Concern'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter medical concern',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _mint),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _medicalConcerns.add(controller.text.trim()));
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: _mint,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _mint,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Edit Pet Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: _mint.withOpacity(0.2),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: _buildEditableAvatarContent(112),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                        style: IconButton.styleFrom(backgroundColor: _mint),
                        onPressed: _pickNewPhoto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isUploadingImage) ...[
              const SizedBox(height: 10),
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_mint),
              ),
            ],
            const SizedBox(height: 24),

            _buildSection('Basic information', [
              _buildTextFieldWithCounter(
                label: 'Name',
                controller: _nameController,
                maxLength: 120,
              ),
              const SizedBox(height: 16),
              _buildSelectableField('Gender', _gender ?? 'Male', _toggleGender),
              const SizedBox(height: 16),
              _buildTextField(label: 'Weight', controller: _weightController),
            ]),

            const SizedBox(height: 24),

            _buildSection('Species', [
              _buildSelectableField(
                'Type',
                _speciesType ?? 'Dog',
                _toggleSpeciesType,
              ),
              const SizedBox(height: 16),
              _buildTextFieldWithCounter(
                label: 'Breed',
                controller: _breedController,
                maxLength: 120,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Other Info', [
              _buildSelectableField(
                'Spayed or Neutered?',
                _spayedNeutered ?? 'No',
                _toggleSpayedNeutered,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Medical Concerns', [
              Wrap(
                spacing: 8,
                // runSpacing: 8,
                children: [
                  ..._medicalConcerns.map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(c, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddConcernDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Add concern',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mint,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _savePetData,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isDeleting ? null : _confirmDeletePet,
                child: _isDeleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.redAccent,
                          ),
                        ),
                      )
                    : const Text(
                        'Remove pet',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSelectableField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _mint),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithCounter({
    required String label,
    required TextEditingController controller,
    required int maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            Text(
              '${controller.text.length}/$maxLength',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _mint),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
