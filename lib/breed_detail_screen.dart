import 'dart:typed_data';
import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);
const _screenBg = Color(0xFFF6F8FB);

class BreedDetailScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String breed;
  final String breedGroup;
  final String size;
  final String lifeSpan;
  final String description;
  final Map<String, int> characteristics;
  final Map<String, dynamic> careGuide;

  const BreedDetailScreen({
    super.key,
    required this.imageBytes,
    required this.breed,
    required this.breedGroup,
    required this.size,
    required this.lifeSpan,
    required this.description,
    required this.characteristics,
    required this.careGuide,
  });

  @override
  State<BreedDetailScreen> createState() => _BreedDetailScreenState();
}

class _BreedDetailScreenState extends State<BreedDetailScreen> {
  String _activeCareGuideTab = 'Nutrition';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: _mint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Breed Information',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breed Image and Name Section
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1, // Makes it square (1:1 ratio)
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(widget.imageBytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                    child: Text(
                      widget.breed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Breed Info Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _BreedInfoColumn(
                    title: 'Breed Group',
                    value: widget.breedGroup,
                  ),
                  const SizedBox(width: 24),
                  _BreedInfoColumn(title: 'Size', value: widget.size),
                  const SizedBox(width: 24),
                  _BreedInfoColumn(title: 'Life Span', value: widget.lifeSpan),
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            // Characteristics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Characteristics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...widget.characteristics.entries.map(
                    (entry) => _buildCharacteristicRow(entry.key, entry.value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Care Guide Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Care Guide',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCareGuideTab('Nutrition'),
                      _buildCareGuideTab('Grooming'),
                      _buildCareGuideTab('Exercise'),
                      _buildCareGuideTab('Health'),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildCareGuideContent(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicRow(String characteristic, int percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                characteristic,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            color: _mint,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildCareGuideTab(String tabName) {
    final bool isActive = _activeCareGuideTab == tabName;
    return GestureDetector(
      onTap: () => setState(() => _activeCareGuideTab = tabName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _mint : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _mint : Colors.grey.shade300),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCareGuideContent() {
    String content = '';
    IconData icon = Icons.info;

    switch (_activeCareGuideTab) {
      case 'Nutrition':
        content = widget.careGuide['nutrition'] ?? 'No information available.';
        icon = Icons.fastfood;
        break;
      case 'Grooming':
        content = widget.careGuide['grooming'] ?? 'No information available.';
        icon = Icons.brush;
        break;
      case 'Exercise':
        content = widget.careGuide['exercise'] ?? 'No information available.';
        icon = Icons.directions_run;
        break;
      case 'Health':
        content = widget.careGuide['health'] ?? 'No information available.';
        icon = Icons.local_hospital;
        break;
    }

    return _buildInfoCard(
      icon: icon,
      title: _activeCareGuideTab,
      content: content,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC5E7A6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF61972E), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreedInfoColumn extends StatelessWidget {
  final String title;
  final String value;

  const _BreedInfoColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
