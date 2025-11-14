import 'package:flutter/material.dart';

import 'data/pet_guide_data.dart';
import 'models/pet_breed.dart';
import 'services/pet_guide_storage.dart';

class PetGuidePage extends StatefulWidget {
  const PetGuidePage({super.key});

  @override
  State<PetGuidePage> createState() => _PetGuidePageState();
}

class _PetGuidePageState extends State<PetGuidePage> {
  late List<PetBreed> _dogBreeds;
  late List<PetBreed> _catBreeds;
  bool _isLoadingOverrides = false;
  late final VoidCallback _storageListener;

  @override
  void initState() {
    super.initState();
    _dogBreeds = List<PetBreed>.from(defaultTopDogBreeds);
    _catBreeds = List<PetBreed>.from(defaultTopCatBreeds);
    _storageListener = () => _loadOverrides();
    PetGuideStorage.instance.overridesVersion.addListener(_storageListener);
    _loadOverrides();
  }

  @override
  void dispose() {
    PetGuideStorage.instance.overridesVersion.removeListener(_storageListener);
    super.dispose();
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
    } finally {
      _isLoadingOverrides = false;
    }
  }

  List<PetBreed> _applyOverrides(
    List<PetBreed> defaults,
    Map<String, PetBreed> overrides,
  ) {
    if (overrides.isEmpty) {
      return defaults;
    }
    return defaults
        .map((breed) => overrides[breed.name.toLowerCase()] ?? breed)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreedSection(
              title: 'Top Dog Breeds',
              subtitle:
                  'Discover local favorites and family-friendly companions.',
              breeds: _dogBreeds,
            ),
            const SizedBox(height: 24),
            _buildBreedSection(
              title: 'Top Cat Breeds',
              subtitle: 'Elegant, cuddly, and full of personality.',
              breeds: _catBreeds,
            ),
            const SizedBox(height: 24),
          ],
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

  void _openBreedDetails(PetBreed breed) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PetBreedDetailPage(breed: breed)));
  }
}

class _BreedHighlightCard extends StatelessWidget {
  final PetBreed breed;
  final void Function(PetBreed breed) onViewDetails;

  const _BreedHighlightCard({required this.breed, required this.onViewDetails});

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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F1CF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.pets, color: Color(0xFF5E7A38)),
                  ),
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
                  onPressed: () => onViewDetails(breed),
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
    _activeCareGuideTab = 'nutrition';
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
