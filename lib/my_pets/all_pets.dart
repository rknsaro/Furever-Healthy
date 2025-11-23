import 'package:flutter/material.dart';
import 'package:fureverhealthy/identify_breed.dart';
import 'package:fureverhealthy/my_pets/edit_pet_profile.dart';
import 'package:fureverhealthy/breed_detail_screen.dart';
import 'package:fureverhealthy/services/pet_guide_storage.dart';
import 'package:fureverhealthy/models/pet_breed.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
// 1. IMPORT THE NEW REMINDERS TAB FILE
import 'package:fureverhealthy/reminders_tab.dart';
import 'package:fureverhealthy/recent_notes.dart';
import 'package:fureverhealthy/view_all_notes.dart';
import 'package:fureverhealthy/quick_actions/medications.dart';
import 'package:fureverhealthy/quick_actions/feeding.dart';
import 'package:fureverhealthy/quick_actions/grooming.dart';
// import 'package:fureverhealthy/my_pets/vaccine.dart';
import 'package:fureverhealthy/pet_medical_history.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);

class AllPetsPage extends StatefulWidget {
  const AllPetsPage({super.key});

  @override
  State<AllPetsPage> createState() => _AllPetsPageState();
}

class _AllPetsPageState extends State<AllPetsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPetId;
  Map<String, dynamic>? _selectedPetData;

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

  void _handlePetSelection(QueryDocumentSnapshot<Object?> doc) {
    final rawData = doc.data();
    if (rawData is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(rawData);
      setState(() {
        _selectedPetId = doc.id;
        _selectedPetData = data;
      });
    }
  }

  void _ensureSelectedPet(List<QueryDocumentSnapshot<Object?>> docs) {
    if (docs.isEmpty) {
      if (_selectedPetId != null || _selectedPetData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedPetId = null;
            _selectedPetData = null;
          });
        });
      }
      return;
    }

    final hasSelected =
        _selectedPetId != null && docs.any((doc) => doc.id == _selectedPetId);
    if (!hasSelected) {
      final doc = docs.first;
      final rawData = doc.data();
      if (rawData is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(rawData);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedPetId = doc.id;
            _selectedPetData = data;
          });
        });
      }
    }
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
              // Top bar
              Padding(
                padding: EdgeInsets.only(
                  top: statusBarHeight + 4,
                  left: 8,
                  right: 8,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 26,
                        ),
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
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('petInfos')
                            .where(
                              'userId',
                              isEqualTo:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 96,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return SizedBox(
                              height: 96,
                              child: Center(
                                child: Text(
                                  'Unable to load pets',
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }

                          final docs =
                              snapshot.data?.docs ??
                              <QueryDocumentSnapshot<Object?>>[];
                          _ensureSelectedPet(docs);

                          if (docs.isEmpty) {
                            return SizedBox(
                              height: 96,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _AddCircle(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const IdentifyBreedScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(right: 12),
                              itemCount: docs.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                if (index == docs.length) {
                                  return _AddCircle(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const IdentifyBreedScreen(),
                                      ),
                                    ),
                                  );
                                }

                                final doc = docs[index];
                                final rawData = doc.data();
                                if (rawData is! Map<String, dynamic>) {
                                  return const SizedBox.shrink();
                                }
                                final data = Map<String, dynamic>.from(rawData);
                                final name = (data['name'] as String?)?.trim();
                                final imageUrl = data['imageUrl'] as String?;
                                final imageAsset =
                                    data['imageAsset'] as String?;

                                return _PetCircle(
                                  name: name?.isNotEmpty == true
                                      ? name!
                                      : 'My Pet',
                                  imageUrl: imageUrl,
                                  assetPath: imageAsset,
                                  isSelected: doc.id == _selectedPetId,
                                  onTap: () => _handlePetSelection(doc),
                                );
                              },
                            ),
                          );
                        },
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

              // White container for tab content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ProfileTab(
                        selectedPetId: _selectedPetId,
                        initialPetData: _selectedPetData,
                      ),
                      _AppointmentsTab(
                        selectedPetId: _selectedPetId,
                        selectedPetName: _selectedPetData?['name'] as String?,
                      ),
                      _RemindersTabWrapper(
                        selectedPetId: _selectedPetId,
                        selectedPetName: _selectedPetData?['name'] as String?,
                      ), // Use the new wrapper
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

// ====================== PROFILE TAB ======================
class _ProfileTab extends StatefulWidget {
  final String? selectedPetId;
  final Map<String, dynamic>? initialPetData;

  const _ProfileTab({required this.selectedPetId, this.initialPetData});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  String _petName = 'My Pet';
  String _petBreed = 'Unknown breed';
  String _petGender = 'Unknown';
  String? _petSpecies;
  String? _petWeight;
  DateTime? _petBirthDate;
  String? _petDescription;
  List<String> _medicalConcerns = [];
  String? _imageUrl;
  String? _assetPath;
  String?
  _lastAppliedPetId; // Track last applied pet to avoid unnecessary updates

  @override
  void initState() {
    super.initState();
    // Initialize from initialPetData if available
    if (widget.initialPetData != null) {
      _applyPetData(widget.initialPetData!);
      _lastAppliedPetId = widget.selectedPetId;
    }
  }

  @override
  void didUpdateWidget(_ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update when selected pet changes
    if (oldWidget.selectedPetId != widget.selectedPetId) {
      _lastAppliedPetId = null; // Reset to allow update
      if (widget.initialPetData != null) {
        _applyPetData(widget.initialPetData!);
        _lastAppliedPetId = widget.selectedPetId;
      }
    }
  }

  // ---------- Ongoing Medications Section ----------
  Widget _buildFeedingSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.selectedPetId == null) {
      return _buildCard(
        title: 'Feeding',
        iconPath: 'assets/pet_feeding.png',
        description: 'Plan ${_petName}\'s meals and portion sizes.',
        buttonText: 'Add feeding',
        onPressed: () {
          if (widget.selectedPetId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FeedingPage(petId: widget.selectedPetId, petName: _petName),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FeedingPage()),
            );
          }
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedings')
          .where('userId', isEqualTo: user.uid)
          .where('petId', isEqualTo: widget.selectedPetId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            title: 'Feeding',
            iconPath: 'assets/pet_feeding.png',
            description: 'Plan ${_petName}\'s meals and portion sizes.',
            buttonText: 'Add feeding',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedingPage(
                    petId: widget.selectedPetId,
                    petName: _petName,
                  ),
                ),
              );
            },
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildCard(
            title: 'Feeding',
            iconPath: 'assets/pet_feeding.png',
            description: 'Plan ${_petName}\'s meals and portion sizes.',
            buttonText: 'Add feeding',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedingPage(
                    petId: widget.selectedPetId,
                    petName: _petName,
                  ),
                ),
              );
            },
          );
        }

        // Sort by createdAt in descending order (newest first)
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });

        if (docs.isEmpty) {
          return _buildCard(
            title: 'Feeding',
            iconPath: 'assets/pet_feeding.png',
            description: 'Plan ${_petName}\'s meals and portion sizes.',
            buttonText: 'Add feeding',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedingPage(
                    petId: widget.selectedPetId,
                    petName: _petName,
                  ),
                ),
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Feeding Schedules',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedingPage(
                            petId: widget.selectedPetId,
                            petName: _petName,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Add feeding',
                      style: TextStyle(
                        color: _mint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // List of feeding cards
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final meal = (data['meal'] as String?)?.trim() ?? 'Meal';
              final time = (data['time'] as String?)?.trim() ?? '';
              final notes = (data['notes'] as String?)?.trim() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.restaurant, color: _mint),
                  title: Text(
                    meal,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '$time${notes.isNotEmpty ? '\n$notes' : ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  isThreeLine: notes.isNotEmpty,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildGroomingSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.selectedPetId == null) {
      return _buildCard(
        title: 'Grooming',
        iconPath: 'assets/pet_grooming.png',
        description: 'Set a grooming routine tailored for $_petName.',
        buttonText: 'Add grooming',
        onPressed: () {
          if (widget.selectedPetId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroomingPage(
                  petId: widget.selectedPetId,
                  petName: _petName,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroomingPage()),
            );
          }
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groomings')
          .where('userId', isEqualTo: user.uid)
          .where('petId', isEqualTo: widget.selectedPetId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            title: 'Grooming',
            iconPath: 'assets/pet_grooming.png',
            description: 'Set a grooming routine tailored for $_petName.',
            buttonText: 'Add grooming',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroomingPage(
                    petId: widget.selectedPetId,
                    petName: _petName,
                  ),
                ),
              );
            },
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildCard(
            title: 'Grooming',
            iconPath: 'assets/pet_grooming.png',
            description: 'Set a grooming routine tailored for $_petName.',
            buttonText: 'Add grooming',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroomingPage(
                    petId: widget.selectedPetId,
                    petName: _petName,
                  ),
                ),
              );
            },
          );
        }

        // Sort by createdAt in descending order (newest first)
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });

        if (docs.isEmpty) {
          return _buildCard(
            title: 'Grooming',
            iconPath: 'assets/pet_grooming.png',
            description: 'Set a grooming routine tailored for $_petName.',
            buttonText: 'Add grooming',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroomingPage(
                    petId: widget.selectedPetId,
                    petName: _petName,
                  ),
                ),
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grooming Schedules',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroomingPage(
                            petId: widget.selectedPetId,
                            petName: _petName,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Add grooming',
                      style: TextStyle(
                        color: _mint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // List of grooming cards
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = (data['type'] as String?)?.trim() ?? 'Grooming';
              final date = (data['date'] as String?)?.trim() ?? '';
              final notes = (data['notes'] as String?)?.trim() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.pets, color: _mint),
                  title: Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '$date${notes.isNotEmpty ? '\n$notes' : ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  isThreeLine: notes.isNotEmpty,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildOngoingMedicationsSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildCard(
        title: 'Ongoing Medications',
        iconPath: 'assets/pet_medication.png',
        description: 'Keep track of ongoing medications for $_petName.',
        buttonText: 'Add medication',
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicationsPage(petName: _petName),
            ),
          );
          if (added == true && mounted) setState(() {});
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            title: 'Ongoing Medications',
            iconPath: 'assets/pet_medication.png',
            description: 'Keep track of ongoing medications for $_petName.',
            buttonText: 'Add medication',
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicationsPage(petName: _petName),
                ),
              );
              if (added == true && mounted) setState(() {});
            },
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildCard(
            title: 'Ongoing Medications',
            iconPath: 'assets/pet_medication.png',
            description: 'Keep track of ongoing medications for $_petName.',
            buttonText: 'Add medication',
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicationsPage(petName: _petName),
                ),
              );
              if (added == true && mounted) setState(() {});
            },
          );
        }

        // Filter medications where this pet is selected
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final pets =
              (data['pets'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
          return pets
              .map((p) => p.trim().toLowerCase())
              .contains(_petName.trim().toLowerCase());
        }).toList();

        if (docs.isEmpty) {
          return _buildCard(
            title: 'Ongoing Medications',
            iconPath: 'assets/pet_medication.png',
            description: 'Keep track of ongoing medications for $_petName.',
            buttonText: 'Add medication',
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicationsPage(petName: _petName),
                ),
              );
              if (added == true && mounted) setState(() {});
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Ongoing Medications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // List of medication cards
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] as String?)?.trim() ?? 'Medication';
              final description =
                  (data['description'] as String?)?.trim() ?? '';
              final dosageUnit =
                  (data['dosageUnit'] as String?)?.trim() ?? 'Pill';
              final scheduleType =
                  (data['scheduleType'] as String?)?.trim() ?? 'On Schedule';
              final startDateTs = data['startDate'] as Timestamp?;
              final endDateTs = data['endDate'] as Timestamp?;
              final timings =
                  (data['timings'] as List?)
                      ?.map((t) => Map<String, dynamic>.from(t as Map))
                      .toList() ??
                  <Map<String, dynamic>>[];

              DateTime? nextDateTime;
              int? nextPills;
              if (timings.isNotEmpty) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                // Sort timings by time of day
                timings.sort((a, b) {
                  final aMin = (a['hour'] as int) * 60 + (a['minute'] as int);
                  final bMin = (b['hour'] as int) * 60 + (b['minute'] as int);
                  return aMin.compareTo(bMin);
                });
                // Find first timing later today, else take first timing tomorrow
                DateTime? candidate;
                int? candidatePills;
                for (final t in timings) {
                  final dt = DateTime(
                    today.year,
                    today.month,
                    today.day,
                    (t['hour'] as int),
                    (t['minute'] as int),
                  );
                  if (dt.isAfter(now)) {
                    candidate = dt;
                    candidatePills = (t['pills'] as int?) ?? 1;
                    break;
                  }
                }
                if (candidate == null) {
                  final t = timings.first;
                  candidate = today.add(const Duration(days: 1));
                  candidate = DateTime(
                    candidate.year,
                    candidate.month,
                    candidate.day,
                    (t['hour'] as int),
                    (t['minute'] as int),
                  );
                  candidatePills = (t['pills'] as int?) ?? 1;
                }
                // Respect start/end dates if present
                final startDate = startDateTs?.toDate();
                final endDate = endDateTs?.toDate();
                if (startDate != null && candidate.isBefore(startDate)) {
                  candidate = DateTime(
                    startDate.year,
                    startDate.month,
                    startDate.day,
                    timings.first['hour'] as int,
                    timings.first['minute'] as int,
                  );
                  candidatePills = (timings.first['pills'] as int?) ?? 1;
                }
                if (endDate == null ||
                    candidate.isBefore(endDate) ||
                    candidate.isAtSameMomentAs(endDate)) {
                  nextDateTime = candidate;
                  nextPills = candidatePills;
                }
              }

              String nextLine;
              if (nextDateTime != null && nextPills != null) {
                nextLine =
                    'Next $nextPills $dosageUnit${nextPills == 1 ? '' : 's'}, ${DateFormat('d MMM, h:mm a').format(nextDateTime)}';
              } else {
                nextLine = 'Next schedule not available';
              }

              // First timing for compact row
              String timeAndDose = '';
              if (timings.isNotEmpty) {
                final t = timings.first;
                final dt = DateTime(
                  0,
                  1,
                  1,
                  (t['hour'] as int),
                  (t['minute'] as int),
                );
                final timeStr = DateFormat('h:mm a').format(dt);
                final pills = (t['pills'] as int?) ?? 1;
                timeAndDose = '$timeStr   $pills';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1EDE0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: _mint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.medication,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                if (description.isEmpty) return;
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(name),
                                    content: Text(description),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.black54,
                              ),
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicationsPage(
                                      medicationId: doc.id,
                                      petName: _petName,
                                    ),
                                  ),
                                );
                                if (updated == true && mounted) setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.pets, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          _petName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          scheduleType == 'On Schedule'
                              ? 'Every day'
                              : 'As needed',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            timeAndDose.isNotEmpty ? timeAndDose : 'Set time',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_right_alt,
                          size: 22,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            nextLine,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            // Add new medication button under list
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final added = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicationsPage(petName: _petName),
                    ),
                  );
                  if (added == true && mounted) setState(() {});
                },
                child: const Text(
                  'Add medication',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // ---------- end Ongoing Medications Section ----------

  Widget _buildRecentNotesCard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.selectedPetId == null) {
      return _buildCard(
        title: 'Recent notes',
        iconPath: 'assets/recent_notes.png',
        description:
            'Add a note to record important information about $_petName.',
        buttonText: 'Add note',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecentNotesPage(initialPetName: _petName),
            ),
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('petNotes')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            title: 'Recent notes',
            iconPath: 'assets/recent_notes.png',
            description:
                'Add a note to record important information about $_petName.',
            buttonText: 'Add note',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecentNotesPage(initialPetName: _petName),
                ),
              );
            },
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildCard(
            title: 'Recent notes',
            iconPath: 'assets/recent_notes.png',
            description:
                'Add a note to record important information about $_petName.',
            buttonText: 'Add note',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecentNotesPage(initialPetName: _petName),
                ),
              );
            },
          );
        }

        // Filter notes by pet name and sort by dateTime
        final petNameTrimmed = _petName.trim().toLowerCase();
        final matchingNotes = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final notePetName = (data['petName'] as String?)?.trim() ?? '';
          // Also check createdAt as fallback if dateTime is missing
          return notePetName.toLowerCase() == petNameTrimmed;
        }).toList();

        if (matchingNotes.isEmpty) {
          return _buildCard(
            title: 'Recent notes',
            iconPath: 'assets/recent_notes.png',
            description:
                'Add a note to record important information about $_petName.',
            buttonText: 'Add note',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecentNotesPage(initialPetName: _petName),
                ),
              );
            },
          );
        }

        // Sort by dateTime descending (or createdAt as fallback) and get the most recent one
        matchingNotes.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          // Try dateTime first, then createdAt as fallback
          Timestamp? aTime = aData['dateTime'] as Timestamp?;
          Timestamp? bTime = bData['dateTime'] as Timestamp?;

          if (aTime == null) {
            aTime = aData['createdAt'] as Timestamp?;
          }
          if (bTime == null) {
            bTime = bData['createdAt'] as Timestamp?;
          }

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending order
        });

        final noteDoc = matchingNotes.first;
        final noteData = noteDoc.data() as Map<String, dynamic>;
        final noteId = noteDoc.id;
        final content = noteData['content'] as String? ?? '';
        final dateTime = noteData['dateTime'] as Timestamp?;
        final petName = noteData['petName'] as String? ?? _petName;
        final noteType = noteData['noteType'] as String? ?? 'General';
        final activityType = noteData['activityType'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent notes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewAllNotesPage(petName: _petName),
                        ),
                      ).then((result) {
                        if (result == true) {
                          setState(() {}); // Refresh to show updated note
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecentNotesPage(
                        initialPetName: _petName,
                        noteId: noteId,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      setState(() {}); // Refresh to show updated note
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6F994A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.note,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: Pet Name (BOLD) on left, Note Type/Activity Type on right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    petName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (noteType.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _mint.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          noteType == 'Activity' &&
                                                  activityType != null &&
                                                  activityType.isNotEmpty
                                              ? 'Activity: $activityType'
                                              : noteType,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _mint,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Notes content
                            Text(
                              content.isNotEmpty ? content : 'No content',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Date and Time at bottom
                            if (dateTime != null)
                              Text(
                                DateFormat(
                                  'd MMM, h:mm a',
                                ).format(dateTime.toDate()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String iconPath,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Image.asset(iconPath, width: 40, height: 40, color: _mint),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  void _applyPetData(Map<String, dynamic> data) {
    final name = (data['name'] as String?)?.trim();
    final breed = (data['breed'] as String?)?.trim();
    final gender = (data['gender'] as String?)?.trim();
    final species = (data['speciesType'] as String?)?.trim();
    final weight = (data['weight'] as String?)?.trim();
    final description = (data['description'] as String?)?.trim();
    final concerns = data['medicalConcerns'];
    final birthDate = data['birthDate'];

    _petName = name?.isNotEmpty == true ? name! : _petName;
    _petBreed = breed?.isNotEmpty == true ? breed! : _petBreed;
    _petGender = gender?.isNotEmpty == true ? gender! : _petGender;
    _petSpecies = species?.isNotEmpty == true ? species : _petSpecies;
    _petWeight = weight?.isNotEmpty == true ? weight : null;
    _petDescription = description?.isNotEmpty == true
        ? description
        : _petDescription;
    if (concerns is List) {
      _medicalConcerns = concerns.map((e) => e.toString()).toList();
    } else {
      _medicalConcerns = [];
    }
    if (birthDate is Timestamp) {
      _petBirthDate = birthDate.toDate();
    } else if (birthDate is DateTime) {
      _petBirthDate = birthDate;
    } else {
      _petBirthDate = null;
    }
    _imageUrl = data['imageUrl'] as String?;
    _assetPath = data['imageAsset'] as String?;
  }

  String _petInitial() {
    final trimmed = _petName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Widget _buildInitialAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE8F3D8),
      ),
      alignment: Alignment.center,
      child: Text(
        _petInitial(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _mintDark,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    const double size = 56;

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(size),
        ),
      );
    }

    if (_assetPath != null && _assetPath!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          _assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(size),
        ),
      );
    }

    return _buildInitialAvatar(size);
  }

  Widget _buildProfileAvatarFromData(String? imageUrl, String? assetPath) {
    const double size = 56;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(size),
        ),
      );
    }

    if (assetPath != null && assetPath.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(size),
        ),
      );
    }

    return _buildInitialAvatar(size);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalConcerns() {
    if (_medicalConcerns.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _medicalConcerns
            .map(
              (concern) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _mint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  concern,
                  style: const TextStyle(
                    color: _mintDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat.yMMMMd().format(date);
  }

  Widget _buildDetailsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Breed', _petBreed),
          _buildInfoRow('Gender', _petGender),
          if (_petSpecies != null) _buildInfoRow('Species', _petSpecies!),
          if (_petWeight != null && _petWeight!.isNotEmpty)
            _buildInfoRow('Weight', _petWeight!),
          if (_formatDate(_petBirthDate) != null)
            _buildInfoRow('Birth Date', _formatDate(_petBirthDate)!),
          if (_petDescription != null && _petDescription!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _petDescription!,
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
            ),
          _buildMedicalConcerns(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _viewBreedDetails(context),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('View Breed Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mint,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewBreedDetails(BuildContext context) async {
    // Get pet image if available
    Uint8List? imageBytes;
    final imageUrl = _imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        }
      } catch (e) {
        print('Error loading image: $e');
      }
    }

    // Try to get breed information from PetGuideStorage
    PetBreed? breedInfo;
    final species = _petSpecies;
    final isDog = species?.toLowerCase() == 'dog';
    final breedName = _petBreed.toLowerCase();

    try {
      final overrides = await PetGuideStorage.instance.loadOverrides();
      final breedMap = isDog ? overrides.dogs : overrides.cats;
      breedInfo = breedMap[breedName];
    } catch (e) {
      print('Error loading breed info: $e');
    }

    // Use breed info if available, otherwise use defaults
    final breedGroup = breedInfo?.breedGroup ?? 'Unknown';
    final size = breedInfo?.size ?? 'Unknown';
    final lifeSpan = breedInfo?.lifeSpan ?? 'Unknown';
    final description = breedInfo?.description.isNotEmpty == true
        ? breedInfo!.description
        : 'Breed information for ${_petBreed}.';
    final characteristics = breedInfo?.characteristics ?? <String, int>{};
    final careGuide = breedInfo?.careGuide ?? <String, String>{};

    // Use pet image or create placeholder
    final finalImageBytes = imageBytes ?? Uint8List(0);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BreedDetailScreen(
            imageBytes: finalImageBytes,
            breed: _petBreed,
            breedGroup: breedGroup,
            size: size,
            lifeSpan: lifeSpan,
            description: description,
            characteristics: characteristics,
            careGuide: careGuide,
          ),
        ),
      );
    }
  }

  Widget _buildProfileHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _petName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_petBreed, $_petGender',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPetProfilePage(petName: _petName),
                  ),
                );
                if (result == true) {
                  setState(() {}); // Trigger rebuild
                }
              },
              child: const Text(
                'Edit',
                style: TextStyle(color: _mint, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final petId = widget.selectedPetId;
    if (petId == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'Add a pet to view their profile information.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('petInfos')
          .doc(petId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? data;
        if (snapshot.hasData && snapshot.data?.data() != null) {
          data = Map<String, dynamic>.from(snapshot.data!.data()!);
        } else if (widget.initialPetData != null) {
          data = Map<String, dynamic>.from(widget.initialPetData!);
        }

        // Extract values directly from data for display - don't update instance variables here
        // to avoid lifecycle issues. Instance variables will be updated via didUpdateWidget
        final name = (data?['name'] as String?)?.trim() ?? _petName;
        final breed = (data?['breed'] as String?)?.trim() ?? _petBreed;
        final gender = (data?['gender'] as String?)?.trim() ?? _petGender;
        final imageUrl = data?['imageUrl'] as String?;
        final assetPath = data?['imageAsset'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  _buildProfileAvatarFromData(imageUrl, assetPath),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'My Pet',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$breed, $gender',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditPetProfilePage(petId: petId, petName: name),
                    ),
                  );
                  if (result == true) {
                    if (mounted) setState(() {});
                  }
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(color: _mint, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            _buildProfileHeader(context),
            if (widget.selectedPetId != null) _buildDetailsCard(),
            _buildRecentNotesCard(context),
            _buildFeedingSection(context),
            _buildGroomingSection(context),
            _buildOngoingMedicationsSection(context),
            _buildCard(
              title: 'Medical History',
              iconPath: 'assets/pet_vaccines.png',
              description:
                  'View and manage vaccine and medicine history for $_petName.',
              buttonText: 'View history',
              onPressed: () {
                if (widget.selectedPetId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetMedicalHistoryPage(
                        petId: widget.selectedPetId!,
                        petName: _petName,
                      ),
                    ),
                  );
                }
              },
            ),
            // _buildCard(
            //   title: 'Vaccines',
            //   iconPath: 'assets/pet_vaccines.png',
            //   description:
            //       'Manage upcoming and completed vaccines for $_petName.',
            //   buttonText: 'Add vaccine',
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => VaccinePage(petName: _petName),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}

// ====================== APPOINTMENTS TAB ======================
class _AppointmentsTab extends StatefulWidget {
  final String? selectedPetId;
  final String? selectedPetName;

  const _AppointmentsTab({this.selectedPetId, this.selectedPetName});

  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupAppointmentsByDate(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (var doc in docs) {
      final appointment = doc.data() as Map<String, dynamic>;
      final appointmentId = doc.id;

      DateTime appointmentDate;
      if (appointment['appointmentDateTime'] != null) {
        appointmentDate = (appointment['appointmentDateTime'] as Timestamp)
            .toDate();
      } else if (appointment['date'] != null) {
        appointmentDate = (appointment['date'] as Timestamp).toDate();
      } else {
        continue; // Skip if no date
      }

      // Normalize to date only (remove time)
      final dateOnly = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );

      if (!grouped.containsKey(dateOnly)) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add({...appointment, 'appointmentId': appointmentId});
    }

    return grouped;
  }

  List<Map<String, dynamic>> _filterAppointments(
    List<Map<String, dynamic>> appointments,
  ) {
    final selectedId = widget.selectedPetId?.trim();
    final selectedName = widget.selectedPetName?.trim();

    if ((selectedId == null || selectedId.isEmpty) &&
        (selectedName == null || selectedName.isEmpty)) {
      return appointments;
    }

    return appointments.where((appointment) {
      final appointmentPetId = appointment['petId'];
      final appointmentPetName = appointment['petName'];

      if (selectedId != null &&
          selectedId.isNotEmpty &&
          appointmentPetId != null &&
          appointmentPetId.toString().isNotEmpty) {
        return appointmentPetId == selectedId;
      }

      if (selectedName != null &&
          selectedName.isNotEmpty &&
          appointmentPetName != null &&
          appointmentPetName.toString().isNotEmpty) {
        return appointmentPetName.toString().toLowerCase() ==
            selectedName.toLowerCase();
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view appointments'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_appointments')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/schedule.png',
                  width: 80,
                  height: 80,
                  color: _mint,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No vet appointment scheduled yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Group appointments by date
        final appointmentsMap = _groupAppointmentsByDate(snapshot.data!.docs);

        // Get selected day's appointments (normalize to date only for lookup)
        final selectedDayAppointments = _selectedDay != null
            ? (appointmentsMap[DateTime(
                    _selectedDay!.year,
                    _selectedDay!.month,
                    _selectedDay!.day,
                  )] ??
                  <Map<String, dynamic>>[])
            : <Map<String, dynamic>>[];
        final filteredAppointments = _filterAppointments(
          selectedDayAppointments,
        );

        return Column(
          children: [
            // Calendar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: (day) {
                  // Normalize day to date only
                  final dateOnly = DateTime(day.year, day.month, day.day);
                  return appointmentsMap.containsKey(dateOnly)
                      ? [dateOnly]
                      : [];
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(color: Colors.black87),
                  defaultTextStyle: const TextStyle(color: Colors.black87),
                  selectedDecoration: BoxDecoration(
                    color: _mint,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: _mint.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: _mint,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerSize: 6,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: _mint),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: _mint,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),

            const SizedBox(height: 16),

            // Selected day appointments
            Expanded(
              child: filteredAppointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (widget.selectedPetName?.trim().isNotEmpty ?? false)
                                ? 'No appointments for ${widget.selectedPetName!.trim()} on this day'
                                : 'No appointments on this day',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = filteredAppointments[index];
                        final date = appointment['appointmentDateTime'] != null
                            ? (appointment['appointmentDateTime'] as Timestamp)
                                  .toDate()
                            : (appointment['date'] as Timestamp).toDate();
                        final timeSlot = appointment['timeSlot'] ?? '';
                        final vetName = appointment['vetName'] ?? 'Unknown Vet';
                        final petName = appointment['petName'] ?? 'Unknown';
                        final status = appointment['status'] ?? 'pending';
                        final reason = appointment['reason'] ?? '';

                        // Get status color
                        Color statusColor;
                        switch (status.toString().toLowerCase()) {
                          case 'confirmed':
                            statusColor = Colors.green;
                            break;
                          case 'declined':
                            statusColor = Colors.red;
                            break;
                          case 'cancelled':
                            statusColor = Colors.red;
                            break;
                          case 'completed':
                            statusColor = Colors.blue;
                            break;
                          default:
                            statusColor = Colors.orange;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Time indicator
                              Container(
                                width: 4,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _mint,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Time
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('h:mm a').format(date),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (timeSlot.isNotEmpty)
                                    Text(
                                      timeSlot,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Appointment details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vet Appointment',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pet: $petName',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'Vet: $vetName',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    if (reason.isNotEmpty)
                                      Text(
                                        reason,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  status.toString().toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ====================== REMINDERS TAB WRAPPER (to use the external file) ======================
class _RemindersTabWrapper extends StatelessWidget {
  final String? selectedPetId;
  final String? selectedPetName;

  const _RemindersTabWrapper({this.selectedPetId, this.selectedPetName});

  @override
  Widget build(BuildContext context) {
    // 3. REPLACING THE LOCAL _RemindersTab with a call to the new file's widget
    return RemindersTab(
      selectedPetId: selectedPetId,
      selectedPetName: selectedPetName,
    );
  }
}

// ====================== REUSABLE EMPTY STATE (made public) ======================
// 2. RENAMED FROM _EmptyStateWidget to EmptyStateWidget (removed underscore)
class EmptyStateWidget extends StatelessWidget {
  final String iconPath;
  final String message;
  final String buttonText;
  final VoidCallback onPressed; // This is the original prop

  const EmptyStateWidget({
    super.key,
    required this.iconPath,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 80, height: 80, color: _mint),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onPressed, // Use the passed-in onPressed callback
            style: ElevatedButton.styleFrom(
              backgroundColor: _mint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== PET CIRCLE ======================
class _PetCircle extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? assetPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _PetCircle({
    required this.name,
    this.imageUrl,
    this.assetPath,
    required this.isSelected,
    required this.onTap,
  });

  String _initial() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Widget _buildFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE8F3D8),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial(),
        style: const TextStyle(
          color: _mintDark,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildAvatarImage(double size) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(size),
        ),
      );
    }
    if (assetPath != null && assetPath!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(size),
        ),
      );
    }
    return _buildFallback(size);
  }

  @override
  Widget build(BuildContext context) {
    const double imageSize = 56;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _mint : Colors.transparent,
                width: 2,
              ),
            ),
            child: _buildAvatarImage(imageSize),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? _mintDark : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== ADD NEW PET CIRCLE ======================
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
