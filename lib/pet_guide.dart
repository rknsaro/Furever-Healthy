import 'package:flutter/material.dart';

class PetGuidePage extends StatefulWidget {
  const PetGuidePage({super.key});

  @override
  State<PetGuidePage> createState() => _PetGuidePageState();
}

class _PetGuidePageState extends State<PetGuidePage> {
  String _activeCareGuideTab = 'Nutrition';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breed Image and Name Section
          Stack(
            children: [
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/golden_retriever.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: const Text(
                    'Golden Retriever',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // LEFT-ALIGNED BREED INFO
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _BreedInfoColumn(title: 'Breed Group', value: 'Sporting'),
                SizedBox(width: 24),
                _BreedInfoColumn(title: 'Size', value: 'Medium-large'),
                SizedBox(width: 24),
                _BreedInfoColumn(title: 'Life Span', value: '10-12 years'),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Friendly, intelligent, and devoted. Golden Retrievers are excellent family dogs and are eager to please their owners.',
              style: TextStyle(fontSize: 15, color: Colors.black87),
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
                _buildCharacteristicRow('Friendliness', 95),
                _buildCharacteristicRow('Trainability', 90),
                _buildCharacteristicRow('Energy Level', 80),
                _buildCharacteristicRow('Shedding', 70),
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
              Text(characteristic, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              Text('$percentage%', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            color: const Color(0xFF6F994A),
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
          color: isActive ? const Color(0xFF6F994A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF6F994A) : Colors.grey.shade300,
          ),
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
    switch (_activeCareGuideTab) {
      case 'Nutrition':
        return Column(children: [
          _buildInfoCard(icon: Icons.fastfood, title: 'Diet Requirements', content: 'Golden Retrievers need high-quality dog food...'),
          const SizedBox(height: 15),
          _buildInfoCard(icon: Icons.monitor_weight, title: 'Weight Management', content: 'Prone to obesity. Monitor weight regularly...'),
          const SizedBox(height: 15),
          _buildInfoCard(icon: Icons.block, title: 'Foods to avoid', content: 'Chocolate, grapes, onions, garlic are toxic.'),
        ]);
      case 'Grooming':
        return Column(children: [
          _buildInfoCard(icon: Icons.brush, title: 'Coat Care', content: 'Brush regularly to prevent matting...'),
          const SizedBox(height: 15),
          _buildInfoCard(icon: Icons.content_cut, title: 'Nail Trimming', content: 'Trim nails every 3-4 weeks...'),
        ]);
      case 'Exercise':
        return Column(children: [
          _buildInfoCard(icon: Icons.directions_run, title: 'Daily Activity', content: 'Requires 60 mins of vigorous exercise daily.'),
          const SizedBox(height: 15),
          _buildInfoCard(icon: Icons.sports_tennis, title: 'Mental Stimulation', content: 'Puzzle toys and training sessions help.'),
        ]);
      case 'Health':
        return Column(children: [
          _buildInfoCard(icon: Icons.local_hospital, title: 'Common Health Issues', content: 'Hip dysplasia, cancer, eye issues.'),
          const SizedBox(height: 15),
          _buildInfoCard(icon: Icons.vaccines, title: 'Vaccinations & Parasite Control', content: 'Stay up-to-date with vet visits.'),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
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
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// LEFT-ALIGNED BREED INFO COLUMN WIDGET
class _BreedInfoColumn extends StatelessWidget {
  final String title;
  final String value;

  const _BreedInfoColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text to left
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
