// lib/my_pets/edit_pet_info.dart
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);

class EditPetInfoPage extends StatefulWidget {
  final String petName;
  final int petType; // 0 = dog, 1 = cat
  final XFile? pickedPhoto;
  final Uint8List? pickedBytes;

  const EditPetInfoPage({
    super.key,
    required this.petName,
    required this.petType,
    this.pickedPhoto,
    this.pickedBytes,
  });

  @override
  State<EditPetInfoPage> createState() => _EditPetInfoPageState();
}

class _EditPetInfoPageState extends State<EditPetInfoPage> {
  int? _selectedGender; // 0 male, 1 female
  String? _selectedBreed;
  DateTime? _birthDate;
  File? _petImage;

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final List<String> _dogBreeds = [
    'Labrador Retriever',
    'Golden Retriever',
    'German Shepherd',
    'Pomeranian',
    'Beagle',
    'Bulldog',
    'Poodle',
    'Shih Tzu',
    'Chihuahua',
    'Siberian Husky',
    'Corgi',
  ];

  final List<String> _catBreeds = [
    'Persian',
    'Siamese',
    'Maine Coon',
    'Ragdoll',
    'British Shorthair',
    'Bengal',
    'Sphynx',
    'Abyssinian',
    'Scottish Fold',
    'Russian Blue',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _petImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petName = widget.petName;
    final breeds = widget.petType == 0 ? _dogBreeds : _catBreeds;

    // Prepare image provider
    ImageProvider? imageProvider;
    if (_petImage != null) {
      imageProvider = FileImage(_petImage!);
    } else if (widget.pickedBytes != null) {
      imageProvider = MemoryImage(widget.pickedBytes!);
    } else if (widget.pickedPhoto != null && !kIsWeb) {
      imageProvider = FileImage(File(widget.pickedPhoto!.path));
    }

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
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Edit Pet Info',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Let's add your first pet, tell us about your friend",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
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
                          children: [
                            const SizedBox(height: 24),

                            // Pet Photo
                            Center(
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _mint, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundColor: _mint,
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? const Icon(Icons.pets,
                                          color: Colors.white, size: 120)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Pet Name
                            Text(
                              "$petName is",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Gender
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _genderButton(0, Icons.male, "Male",
                                    _selectedGender == 0),
                                const SizedBox(width: 28),
                                _genderButton(1, Icons.female, "Female",
                                    _selectedGender == 1),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // Breed Selection (Dropdown + Identify Breed)
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F7FB),
                                      border: Border.all(color: _mint),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedBreed,
                                        hint: Text(
                                          "${petName}'s breed is",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        isExpanded: true,
                                        items: breeds
                                            .map((b) => DropdownMenuItem(
                                                  value: b,
                                                  child: Text(b),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedBreed = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              "Breed identification feature coming soon!"),
                                        ));
                                      },
                                      icon: const Icon(Icons.camera_alt_rounded,
                                          color: Colors.white, size: 18),
                                      label: const Text(
                                        "Identify Breed",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _mint,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Birth Date
                            GestureDetector(
                              onTap: _pickBirthDate,
                              child: AbsorbPointer(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: "$petName was born on",
                                    suffixIcon: const Icon(Icons.calendar_today,
                                        color: Colors.grey),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F7FB),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide:
                                          const BorderSide(color: _mint),
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: _birthDate == null
                                        ? ''
                                        : "${_birthDate!.day} ${_monthName(_birthDate!.month)} ${_birthDate!.year}",
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Height & Weight
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _heightController,
                                    decoration: InputDecoration(
                                      hintText: "Height",
                                      prefixIcon: const Icon(
                                          Icons.straighten_rounded,
                                          color: Colors.grey),
                                      suffixText: "cm",
                                      suffixStyle:
                                          const TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: const Color(0xFFF7F7FB),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(25),
                                        borderSide:
                                            const BorderSide(color: _mint),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _weightController,
                                    decoration: InputDecoration(
                                      hintText: "Weight",
                                      prefixIcon: const Icon(
                                          Icons.monitor_weight_rounded,
                                          color: Colors.grey),
                                      suffixText: "kg",
                                      suffixStyle:
                                          const TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: const Color(0xFFF7F7FB),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(25),
                                        borderSide:
                                            const BorderSide(color: _mint),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Navigation
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
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
                              _dot(true),
                              const SizedBox(width: 8),
                              _dot(false),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Pet info saved!')),
                              );
                            },
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

  Widget _genderButton(int value, IconData icon, String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: selected ? _mint : const Color(0xFFF1F1F1),
            child: Icon(
              icon,
              color: selected ? Colors.white : Colors.grey.shade700,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? _mintDark : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }
}
