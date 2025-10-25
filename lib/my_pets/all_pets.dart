import 'package:flutter/material.dart';
import 'package:fureverhealthy/my_pets/add_new_pet.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);

class AllPetsPage extends StatefulWidget {
  const AllPetsPage({super.key});

  @override
  State<AllPetsPage> createState() => _AllPetsPageState();
}

class _AllPetsPageState extends State<AllPetsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_mint, _mintDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with back button and centered "My Pets"
              Padding(
                padding: EdgeInsets.only(top: statusBarHeight + 4, left: 8, right: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'My Pets',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // My Pets Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Pets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _PetCircle(name: 'Spencer', imagePath: 'assets/dog.png'),
                          const SizedBox(width: 12),
                          _PetCircle(name: 'Luna', imagePath: 'assets/cat.png'),
                          const SizedBox(width: 12),
                          _AddCircle(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddNewPetPage()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2.5,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Appointments'),
                    Tab(text: 'Reminders'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // White rounded container for content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      Center(
                        child: Text(
                          'All Pet Profiles List Here',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      Center(
                        child: Text(
                          'All Pet Appointments Here',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      Center(
                        child: Text(
                          'All Pet Reminders Here',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
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

// Pet Circle (with image)
class _PetCircle extends StatelessWidget {
  final String name;
  final String imagePath;

  const _PetCircle({required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFA9C88C),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Add New Pet Circle
class _AddCircle extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFA9C88C),
            ),
            child: const Icon(Icons.add, size: 35, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add new pet',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
