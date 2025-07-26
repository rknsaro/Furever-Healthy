import 'package:flutter/material.dart';
// Import the new pet profile page
import 'package:fureverhealthy/pet_profile.dart';
// Import the new appointment page
import 'package:fureverhealthy/appointment.dart'; // <--- Add this import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Pages for each tab
  final List<Widget> _pages = [
    const HomeTab(),
    const AppointmentPage(), // <--- Changed to AppointmentPage
    const PetGuideTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0D6),
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF61972E), // Header color applied
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/furever2.png', // Logo from assets
              height: 40,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {
              print('Notification icon tapped!');
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'Pet Guide',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF6F994A),
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ----------------------
// Tabs Below
// ----------------------

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Added space below the header of the HomeTab
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                color: const Color(0xFFC5E7A6), // Changed to solid color C5E7A6
                borderRadius: BorderRadius.circular(20), // Apply borderRadius to the container
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, Fur Parent!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87, // Changed text color for better contrast
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Get personalized care for your furry friend!',
                    style: TextStyle(fontSize: 16, color: Colors.black54), // Changed text color for better contrast
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print('Identify Breed tapped!');
                          },
                          icon: const Icon(Icons.camera_alt, color: Colors.white), // Icon color
                          label: const Text('Identify Breed', style: TextStyle(color: Colors.white)), // Text color
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF61972E), // Changed to dark green
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print('Symptom Check tapped!');
                          },
                          icon: const Icon(Icons.search, color: Color(0xFF61972E)), // Icon color
                          label: const Text('Symptom Check', style: TextStyle(color: Color(0xFF61972E))), // Text color
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // --- New Content Below Identify Breed/Symptom Check ---
          const SizedBox(height: 25), // Space between previous section and My Pets

          // My Pets section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Pets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        print('Add Pet tapped!');
                        // Implement add pet logic
                      },
                      icon: const Icon(Icons.add, color: Color(0xFF61972E)),
                      label: const Text(
                        'Add Pet',
                        style: TextStyle(color: Color(0xFF61972E), fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 130, // Adjust height as needed for pet cards
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Example Pet Card 1 (Dog)
                      _buildPetCard(
                        context,
                        'Deabak',
                        'Shiba Inu',
                        'dog.png', // Using dog.png
                        'Male', // Example gender
                        '2 years', // Example age
                        '56 cm', // Example height
                        '32 kg', // Example weight
                        'Vaccine Due',
                        'Feed Pet',
                      ),
                      const SizedBox(width: 15),
                      // Example Pet Card 2 (Cat)
                      _buildPetCard(
                        context,
                        'Ggong',
                        'Scottish Fold',
                        'cat.png', // Using cat.png
                        'Female', // Example gender
                        '3 years', // Example age
                        '30 cm', // Example height
                        '5 kg', // Example weight
                        null, // No vaccine due
                        'Feed Pet',
                      ),
                      const SizedBox(width: 15),
                      // Add more pet cards as needed
                      _buildPetCard(
                        context,
                        'Buddy',
                        'Golden Retriever',
                        'dog.png', // Using dog.png
                        'Male',
                        '4 years',
                        '60 cm',
                        '28 kg',
                        'Checkup Soon',
                        'Play Time',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25), // Space between My Pets and Quick Actions

          // Quick Actions section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 15),
                GridView.count(
                  shrinkWrap: true, // Important for GridView inside Column/SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                  crossAxisCount: 4, // 4 items per row as per screenshot
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildQuickActionItem('assets/feeding.png', 'Feeding'),
                    _buildQuickActionItem('assets/grooming.png', 'Grooming'),
                    _buildQuickActionItem('assets/community.png', 'Community'),
                    _buildQuickActionItem('assets/vaccination.png', 'Vaccine'),
                    // Add more quick action items as needed
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Space at the bottom
        ],
      ),
    );
  }

  // Helper method to build Pet Cards
  Widget _buildPetCard(
    BuildContext context,
    String name,
    String breed,
    String imageAssetName, // Changed to String for image asset name
    String gender, // Added for PetProfilePage
    String age, // Added for PetProfilePage
    String height, // Added for PetProfilePage
    String weight, // Added for PetProfilePage
    String? status1,
    String? status2,
  ) {
    return Container(
      width: 180, // Made wider, adjust as needed
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE8F0D6), // Light green background for avatar
                  child: Image.asset( // Changed to Image.asset
                    'assets/$imageAssetName', // Path to the image asset
                    color: const Color(0xFF61972E), // Apply color tint to the image if desired
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        breed,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // The GestureDetector for the edit icon
                GestureDetector(
                  onTap: () {
                    // Navigate to PetProfilePage with pet data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetProfilePage(
                          petName: name,
                          petBreed: breed,
                          gender: gender,
                          age: age,
                          height: height,
                          weight: weight,
                          petImageAsset: imageAssetName, // Pass the image asset name
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.edit, color: Colors.grey, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (status1 != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DDF0), // Light blue for vaccine due
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status1,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
            if (status1 != null && status2 != null) const SizedBox(height: 5),
            if (status2 != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0D6D6), // Light red for feed pet
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status2,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build Quick Action items
  Widget _buildQuickActionItem(String imagePath, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
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
          child: Center(
            child: Image.asset(
              imagePath, // Use actual image asset here
              width: 40,
              height: 40,
              color: const Color(0xFF61972E), // Apply green tint to icons
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// The AppointmentPage is now imported and used directly in _pages list
// The AppointmentsTab class is no longer needed if AppointmentPage is directly used.
// If you want to keep AppointmentsTab as a wrapper, you can modify it to:
/*
class AppointmentsTab extends StatelessWidget {
  const AppointmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppointmentPage();
  }
}
*/

class PetGuideTab extends StatelessWidget {
  const PetGuideTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Pet Guide Page',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}