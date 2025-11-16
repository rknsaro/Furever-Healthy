// lib/my_pets/edit_pet_info.dart
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../identify_breed.dart';
import '../home_page.dart';
import 'almost_done.dart';

const _mint = Color(0xFF6F994A);

class EditPetInfoPage extends StatefulWidget {
  final String petName;
  final int petType; // 0 = dog, 1 = cat
  final XFile? pickedPhoto;
  final Uint8List? pickedBytes;
  final String? breedFromIdentification;
  final Uint8List? imageBytesFromIdentification;
  final bool isFromBreedIdentification;

  const EditPetInfoPage({
    super.key,
    required this.petName,
    required this.petType,
    this.pickedPhoto,
    this.pickedBytes,
    this.breedFromIdentification,
    this.imageBytesFromIdentification,
    this.isFromBreedIdentification = false,
  });

  @override
  State<EditPetInfoPage> createState() => _EditPetInfoPageState();
}

class _EditPetInfoPageState extends State<EditPetInfoPage> {
  int? _selectedGender; // 0 male, 1 female
  String? _selectedBreed;
  DateTime? _birthDate;
  bool _isSaving = false;

  final TextEditingController _weightController = TextEditingController();

  final List<String> _dogBreeds = [
    'Adopted',
    'Afador',
    'Affenhuahua',
    'Affenpinscher',
    'Afghan Hound',
    'Aidi (Aïdi) (Atlas Mountain Dog)',
    'Airedale Terrier',
    'Akbash',
    'Akita',
    'Akita Chow',
    'Akita Inu',
    'Akita Pitbull',
    'Akita Shepherd',
    'Alapaha Blue-Blood Bulldog',
    'Alaskan Husky',
    'Alaskan Klee Kai',
    'Alaskan Malamute',
    'American Bulldog',
    'American Bully',
    'American Eskimo Dog',
    'American Foxhound',
    'American Pit Bull Terrier',
    'American Staffordshire Terrier',
    'American Water Spaniel',
    'Anatolian Shepherd Dog',
    'Australian Cattle Dog',
    'Australian Kelpie',
    'Australian Shepherd',
    'Australian Terrier',
    'Basenji',
    'Basset Hound',
    'Beagle',
    'Bearded Collie',
    'Beauceron',
    'Bedlington Terrier',
    'Belgian Malinois',
    'Belgian Shepherd',
    'Belgian Tervuren',
    'Bernese Mountain Dog',
    'Bichon Frise',
    'Black and Tan Coonhound',
    'Black Russian Terrier',
    'Bloodhound',
    'Blue Lacy',
    'Bluetick Coonhound',
    'Border Collie',
    'Border Terrier',
    'Borzoi',
    'Boston Terrier',
    'Bouvier des Flandres',
    'Boxer',
    'Boykin Spaniel',
    'Brittany',
    'Brussels Griffon',
    'Bull Terrier',
    'Bulldog',
    'Bullmastiff',
    'Cane Corso',
    'Cardigan Welsh Corgi',
    'Catahoula Leopard Dog',
    'Cavalier King Charles Spaniel',
    'Chesapeake Bay Retriever',
    'Chihuahua',
    'Chinese Crested',
    'Chinese Shar-Pei',
    'Chinook',
    'Chow Chow',
    'Clumber Spaniel',
    'Cockapoo',
    'Cocker Spaniel',
    'Collie',
    'Coonhound',
    'Corgi',
    'Curly-Coated Retriever',
    'Dachshund',
    'Dalmatian',
    'Doberman Pinscher',
    'Dogo Argentino',
    'Dutch Shepherd',
    'English Bulldog',
    'English Cocker Spaniel',
    'English Pointer',
    'English Setter',
    'English Springer Spaniel',
    'English Toy Spaniel',
    'Field Spaniel',
    'Finnish Lapphund',
    'Finnish Spitz',
    'French Bulldog',
    'German Pinscher',
    'German Shepherd',
    'German Shorthaired Pointer',
    'German Wirehaired Pointer',
    'Giant Schnauzer',
    'Glen of Imaal Terrier',
    'Golden Retriever',
    'Gordon Setter',
    'Great Dane',
    'Great Pyrenees',
    'Greater Swiss Mountain Dog',
    'Greyhound',
    'Harrier',
    'Havanese',
    'Husky',
    'Ibizan Hound',
    'Icelandic Sheepdog',
    'Irish Red and White Setter',
    'Irish Setter',
    'Irish Terrier',
    'Irish Water Spaniel',
    'Irish Wolfhound',
    'Italian Greyhound',
    'Jack Russell Terrier',
    'Japanese Chin',
    'Keeshond',
    'Kerry Blue Terrier',
    'Kuvasz',
    'Labrador Retriever',
    'Lagotto Romagnolo',
    'Lakeland Terrier',
    'Leonberger',
    'Lhasa Apso',
    'Maltese',
    'Mastiff',
    'Miniature Bull Terrier',
    'Miniature Pinscher',
    'Miniature Schnauzer',
    'Newfoundland',
    'Norfolk Terrier',
    'Norwegian Buhund',
    'Norwegian Elkhound',
    'Norwich Terrier',
    'Nova Scotia Duck Tolling Retriever',
    'Old English Sheepdog',
    'Otterhound',
    'Papillon',
    'Parson Russell Terrier',
    'Pekingese',
    'Pembroke Welsh Corgi',
    'Petit Basset Griffon Vendeen',
    'Pharaoh Hound',
    'Pit Bull',
    'Plott',
    'Pointer',
    'Polish Lowland Sheepdog',
    'Pomeranian',
    'Poodle',
    'Portuguese Water Dog',
    'Pug',
    'Puli',
    'Pumi',
    'Rat Terrier',
    'Redbone Coonhound',
    'Rhodesian Ridgeback',
    'Rottweiler',
    'Saint Bernard',
    'Saluki',
    'Samoyed',
    'Schipperke',
    'Schnauzer',
    'Scottish Deerhound',
    'Scottish Terrier',
    'Sealyham Terrier',
    'Shetland Sheepdog',
    'Shiba Inu',
    'Shih Tzu',
    'Siberian Husky',
    'Silky Terrier',
    'Smooth Fox Terrier',
    'Soft Coated Wheaten Terrier',
    'Spinone Italiano',
    'Staffordshire Bull Terrier',
    'Standard Schnauzer',
    'Sussex Spaniel',
    'Swedish Vallhund',
    'Tibetan Mastiff',
    'Tibetan Spaniel',
    'Tibetan Terrier',
    'Toy Fox Terrier',
    'Treeing Walker Coonhound',
    'Vizsla',
    'Weimaraner',
    'Welsh Springer Spaniel',
    'Welsh Terrier',
    'West Highland White Terrier',
    'Whippet',
    'Wire Fox Terrier',
    'Wirehaired Pointing Griffon',
    'Xoloitzcuintli',
    'Yorkshire Terrier',
    'Aspin',
    'Mixed Breed',
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
    'American Shorthair',
    'Turkish Angora',
    'Norwegian Forest Cat',
    'Exotic Shorthair',
    'Oriental Shorthair',
    'Devon Rex',
    'Cornish Rex',
    'Manx',
    'Himalayan',
    'Burmese',
    'Egyptian Mau',
    'Somali',
    'Birman',
    'Tonkinese',
    'Puspin',
    'Philippine Shorthair',
    'Mixed Breed',
  ];

  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _breedSearchController = TextEditingController();
  final FocusNode _breedFocusNode = FocusNode();

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _mint,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _navigateToIdentifyBreed() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const IdentifyBreedScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedBreed = result;
        _breedController.text = result;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isFromBreedIdentification && widget.breedFromIdentification != null) {
      _selectedBreed = widget.breedFromIdentification;
      _breedController.text = widget.breedFromIdentification!;
    } else if (_selectedBreed != null) {
      _breedController.text = _selectedBreed!;
    }
  }

  @override
  void dispose() {
    _breedController.dispose();
    _breedSearchController.dispose();
    _weightController.dispose();
    _breedFocusNode.dispose();
    super.dispose();
  }

  void _showBreedModal(BuildContext context, List<String> breeds) {
    _breedSearchController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _BreedModalContent(
          breeds: breeds,
          searchController: _breedSearchController,
          onBreedSelected: (String breed) {
            setState(() {
              _selectedBreed = breed;
              _breedController.text = breed;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final petName = widget.petName;
    final breeds = widget.petType == 0 ? _dogBreeds : _catBreeds;

    // Prepare image provider
    ImageProvider? imageProvider;
    if (widget.isFromBreedIdentification && widget.imageBytesFromIdentification != null) {
      imageProvider = MemoryImage(widget.imageBytesFromIdentification!);
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
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 18,
                      ),
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
                                      ? const Icon(
                                          Icons.pets,
                                          color: Colors.white,
                                          size: 120,
                                        )
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
                                _genderButton(
                                  0,
                                  Icons.male,
                                  "Male",
                                  _selectedGender == 0,
                                ),
                                const SizedBox(width: 28),
                                _genderButton(
                                  1,
                                  Icons.female,
                                  "Female",
                                  _selectedGender == 1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // Species and Breed Selection (Side by Side)
                            Row(
                              children: [
                                // Pet Species
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _mint.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: _mint.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.petType == 0
                                            ? Icons.pets
                                            : Icons.cruelty_free,
                                        color: _mint,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.petType == 0 ? 'Dog' : 'Cat',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _mint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Breed Selection
                                Expanded(
                                  child: GestureDetector(
                                    onTap: widget.isFromBreedIdentification
                                        ? null
                                        : () => _showBreedModal(context, breeds),
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: widget.isFromBreedIdentification
                                            ? Colors.grey.shade200
                                            : Colors.white,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _breedController.text.isEmpty
                                                  ? "Breed"
                                                  : _breedController.text,
                                              style: TextStyle(
                                                color:
                                                    _breedController
                                                        .text
                                                        .isEmpty
                                                    ? Colors.black54
                                                    : Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!widget.isFromBreedIdentification)
                                            const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Colors.grey,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (!widget.isFromBreedIdentification) ...[
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: _navigateToIdentifyBreed,
                                      icon: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        "Identify",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _mint,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Separator
                            Container(
                              height: 1,
                              color: Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(vertical: 20),
                            ),

                            // Birth Date Label
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "$petName was born on",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Birth Date
                            GestureDetector(
                              onTap: _pickBirthDate,
                              child: AbsorbPointer(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: "7/11/25",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      color: _mint,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: _birthDate == null
                                        ? ''
                                        : "${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year % 100}",
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Weight Label
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "$petName's weight",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Weight
                            TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Weight",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                suffixIcon: Icon(
                                  Icons.monitor_weight_rounded,
                                  color: _mint,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
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
                              _dot(true),
                              const SizedBox(width: 8),
                              _dot(false),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _isSaving
                                ? null
                                : (widget.isFromBreedIdentification
                                    ? _savePetDirectly
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AlmostDoneScreen(
                                              petName: widget.petName,
                                              petType: widget.petType,
                                              breed: _selectedBreed,
                                              gender: _selectedGender,
                                              birthDate: _birthDate,
                                              weight: _weightController.text.trim(),
                                              pickedPhoto: widget.pickedPhoto,
                                              pickedBytes: widget.pickedBytes,
                                            ),
                                          ),
                                        );
                                      }),
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
                                    widget.isFromBreedIdentification ? 'Save' : 'Next',
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

  Future<void> _savePetDirectly() async {
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

      // Use imageBytesFromIdentification if available, otherwise use pickedBytes or pickedPhoto
      final imageBytes = widget.imageBytesFromIdentification ?? widget.pickedBytes;
      final pickedPhoto = widget.pickedPhoto;

      if (imageBytes != null || pickedPhoto != null) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          storagePath = 'pet_images/${user.uid}/$timestamp.jpg';
          final storageRef = FirebaseStorage.instance.ref().child(storagePath);

          UploadTask? uploadTask;
          if (imageBytes != null) {
            uploadTask = storageRef.putData(
              imageBytes,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else if (!kIsWeb && pickedPhoto != null) {
            final file = File(pickedPhoto.path);
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

      final gender = _selectedGender == null
          ? 'Unknown'
          : (_selectedGender == 0 ? 'Male' : 'Female');
      final species = widget.petType == 0 ? 'Dog' : 'Cat';

      // Prepare pet data
      final petData = {
        'userId': user.uid,
        'name': widget.petName,
        'breed': _selectedBreed ?? 'Unknown',
        'gender': gender,
        'speciesType': species,
        'weight': _weightController.text.trim(),
        'spayedNeutered': 'No',
        'medicalConcerns': <String>[],
        'description': '',
        'imageAsset': 'assets/${widget.petType == 0 ? 'dog' : 'cat'}.png',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (_birthDate != null) 'birthDate': Timestamp.fromDate(_birthDate!),
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
            backgroundColor: selected ? _mint : Colors.grey.shade200,
            child: Icon(
              icon,
              color: selected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreedModalContent extends StatefulWidget {
  final List<String> breeds;
  final TextEditingController searchController;
  final Function(String) onBreedSelected;

  const _BreedModalContent({
    required this.breeds,
    required this.searchController,
    required this.onBreedSelected,
  });

  @override
  State<_BreedModalContent> createState() => _BreedModalContentState();
}

class _BreedModalContentState extends State<_BreedModalContent> {
  List<String> _filteredBreeds = [];

  @override
  void initState() {
    super.initState();
    _filteredBreeds = widget.breeds;
    widget.searchController.addListener(_filterBreeds);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_filterBreeds);
    super.dispose();
  }

  void _filterBreeds() {
    setState(() {
      if (widget.searchController.text.isEmpty) {
        _filteredBreeds = widget.breeds;
      } else {
        _filteredBreeds = widget.breeds
            .where(
              (breed) => breed.toLowerCase().contains(
                widget.searchController.text.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: _mint.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _mint.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: widget.searchController,
                  autofocus: true,
                  onChanged: (_) => _filterBreeds(),
                  decoration: InputDecoration(
                    hintText: 'Search breed',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search, color: _mint),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              widget.searchController.clear();
                              _filterBreeds();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _mint, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _mint, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _mint, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          // Breed List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBreeds.length,
              itemBuilder: (BuildContext context, int index) {
                final breed = _filteredBreeds[index];
                return InkWell(
                  onTap: () {
                    widget.onBreedSelected(breed);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            breed,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
