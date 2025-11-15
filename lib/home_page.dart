import 'package:flutter/material.dart';
import 'package:fureverhealthy/appointment.dart';
import 'package:fureverhealthy/pet_guide.dart';
import 'package:fureverhealthy/symptom_check.dart';
import 'package:fureverhealthy/quick_actions/quick_actions_panel.dart';
import 'package:fureverhealthy/my_pets/all_pets.dart';
import 'package:fureverhealthy/my_pets/edit_pet_profile.dart';
import 'package:fureverhealthy/identify_breed.dart';
import 'package:fureverhealthy/notifications.dart';
import 'user_prof_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _onItemTapped(int i) => setState(() => _selectedIndex = i);

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return const HomeTab();
      case 1:
        return _PageWithHeader(child: const PetGuidePage());
      case 2:
        return _PageWithHeader(child: const AppointmentPage());
      case 3:
        return _PageWithHeader(child: const UserProfTab());
      default:
        return const HomeTab();
    }
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_selectedIndex == 0) {
      // Show full header on Home tab
      return AppBar(
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
        actions: const [_NotificationsBellButton(), SizedBox(width: 6)],
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: _buildAppBar(),
      body: _buildPage(),
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

class _PageWithHeader extends StatelessWidget {
  final Widget child;

  const _PageWithHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: _mint,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/furever.png', height: 36),
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
                  const _NotificationsBellButton(
                    padding: EdgeInsets.zero,
                    compactConstraints: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _NotificationsBellButton extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final bool compactConstraints;

  const _NotificationsBellButton({
    this.padding = const EdgeInsets.all(8),
    this.compactConstraints = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final resolvedPadding = padding.resolve(Directionality.of(context));

    Widget buildBell(int unreadCount) {
      final icon = Image.asset('assets/notif_bell.png', height: 26);
      final button = IconButton(
        padding: resolvedPadding,
        constraints: compactConstraints
            ? const BoxConstraints(minWidth: 30, minHeight: 30)
            : const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: icon,
        tooltip: 'Notifications',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          );
        },
      );

      if (unreadCount <= 0) {
        return button;
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: resolvedPadding.horizontal == 0 ? 0 : 4,
            top: resolvedPadding.vertical == 0 ? -2 : 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (user == null) {
      return buildBell(0);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            return (data['isRead'] as bool? ?? false) == false;
          }).length;
        }
        return buildBell(unreadCount);
      },
    );
  }
}

/* ——————————————————————————————
   HOME TAB (unchanged)
—————————————————————————————— */
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
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseAuth.instance.currentUser != null
                        ? FirebaseFirestore.instance
                              .collection('petInfos')
                              .where(
                                'userId',
                                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                              )
                              .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      final hasPets = snapshot.hasData &&
                          snapshot.data!.docs.isNotEmpty;
                      
                      return Row(
                        children: [
                          if (!hasPets)
                            Expanded(
                              child: _FilledPillButton(
                                icon: Icons.camera_alt,
                                label: 'Add first pet',
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
                          if (!hasPets) const SizedBox(width: 10),
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
                      );
                    },
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllPetsPage(),
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

            SizedBox(
              height: 100,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance
                          .collection('petInfos')
                          .where(
                            'userId',
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                          )
                          .snapshots()
                    : null,
                builder: (context, snapshot) {
                  if (FirebaseAuth.instance.currentUser == null) {
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [const _AddCircle()],
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pets = snapshot.data!.docs;
                  if (pets.isEmpty) {
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [const _AddCircle()],
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: pets.length + 1, // +1 for AddCircle
                    itemBuilder: (context, index) {
                      if (index == pets.length) {
                        return const _AddCircle();
                      }
                      final petData =
                          pets[index].data() as Map<String, dynamic>;
                      final petName = petData['name'] as String? ?? 'Unknown';
                      final petType =
                          petData['speciesType'] as String? ?? 'Dog';
                      final imageUrl = petData['imageUrl'] as String?;
                      final assetPath = petData['imageAsset'] as String?;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == pets.length - 1 ? 0 : 10,
                        ),
                        child: _PetCircle(
                          petName: petName,
                          petType: petType,
                          imageUrl: imageUrl,
                          assetPath: assetPath,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance
                        .collection('petInfos')
                        .where(
                          'userId',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                        )
                        .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (FirebaseAuth.instance.currentUser == null) {
                  return const SizedBox.shrink();
                }

                if (!snapshot.hasData) {
                  return SizedBox(
                    height: petCardHeight + 30,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final pets = snapshot.data!.docs;
                if (pets.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Show horizontal scroll only if 2 or more pets
                final shouldScroll = pets.length >= 2;

                return SizedBox(
                  height: petCardHeight + 30,
                  child: shouldScroll
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              ...pets.asMap().entries.map((entry) {
                                final index = entry.key;
                                final petDoc = entry.value;
                                final petData =
                                    petDoc.data() as Map<String, dynamic>;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index == pets.length - 1 ? 0 : 14,
                                  ),
                                  child: SizedBox(
                                    width: petCardWidth,
                                    child: _PetDetailCard(
                                      height: petCardHeight,
                                      petId: petDoc.id,
                                      petData: petData,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            SizedBox(
                              width: petCardWidth,
                              child: _PetDetailCard(
                                height: petCardHeight,
                                petId: pets.first.id,
                                petData:
                                    pets.first.data() as Map<String, dynamic>,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),

            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 3, color: Color(0x11000000)),
            const SizedBox(height: 18),
            const QuickActionsPanel(),
          ],
        ),
      ),
    );
  }
}

/* Helper widgets (unchanged) */
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
  final String petName;
  final String petType;
  final String? imageUrl;
  final String? assetPath;

  const _PetCircle({
    this.petName = 'Spencer',
    this.petType = 'Dog',
    this.imageUrl,
    this.assetPath,
  });

  Widget _buildFallback() {
    final iconAsset = petType.toLowerCase() == 'cat'
        ? 'assets/cat.png'
        : 'assets/dog.png';
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE8F3D8),
      ),
      child: Center(
        child: Image.asset(iconAsset, height: 40),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      );
    }
    if (assetPath != null && assetPath!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          assetPath!,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAvatarImage(),
        const SizedBox(height: 6),
        Text(
          petName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AddCircle extends StatelessWidget {
  const _AddCircle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const IdentifyBreedScreen()),
        );
      },
      child: Column(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Image.asset('assets/add_post.png', height: 44),
            ),
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
  final double height;
  final String? petId;
  final Map<String, dynamic>? petData;

  const _PetDetailCard({this.height = 140, this.petId, this.petData});

  @override
  Widget build(BuildContext context) {
    String petName = 'Spencer';
    String petBreed = 'Golden Retriever';
    String status = 'No concerns';
    String petType = 'Dog';

    if (petData != null) {
      petName = petData!['name'] as String? ?? 'Spencer';
      petBreed = petData!['breed'] as String? ?? 'Golden Retriever';
      petType = petData!['speciesType'] as String? ?? 'Dog';

      // Get medical concerns for status
      final medicalConcerns = petData!['medicalConcerns'] as List<dynamic>?;
      if (medicalConcerns != null && medicalConcerns.isNotEmpty) {
        status = medicalConcerns.map((e) => e.toString()).join(', ');
        if (status.length > 30) {
          status = '${status.substring(0, 27)}...';
        }
      } else {
        status = 'No concerns';
      }
    }

    final iconAsset = petType.toLowerCase() == 'cat'
        ? 'assets/cat.png'
        : 'assets/dog.png';
    
    final imageUrl = petData?['imageUrl'] as String?;
    final assetPath = petData?['imageAsset'] as String?;

    Widget _buildFallbackAvatar(String icon) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFDFFCF4), Color(0xBFB9E591)],
          ),
        ),
        child: Center(child: Image.asset(icon, height: 40)),
      );
    }

    Widget _buildPetAvatar() {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return ClipOval(
          child: Image.network(
            imageUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackAvatar(iconAsset),
          ),
        );
      }
      if (assetPath != null && assetPath.isNotEmpty) {
        return ClipOval(
          child: Image.asset(
            assetPath,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackAvatar(iconAsset),
          ),
        );
      }
      return _buildFallbackAvatar(iconAsset);
    }

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
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          _buildPetAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        petName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (petId != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPetProfilePage(
                                petId: petId,
                                petName: petName,
                              ),
                            ),
                          );
                        },
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
                  petBreed,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
