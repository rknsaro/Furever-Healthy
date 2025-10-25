import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:fureverhealthy/pet_profile.dart';
import 'package:fureverhealthy/appointment.dart';
import 'package:fureverhealthy/pet_guide.dart';
// ignore: unused_import
import 'package:fureverhealthy/models/pet_model.dart';
import 'package:fureverhealthy/symptom_check.dart';
// import 'package:fureverhealthy/quick_actions/community.dart';
import 'package:fureverhealthy/quick_actions/quick_actions_panel.dart';
import 'package:fureverhealthy/my_pets/add_new_pet.dart'; // This is the new import
import 'package:fureverhealthy/my_pets/all_pets.dart';
import 'package:fureverhealthy/identify_breed.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);
const _screenBg = Color(0xFFF6F8FB);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    PetGuidePage(),
    AppointmentPage(),
    ProfileTab(),
  ];

  void _onItemTapped(int i) => setState(() => _selectedIndex = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/furever.png', height: 40),
            const SizedBox(width: 8),
            const Text(
              'Furever Healthy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
            tooltip: 'Settings',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: _mint,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 12,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset('assets/hmpage.png', height: 28),
            activeIcon: Image.asset('assets/hmpage.png', height: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/guide.png', height: 28),
            label: 'Pet Guide',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/appoint.png', height: 28),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/userprof.png', height: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    const petCardWidth = 320.0;
    const petCardHeight = 140.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GREETING CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xBFB9E591),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, Fur Parent!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _mintDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Get personalized care for your furry friend!',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _FilledPillButton(
                          icon: Icons.camera_alt,
                          label: 'Identify Breed',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IdentifyBreedScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OutlinedPillButton(
                          icon: Icons.search,
                          label: 'Symptom Check',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SymptomCheckPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // MY PETS
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Pets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              TextButton(
                // MODIFIED: Add navigation here
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllPetsPage(), // <--- USE AllPetsPage
                    ),
                  );
                },
                child: const Text(
                  'All',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

            // round avatars
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: const [
                  _PetCircle(name: 'Spencer', imagePath: 'assets/dog.png'),
                  SizedBox(width: 10),
                  _AddCircle(), // This widget is now tappable
                ],
              ),
            ),
            // PET CARD (horizontal scroller)
            SizedBox(
              height: petCardHeight + 30,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    SizedBox(
                      width: petCardWidth,
                      child: _PetDetailCard(
                        name: 'Spencer',
                        breed: 'Golden Retriever',
                        imagePath: 'assets/dog.png',
                        status: 'Vaccine Due',
                        height: petCardHeight,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            const Divider(
              height: 1,
              thickness: 3,
              color: Color(0x11000000),
            ),
            const SizedBox(height: 18),

            // QUICK ACTIONS PANEL
            const QuickActionsPanel(),
          ],
        ),
      ),
    );
  }
}

/* —— Small helper widgets —— */

class _FilledPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FilledPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _mintDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _OutlinedPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlinedPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.black54),
      label: Text(label, style: const TextStyle(color: Colors.black54)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class _PetCircle extends StatelessWidget {
  final String name;
  final String imagePath;
  const _PetCircle({required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          // decoration: const BoxDecoration(
          //   shape: BoxShape.circle,
          //   color: Color(0xFFE6FFF7),
          // ),
          child: Center(child: Image.asset(imagePath, height: 40)),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// MODIFIED TO NAVIGATE ON TAP
class _AddCircle extends StatelessWidget {
  const _AddCircle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigates to the AddNewPetPage when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddNewPetPage(),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            // Added a color for better visibility as a tappable area
            // decoration: BoxDecoration(
            //   shape: BoxShape.circle,
            //   color: Colors.grey[200],
            // ),
            child: Center(child: Image.asset('assets/add_post.png', height: 44)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add new pet',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PetDetailCard extends StatelessWidget {
  final String name;
  final String breed;
  final String imagePath;
  final String status;
  final double height;

  const _PetDetailCard({
    required this.name,
    required this.breed,
    required this.imagePath,
    required this.status,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBDAFE0), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // slim mint bar
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // avatar
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFDFFCF4), Color(0xBFB9E591)],
                center: Alignment(-0.2, -0.2),
                focal: Alignment(-0.1, -0.1),
                focalRadius: .8,
              ),
            ),
            child: Center(child: Image.asset(imagePath, height: 40)),
          ),
          const SizedBox(width: 12),

          // info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: _mint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  breed,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD3C8FF)),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF5C4DB3),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Page', style: TextStyle(fontSize: 18)),
    );
  }
}