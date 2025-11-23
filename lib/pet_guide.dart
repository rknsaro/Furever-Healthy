import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'breed_detail_screen.dart';
import 'data/pet_guide_data.dart';
import 'models/pet_breed.dart';
import 'services/pet_guide_storage.dart';

// Helper class to store pet information for display
class _MyPetInfo {
  final String petName;
  final String breedName;
  final String speciesType;
  final String breedGroup;
  final String? imageUrl;
  final String? imageAsset;
  final PetBreed? breedInfo;

  _MyPetInfo({
    required this.petName,
    required this.breedName,
    required this.speciesType,
    required this.breedGroup,
    this.imageUrl,
    this.imageAsset,
    this.breedInfo,
  });
}

class PetGuidePage extends StatefulWidget {
  const PetGuidePage({super.key});

  @override
  State<PetGuidePage> createState() => _PetGuidePageState();
}

class _PetGuidePageState extends State<PetGuidePage>
    with WidgetsBindingObserver {
  late List<PetBreed> _dogBreeds;
  late List<PetBreed> _catBreeds;
  List<_MyPetInfo> _myPets = []; // Store individual pet info
  bool _isLoadingOverrides = false;
  late final VoidCallback _storageListener;

  @override
  void initState() {
    super.initState();
    _dogBreeds = List<PetBreed>.from(defaultTopDogBreeds);
    _catBreeds = List<PetBreed>.from(defaultTopCatBreeds);
    _storageListener = () => _loadOverrides();
    PetGuideStorage.instance.overridesVersion.addListener(_storageListener);
    WidgetsBinding.instance.addObserver(this);
    _loadOverrides();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PetGuideStorage.instance.overridesVersion.removeListener(_storageListener);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload when app comes back to foreground
      _loadOverrides();
    }
  }

  Future<void> _loadOverrides() async {
    if (_isLoadingOverrides) return;
    _isLoadingOverrides = true;
    try {
      final overrides = await PetGuideStorage.instance.loadOverrides();
      if (!mounted) return;
      setState(() {
        _dogBreeds = _applyOverrides(
          List<PetBreed>.from(defaultTopDogBreeds),
          overrides.dogs,
        );
        _catBreeds = _applyOverrides(
          List<PetBreed>.from(defaultTopCatBreeds),
          overrides.cats,
        );
      });
      // Load breeds from user's pets
      await _loadMyPetBreeds(overrides);
    } catch (e) {
      // Silently handle errors - keep existing breeds
      debugPrint('Error loading breed overrides: $e');
    } finally {
      _isLoadingOverrides = false;
    }
  }

  Future<void> _loadMyPetBreeds(PetGuideOverrides overrides) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _myPets = []);
      return;
    }

    try {
      final petsSnapshot = await FirebaseFirestore.instance
          .collection('petInfos')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<_MyPetInfo> myPets = [];

      for (final petDoc in petsSnapshot.docs) {
        final petData = petDoc.data();
        final petName = (petData['name'] ?? '').toString().trim();
        final breedName = (petData['breed'] ?? '').toString().trim();
        final speciesType = (petData['speciesType'] ?? 'Dog').toString();

        if (breedName.isEmpty ||
            breedName.toLowerCase() == 'unknown' ||
            breedName.toLowerCase() == 'unknown breed' ||
            petName.isEmpty) {
          continue;
        }

        final isDog = speciesType.toLowerCase() == 'dog';
        final breedNameLower = breedName.toLowerCase();

        // Get pet image URL if available
        final imageUrl = petData['imageUrl'] as String?;
        final imageAsset = petData['imageAsset'] as String?;

        // Try to get breed info from overrides (stored breed data)
        final breedMap = isDog ? overrides.dogs : overrides.cats;
        PetBreed? breedInfo = breedMap[breedNameLower];

        // If not found in overrides, try to find in defaults
        if (breedInfo == null) {
          final canonicalName = isDog
              ? resolveTopDogCanonicalName(breedName)
              : resolveTopCatCanonicalName(breedName);

          if (canonicalName != null) {
            breedInfo = isDog
                ? findDefaultDogBreedByName(canonicalName)
                : findDefaultCatBreedByName(canonicalName);

            // If found in defaults, check if there's an override
            if (breedInfo != null) {
              final overrideInfo = breedMap[canonicalName.toLowerCase()];
              if (overrideInfo != null) {
                breedInfo = overrideInfo;
              }
            }
          }
        }

        // Get breed group from breed info or use default
        final breedGroup = breedInfo?.breedGroup ?? 'Mixed';
        final finalBreedName = breedInfo?.name ?? capitalizeBreed(breedName);

        // Add individual pet info
        myPets.add(
          _MyPetInfo(
            petName: petName,
            breedName: finalBreedName,
            speciesType: speciesType,
            breedGroup: breedGroup,
            imageUrl: imageUrl,
            imageAsset: imageAsset,
            breedInfo:
                breedInfo ??
                PetBreed(
                  name: finalBreedName,
                  animalType: isDog ? 'Dog' : 'Cat',
                  breedGroup: breedGroup,
                  size: petData['size']?.toString() ?? 'Unknown',
                  lifeSpan: 'Unknown',
                  description:
                      'Breed information for $petName - $finalBreedName.',
                  characteristics: const {},
                  careGuide: const {},
                ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _myPets = myPets;
        });
      }
    } catch (e) {
      debugPrint('Error loading my pet breeds: $e');
      if (mounted) {
        setState(() => _myPets = []);
      }
    }
  }

  List<PetBreed> _applyOverrides(
    List<PetBreed> defaults,
    Map<String, PetBreed> overrides,
  ) {
    if (overrides.isEmpty) {
      return defaults;
    }

    // First, replace existing breeds with overrides
    final updatedDefaults = defaults
        .map((breed) => overrides[breed.name.toLowerCase()] ?? breed)
        .toList();

    // Then, add new breeds from overrides that aren't in the defaults
    final defaultNames = defaults
        .map((breed) => breed.name.toLowerCase())
        .toSet();

    final newBreeds = overrides.values
        .where((breed) => !defaultNames.contains(breed.name.toLowerCase()))
        .toList();

    // Combine updated defaults with new breeds
    return [...updatedDefaults, ...newBreeds];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8FB),
      child: RefreshIndicator(
        onRefresh: _loadOverrides,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My Pets Section (if user has pets)
              if (_myPets.isNotEmpty) ...[
                _buildMyPetsSection(),
                const SizedBox(height: 24),
              ],
              _buildBreedSection(
                title: 'Dog Breeds',
                subtitle:
                    'Discover local favorites, family-friendly companions, and popular dog breeds.',
                breeds: _dogBreeds,
              ),
              const SizedBox(height: 24),
              _buildBreedSection(
                title: 'Cat Breeds',
                subtitle:
                    'Elegant, cuddly, and full of personality. Explore popular cat breeds.',
                breeds: _catBreeds,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreedSection({
    required String title,
    required String subtitle,
    required List<PetBreed> breeds,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF304222),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final breed in breeds) ...[
                _BreedHighlightCard(
                  breed: breed,
                  onViewDetails: _openBreedDetails,
                ),
                if (breed != breeds.last) const SizedBox(width: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Pets',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF304222),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap to review detailed breed information for your pets.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < _myPets.length; i++) ...[
                _MyPetCard(
                  petInfo: _myPets[i],
                  onViewDetails: _openBreedDetails,
                ),
                if (i < _myPets.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openBreedDetails(PetBreed breed, {String? imageUrl}) async {
    // Download pet image if URL is provided
    Uint8List imageBytes = Uint8List(0);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Check if it's a network URL
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          }
        } catch (e) {
          debugPrint('Error loading pet image: $e');
          // Continue with empty bytes if image fails to load
        }
      }
    }

    // Convert careGuide from Map<String, String> to Map<String, dynamic>
    final careGuideMap = <String, dynamic>{
      for (final entry in breed.careGuide.entries) entry.key: entry.value,
    };

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BreedDetailScreen(
            imageBytes: imageBytes,
            breed: breed.name,
            breedGroup: breed.breedGroup,
            size: breed.size,
            lifeSpan: breed.lifeSpan,
            description: breed.description,
            characteristics: breed.characteristics,
            careGuide: careGuideMap,
          ),
        ),
      );
    }
  }
}

class _BreedHighlightCard extends StatelessWidget {
  final PetBreed breed;
  final void Function(PetBreed breed, {String? imageUrl}) onViewDetails;
  final String? imageUrl; // Optional image URL for pet photos

  const _BreedHighlightCard({
    required this.breed,
    required this.onViewDetails,
    this.imageUrl,
  });

  Widget _buildBreedIcon(String? imageUrl, String animalType) {
    final isCat = animalType.toLowerCase() == 'cat';
    final defaultIconAsset = isCat ? 'assets/cat.png' : 'assets/dog.png';

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Check if it's a network URL or asset path
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        // Network image
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultIcon(defaultIconAsset),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F1CF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5E7A38),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      } else {
        // Asset image
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultIcon(defaultIconAsset),
          ),
        );
      }
    }

    // Default icon if no image
    return _buildDefaultIcon(defaultIconAsset);
  }

  Widget _buildDefaultIcon(String iconAsset) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE1F1CF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Image.asset(iconAsset, height: 28)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final num clampedWidth = (MediaQuery.of(context).size.width * 0.7).clamp(
      220.0,
      280.0,
    );
    final double width = clampedWidth.toDouble();
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreedIcon(imageUrl, breed.animalType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          breed.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF223118),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${breed.animalType} • ${breed.breedGroup}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F994A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => onViewDetails(breed, imageUrl: imageUrl),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// New card widget for individual pets matching the image design
class _MyPetCard extends StatelessWidget {
  final _MyPetInfo petInfo;
  final void Function(PetBreed breed, {String? imageUrl}) onViewDetails;

  const _MyPetCard({required this.petInfo, required this.onViewDetails});

  Widget _buildPetImage() {
    final isCat = petInfo.speciesType.toLowerCase() == 'cat';
    final defaultIconAsset = isCat ? 'assets/cat.png' : 'assets/dog.png';

    if (petInfo.imageUrl != null && petInfo.imageUrl!.isNotEmpty) {
      if (petInfo.imageUrl!.startsWith('http://') ||
          petInfo.imageUrl!.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            petInfo.imageUrl!,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultImage(defaultIconAsset),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1F1CF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5E7A38),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
    }

    if (petInfo.imageAsset != null && petInfo.imageAsset!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          petInfo.imageAsset!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultImage(defaultIconAsset),
        ),
      );
    }

    return _buildDefaultImage(defaultIconAsset);
  }

  Widget _buildDefaultImage(String iconAsset) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFFE1F1CF),
        shape: BoxShape.circle,
      ),
      child: Center(child: Image.asset(iconAsset, height: 35)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final num clampedWidth = (MediaQuery.of(context).size.width * 0.7).clamp(
      220.0,
      280.0,
    );
    final double width = clampedWidth.toDouble();
    final imageUrl = petInfo.imageUrl ?? petInfo.imageAsset;

    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular pet image
                  _buildPetImage(),
                  const SizedBox(width: 12),
                  // Pet information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breed name in bold
                        Text(
                          petInfo.breedName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF223118),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Pet name and type
                        Text(
                          '${petInfo.petName} • ${petInfo.speciesType}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // View details button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F994A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (petInfo.breedInfo != null) {
                      onViewDetails(petInfo.breedInfo!, imageUrl: imageUrl);
                    }
                  },
                  child: const Text(
                    'View details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetBreedDetailPage extends StatefulWidget {
  final PetBreed breed;

  const PetBreedDetailPage({super.key, required this.breed});

  @override
  State<PetBreedDetailPage> createState() => _PetBreedDetailPageState();
}

class _PetBreedDetailPageState extends State<PetBreedDetailPage> {
  late String _activeCareGuideTab;

  @override
  void initState() {
    super.initState();
    _activeCareGuideTab = widget.breed.careGuide.keys.isNotEmpty
        ? widget.breed.careGuide.keys.first
        : 'nutrition';
  }

  @override
  Widget build(BuildContext context) {
    final breed = widget.breed;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(breed.name),
        backgroundColor: const Color(0xFF6F994A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F1CF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 30,
                          color: Color(0xFF5E7A38),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              breed.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF213318),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${breed.animalType} • ${breed.breedGroup}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: -4,
                              children: [
                                _infoPill(Icons.balance, breed.size),
                                _infoPill(Icons.favorite, breed.lifeSpan),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    breed.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Characteristics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF293821),
              ),
            ),
            const SizedBox(height: 12),
            ...breed.characteristics.entries.map(
              (entry) =>
                  _CharacteristicRow(label: entry.key, value: entry.value),
            ),
            const SizedBox(height: 28),
            const Text(
              'Care Guide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF293821),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.breed.careGuide.keys.map((key) {
                final isActive = _activeCareGuideTab == key;
                return ChoiceChip(
                  label: Text(_capitalize(key)),
                  selected: isActive,
                  onSelected: (_) => setState(() => _activeCareGuideTab = key),
                  selectedColor: const Color(0xFF6F994A),
                  backgroundColor: const Color(0xFFE9F2DF),
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF314022),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                widget.breed.careGuide[_activeCareGuideTab] ??
                    'Details unavailable.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Chip(
      backgroundColor: const Color(0xFFF0F5EA),
      avatar: Icon(icon, size: 16, color: const Color(0xFF5A7440)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF2F4024)),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _CharacteristicRow extends StatelessWidget {
  final String label;
  final int value;

  const _CharacteristicRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              Text(
                '$value%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E7DA),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6F994A)),
            ),
          ),
        ],
      ),
    );
  }
}
