// lib/breed_result_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);

class BreedResultScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final String resultJson;

  const BreedResultScreen({
    super.key,
    required this.imageBytes,
    required this.resultJson,
  });

  @override
  Widget build(BuildContext context) {
    final data = jsonDecode(resultJson);
    final breed = data['breed'] ?? 'Unknown Breed';
    final group = data['group'] ?? '-';
    final size = data['size'] ?? '-';
    final lifespan = data['lifespan'] ?? '-';
    final desc = data['description'] ?? 'No description available.';
    final characteristics = Map<String, dynamic>.from(
      data['characteristics'] ?? {},
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _mint,
        title: const Text(
          'Furever Healthy',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Image.memory(
              imageBytes,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breed,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoTile('Breed Group', group),
                      _buildInfoTile('Size', size),
                      _buildInfoTile('Life Span', lifespan),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    desc,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Characteristics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),
                  ...characteristics.entries.map(
                    (e) => _buildCharacteristic(e.key, e.value),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Care Guide',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildCareTabs(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristic(String name, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[200],
            color: _mint,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  Widget _buildCareTabs(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _buildTag('Nutrition'),
        _buildTag('Grooming'),
        _buildTag('Exercise'),
        _buildTag('Health'),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: text == 'Nutrition' ? _mint.withOpacity(0.1) : Colors.white,
        border: Border.all(color: _mint),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _mintDark,
          fontWeight: text == 'Nutrition' ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
