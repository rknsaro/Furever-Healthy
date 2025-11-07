import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _mint = Color(0xFF6F994A);

class EditPetProfilePage extends StatefulWidget {
  final String? petId; // Optional pet ID for editing existing pet
  final String? petName; // Optional pet name for editing existing pet

  const EditPetProfilePage({super.key, this.petId, this.petName});

  @override
  State<EditPetProfilePage> createState() => _EditPetProfilePageState();
}

class _EditPetProfilePageState extends State<EditPetProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final List<String> _medicalConcerns = [];

  String? _gender; // 'Male' or 'Female'
  String? _speciesType; // 'Cat' or 'Dog'
  String? _spayedNeutered; // 'Yes' or 'No'
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Set default values if no user
        _setDefaultValues();
        setState(() => _isLoadingData = false);
        return;
      }

      QuerySnapshot? querySnapshot;
      if (widget.petId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('petInfos')
            .doc(widget.petId)
            .get();
        if (doc.exists) {
          final docData = doc.data();
          if (docData != null) {
            _populateFields(Map<String, dynamic>.from(docData));
          } else {
            _setDefaultValues();
          }
        } else {
          _setDefaultValues();
        }
      } else {
        // Try to find pet by name, or default to Spencer
        final petName = widget.petName ?? 'Spencer';
        querySnapshot = await FirebaseFirestore.instance
            .collection('petInfos')
            .where('userId', isEqualTo: user.uid)
            .where('name', isEqualTo: petName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docData = querySnapshot.docs.first.data();
          if (docData != null && docData is Map) {
            _populateFields(Map<String, dynamic>.from(docData));
          } else {
            _setDefaultValues(petName);
          }
        } else {
          // No pet found, use default values
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
  }

  void _populateFields(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _breedController.text = data['breed'] ?? '';
    _weightController.text = data['weight'] ?? '';
    _gender = data['gender'] ?? 'Male';
    _speciesType = data['speciesType'] ?? 'Dog';
    _spayedNeutered = data['spayedNeutered'] ?? 'No';
    if (data['medicalConcerns'] != null) {
      _medicalConcerns.clear();
      _medicalConcerns.addAll(List<String>.from(data['medicalConcerns']));
    }
  }

  Future<void> _savePetData() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a pet name')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to save pet data')),
          );
        }
        return;
      }

      final petName = _nameController.text.trim();
      final petData = {
        'userId': user.uid,
        'name': petName,
        'breed': _breedController.text.trim(),
        'gender': _gender ?? 'Male',
        'speciesType': _speciesType ?? 'Dog',
        'weight': _weightController.text.trim(),
        'spayedNeutered': _spayedNeutered ?? 'No',
        'medicalConcerns': _medicalConcerns,
        'imageAsset': 'assets/spencer.jpeg', // Using spencer.jpeg as specified
        'updatedAt': FieldValue.serverTimestamp(),
      };

      DocumentReference docRef;

      if (widget.petId != null) {
        // Update existing pet by ID
        docRef = FirebaseFirestore.instance
            .collection('petInfos')
            .doc(widget.petId);
        await docRef.update(petData);
        print('Updated pet with ID: ${widget.petId}');
      } else {
        // Check if pet with this name exists for this user
        final querySnapshot = await FirebaseFirestore.instance
            .collection('petInfos')
            .where('userId', isEqualTo: user.uid)
            .where('name', isEqualTo: petName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Update existing pet
          docRef = querySnapshot.docs.first.reference;
          await docRef.update(petData);
          print('Updated existing pet: $petName');
        } else {
          // Create new pet
          petData['createdAt'] = FieldValue.serverTimestamp();
          docRef = await FirebaseFirestore.instance
              .collection('petInfos')
              .add(petData);
          print('Created new pet: $petName with ID: ${docRef.id}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removePet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Remove Pet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to remove this pet? This action cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        if (widget.petId != null) {
          await FirebaseFirestore.instance
              .collection('petInfos')
              .doc(widget.petId)
              .delete();
        } else if (widget.petName != null) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('petInfos')
              .where('userId', isEqualTo: user.uid)
              .where('name', isEqualTo: widget.petName)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            await querySnapshot.docs.first.reference.delete();
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing pet: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Male'),
              leading: Radio<String>(
                value: 'Male',
                groupValue: _gender,
                onChanged: (value) {
                  setState(() => _gender = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Female'),
              leading: Radio<String>(
                value: 'Female',
                groupValue: _gender,
                onChanged: (value) {
                  setState(() => _gender = value);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeciesPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Cat'),
              leading: Radio<String>(
                value: 'Cat',
                groupValue: _speciesType,
                onChanged: (value) {
                  setState(() => _speciesType = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Dog'),
              leading: Radio<String>(
                value: 'Dog',
                groupValue: _speciesType,
                onChanged: (value) {
                  setState(() => _speciesType = value);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpayedNeuteredPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Yes'),
              leading: Radio<String>(
                value: 'Yes',
                groupValue: _spayedNeutered,
                onChanged: (value) {
                  setState(() => _spayedNeutered = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('No'),
              leading: Radio<String>(
                value: 'No',
                groupValue: _spayedNeutered,
                onChanged: (value) {
                  setState(() => _spayedNeutered = value);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _medicalConcerns.add(controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _mint,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: _mint,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _mint,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Pet Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Pet Profile Image
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _mint, width: 3),
                ),
                child: ClipOval(
                  child: Image.asset('assets/spencer.jpeg', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Basic information
            _buildSection('Basic information', [
              _buildTextFieldWithCounter(
                label: 'Name',
                controller: _nameController,
                maxLength: 120,
              ),
              const SizedBox(height: 16),
              _buildSelectableField(
                label: 'Gender',
                value: _gender ?? 'Male',
                onTap: _showGenderPicker,
              ),
              const SizedBox(height: 16),
              _buildTextField(label: 'Weight', controller: _weightController),
            ]),

            const SizedBox(height: 24),

            // Species
            _buildSection('Species', [
              _buildSelectableField(
                label: 'Type',
                value: _speciesType ?? 'Dog',
                onTap: _showSpeciesPicker,
              ),
              const SizedBox(height: 16),
              _buildTextFieldWithCounter(
                label: 'Breed',
                controller: _breedController,
                maxLength: 120,
              ),
            ]),

            const SizedBox(height: 24),

            // Other info
            _buildSection('Other info', [
              _buildSelectableField(
                label: 'Spayed or Neutered?',
                value: _spayedNeutered ?? 'No',
                onTap: _showSpayedNeuteredPicker,
              ),
            ]),

            const SizedBox(height: 24),

            // Medical Concerns
            _buildSection('Medical Concerns', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._medicalConcerns.map(
                    (concern) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        concern,
                        style: const TextStyle(fontSize: 14),
                      ),
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

            // Save Changes Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePetData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mint,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Remove pet
            Center(
              child: TextButton(
                onPressed: _removePet,
                child: const Text(
                  'Remove pet',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),
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
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
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
            counterText: '',
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildSelectableField({
    required String label,
    required String value,
    required VoidCallback onTap,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
