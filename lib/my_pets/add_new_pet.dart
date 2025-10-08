// add_new_pet.dart
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_pet_info.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);

class AddNewPetPage extends StatefulWidget {
  const AddNewPetPage({super.key});

  @override
  State<AddNewPetPage> createState() => _AddNewPetPageState();
}

class _AddNewPetPageState extends State<AddNewPetPage> {
  final TextEditingController _petNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int _selectedPetType = -1; // -1 = none, 0 = dog, 1 = cat
  XFile? _pickedPhoto;
  Uint8List? _pickedBytes;

  @override
  void dispose() {
    _petNameController.dispose();
    super.dispose();
  }

  Future<void> _choosePhotoFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedPhoto = file;
          _pickedBytes = bytes;
        });
      } else {
        setState(() => _pickedPhoto = file);
      }
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      );

  Widget _divider() => const Divider(
        color: _mint,
        thickness: 1,
        height: 25,
      );

  void _goNext() {
    final name = _petNameController.text.trim();
    final hasPhoto = _pickedPhoto != null || _pickedBytes != null;

    if (name.isEmpty || _selectedPetType == -1 || !hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide name, photo, and select pet type.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPetInfoPage(
          petName: name,
          petType: _selectedPetType,
          pickedPhoto: _pickedPhoto,
          pickedBytes: _pickedBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add a new pet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Let's add your first pet, tell us about your friend",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // ===== WHITE MAIN AREA =====
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            const SizedBox(height: 20),
                            // PET NAME
                            _sectionTitle('I call my pet'),
                            SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _petNameController,
                                decoration: InputDecoration(
                                  hintText: "Your pet's name",
                                  filled: true,
                                  fillColor: const Color(0xFFF7F7FB),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _mint),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _mint),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            _divider(),

                            // PET PHOTO
                            _sectionTitle("My pet's best photo"),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: _choosePhotoFromGallery,
                              child: Container(
                                width: 360,
                                height: 320,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _mint, width: 1.2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _pickedPhoto != null || _pickedBytes != null
                                      ? (kIsWeb
                                          ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                                          : Image.file(File(_pickedPhoto!.path), fit: BoxFit.cover))
                                      : Center(
                                          child: Image.asset(
                                            'assets/upload.png',
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            _divider(),

                            // PET TYPE
                            _sectionTitle('My pet is'),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _PetTypeSelector(
                                  label: 'Dog',
                                  asset: 'assets/dog.png',
                                  selected: _selectedPetType == 0,
                                  onTap: () => setState(() => _selectedPetType = 0),
                                ),
                                const SizedBox(width: 40),
                                _PetTypeSelector(
                                  label: 'Cat',
                                  asset: 'assets/cat.png',
                                  selected: _selectedPetType == 1,
                                  onTap: () => setState(() => _selectedPetType = 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),

                    // ===== BOTTOM NAVIGATION =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Disabled "Previous" button (grayed out)
                          const Opacity(
                            opacity: 0.4,
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                color: _mint,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Progress Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              _Dot(active: true),
                              SizedBox(width: 8),
                              _Dot(),
                              SizedBox(width: 8),
                              _Dot(),
                            ],
                          ),

                          // "Next" button (clickable)
                          GestureDetector(
                            onTap: _goNext,
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                color: _mint,
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
}

// ===== SMALL HELPER WIDGETS =====

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? _mint : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PetTypeSelector extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  const _PetTypeSelector({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: selected ? Border.all(color: _mint, width: 3) : null,
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFDFFCF4), Color(0xFFF0FFF9)],
                    center: Alignment(-0.2, -0.2),
                  ),
                ),
                child: Center(child: Image.asset(asset, height: 36)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? _mintDark : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
