import 'package:flutter/material.dart';
import 'package:fureverhealthy/pet_profile.dart';
import 'package:fureverhealthy/appointment.dart';
import 'package:fureverhealthy/pet_guide.dart';
import 'package:fureverhealthy/models/pet_model.dart';
import 'package:fureverhealthy/symptom_check.dart';
import 'package:fureverhealthy/quick_actions/community.dart';

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

  final List<Widget> _pages = [
    const HomeTab(),
    const PetGuidePage(),
    const CommunityPage(),
    const AppointmentPage(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF1EC39F),
        elevation: 0,
        automaticallyImplyLeading: false, // remove default back button
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo on the left
            Image.asset(
              'assets/furever.png',
              height: 40,
            ),
            // const Text(
            //   'Furever Healthy',
            //   style: TextStyle(
            //     fontSize: 22,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //   ),
            // ),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1EC39F),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/hmpage.png',
              height: 40,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/guide.png',
              height: 40,
            ),
            label: 'Pet Guide',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/add_post.png',
              height: 40,
            ),
            label: 'Paws',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/appoint.png',
              height: 40,
            ),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/userprof.png',
              height: 40,
            ),
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
    // widths and heights for cards in the horizontal scroller
    const double petCardWidth = 320;
    const double petCardHeight = 140;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hello, Fur Parent! Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFD4FFEC),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, Fur Parent!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1EC39F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get personalized care for your furry friend!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print('Identify Breed tapped!');
                          },
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text(
                            'Identify Breed',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF02AF95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SymptomCheckPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search, color: Colors.black54),
                          label: const Text(
                            'Symptom Check',
                            style: TextStyle(color: Colors.black54),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: const BorderSide(color: Colors.black12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // My Pets title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Pets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    print('All tapped!');
                  },
                  child: const Text(
                    'All',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // small circular pet icons scroller (unchanged)
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPetButton('Spencer', 'assets/dog.png', context),
                  const SizedBox(width: 10),
                  _buildAddPetButton(),
                ],
              ),
            ),

            // const SizedBox(height: 6),

            // ---------- HORIZONTAL SCROLLABLE PET DETAIL CARDS ----------
            SizedBox(
              height: petCardHeight + 20,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 4),

                    // Pet detail card (example)
                    SizedBox(
                      width: petCardWidth,
                      child: _buildPetDetailCard(
                        context,
                        'Spencer',
                        'Golden Retriever',
                        'assets/dog.png',
                        'Vaccine Due',
                        height: petCardHeight,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Add new pet card (now same width & height as pet card)
                    SizedBox(
                    width: 140,
                    child: _buildEmptyPetDetailCard(
                      context,
                      size: 140,
                    ),
                  ),

                    // const SizedBox(width: 12),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // other content...
          ],
        ),
      ),
    );
  }

  Widget _buildPetButton(String name, String imagePath, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle pet button tap
        print('$name tapped!');
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                imagePath,
                height: 60,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPetButton() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/add_post.png',
              height: 60,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '+Add',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Pet detail card (keeps previous styling). height param controls its fixed height.
  Widget _buildPetDetailCard(BuildContext context, String name, String breed, String imagePath, String status, {double height = 140}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFBDAFE0), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // slim colored bar (left)
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1EC39F),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // avatar with mint gradient circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFDFFCF4), Color(0xFFD4FFEC)],
                center: Alignment(-0.2, -0.2),
                focal: Alignment(-0.1, -0.1),
                focalRadius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(imagePath, height: 40, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 12),

          // Name, breed and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // title row: name + Edit button aligned right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        print('Edit $name tapped!');
                      },
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Color(0xFF1EC39F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Text(
                  breed,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),

                // status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      fontWeight: FontWeight.w600,
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

  // Empty "Add New Pet" card — square with left pastel bar
Widget _buildEmptyPetDetailCard(BuildContext context, {double size = 140}) {
  return GestureDetector(
    onTap: () {
      print('Add new pet tapped!');
      // TODO: navigate to Add Pet screen
    },
    child: Container(
      width: size,
      height: size, // ensures square
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBDAFE0), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // slim pastel bar on left
          Container(
            width: 6,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFCBC0F5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),

          // centered column with add image and text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/add_post.png',
                  height: 44,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add New Pet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
