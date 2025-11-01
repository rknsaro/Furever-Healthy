import 'package:flutter/material.dart';
import 'package:fureverhealthy/book_appointment.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);
const _screenBg = Color(0xFFF6F8FB);

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  String? selectedFilterType;
  String? selectedFilterValue;

  final List<String> filters = ['Location', 'Specialty', 'Rating'];

  // Available filter options for each filter type
  final Map<String, List<String>> filterOptions = {
    'Location': ['Quezon City', 'Manila', 'Makati', 'Pasig', 'Taguig'],
    'Specialty': [
      'Small Animal Specialist',
      'Surgery Specialist',
      'Emergency Care',
      'Dental Specialist',
      'Dermatology',
    ],
    'Rating': ['5 Stars', '4 Stars', '3 Stars'],
  };

  final List<Map<String, dynamic>> allVets = [
    {
      'name': 'Dr. Lorem Ipsum',
      'specialty': 'Small Animal Specialist',
      'rating': 5,
      'location': 'Quezon City',
      'verified': true,
    },
    {
      'name': 'Dr. Jack Doe',
      'specialty': 'Surgery Specialist',
      'rating': 5,
      'location': 'Manila',
      'verified': true,
    },
    {
      'name': 'Dr. Jane Smith',
      'specialty': 'Emergency Care',
      'rating': 4,
      'location': 'Makati',
      'verified': true,
    },
    {
      'name': 'Dr. Maria Santos',
      'specialty': 'Dental Specialist',
      'rating': 5,
      'location': 'Pasig',
      'verified': true,
    },
    {
      'name': 'Dr. John Cruz',
      'specialty': 'Small Animal Specialist',
      'rating': 4,
      'location': 'Taguig',
      'verified': true,
    },
  ];

  List<Map<String, dynamic>> get filteredVets {
    if (selectedFilterType == null || selectedFilterValue == null) {
      return allVets;
    }

    return allVets.where((vet) {
      switch (selectedFilterType) {
        case 'Location':
          return vet['location'] == selectedFilterValue;
        case 'Specialty':
          return vet['specialty'] == selectedFilterValue;
        case 'Rating':
          int filterRating = int.parse(selectedFilterValue!.split(' ')[0]);
          return vet['rating'] == filterRating;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book an appointment',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _mintDark,
                ),
              ),
              const SizedBox(height: 16),

              // Filters Section
              Row(
                children: [
                  ...filters.map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => _showFilterDialog(filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedFilterType == filter
                                ? _mint
                                : Colors.transparent,
                            border: Border.all(
                              color: selectedFilterType == filter
                                  ? _mint
                                  : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: selectedFilterType == filter
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (selectedFilterType != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilterType = null;
                          selectedFilterValue = null;
                        });
                      },
                      child: const Icon(Icons.clear, color: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Show selected filter value
              if (selectedFilterValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _mint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$selectedFilterType: $selectedFilterValue',
                        style: const TextStyle(
                          color: _mintDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              Text(
                filteredVets.isEmpty
                    ? 'No vets found'
                    : 'Available Veterinarians (${filteredVets.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _mintDark,
                ),
              ),
              const SizedBox(height: 12),

              // Vet Cards
              if (filteredVets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No veterinarians match your filter',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredVets.map(
                  (vet) => _doctorCard(
                    vet['name'],
                    vet['specialty'],
                    vet['rating'],
                    vet['location'],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(String filterType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select $filterType'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: filterOptions[filterType]!.map((option) {
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    setState(() {
                      selectedFilterType = filterType;
                      selectedFilterValue = option;
                    });
                    Navigator.pop(context);
                  },
                  selected: selectedFilterValue == option,
                  selectedTileColor: _mint.withOpacity(0.1),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _doctorCard(
    String name,
    String specialty,
    int rating,
    String location,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vet icon
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _mint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.person, size: 30, color: _mintDark),
          ),
          const SizedBox(width: 15),

          // Vet info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 5 Star Rating at the top
                Row(
                  children: List.generate(
                    rating,
                    (index) =>
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                  ),
                ),
                const SizedBox(height: 4),
                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _mintDark,
                  ),
                ),
                const SizedBox(height: 3),
                // Specialty
                Text(
                  specialty,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, color: _mint, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // License Verified
                Row(
                  children: const [
                    Icon(Icons.verified, color: _mint, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'License Verified',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Book Now Button with white text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointmentPage(
                        vetName: name,
                        vetSpecialty: specialty,
                        vetRating: rating,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
