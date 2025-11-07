import 'package:flutter/material.dart';
import 'package:fureverhealthy/my_pets/add_new_pet.dart';
import 'package:fureverhealthy/appointment.dart';
import 'package:fureverhealthy/my_pets/edit_pet_profile.dart';
// 1. IMPORT THE NEW REMINDERS TAB FILE
import 'package:fureverhealthy/reminders_tab.dart';
import 'package:fureverhealthy/recent_notes.dart';
import 'package:fureverhealthy/my_pets/vaccine.dart';
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
                          String petName = 'Spencer';
                          String petImage = 'assets/spencer.jpeg';

                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            // Try to find Spencer first, otherwise use the first pet
                            QueryDocumentSnapshot petDoc =
                                snapshot.data!.docs.first;

                            // Look for Spencer
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] as String?;
                              if (name != null &&
                                  name.toLowerCase() == 'spencer') {
                                petDoc = doc;
                                break;
                              }
                            }

                            final data = petDoc.data() as Map<String, dynamic>;
                            petName = data['name'] as String? ?? 'Spencer';
                            petImage =
                                data['imageAsset'] as String? ??
                                'assets/spencer.jpeg';
                          }

                          return Row(
                            children: [
                              _PetCircle(name: petName, imagePath: petImage),
                              const SizedBox(width: 12),
                              _AddCircle(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddNewPetPage(),
                                  ),
                                ),
                              ),
                            ],
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
                      _ProfileTab(),
                      const _AppointmentsTab(),
                      const _RemindersTabWrapper(), // Use the new wrapper
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
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  String _petName = 'Spencer';
  String _petBreed = 'Golden Retriever';
  String _petGender = 'Male';

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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('petInfos')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String displayName = _petName;
        String displayBreed = _petBreed;
        String displayGender = _petGender;

        if (snapshot.hasError) {
          print('Error loading pets: ${snapshot.error}');
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // Try to find Spencer first, otherwise use the first pet
          QueryDocumentSnapshot petDoc = snapshot.data!.docs.first;

          // Look for Spencer
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] as String?;
            if (name != null && name.toLowerCase() == 'spencer') {
              petDoc = doc;
              break;
            }
          }

          final data = petDoc.data() as Map<String, dynamic>;
          displayName = data['name'] as String? ?? _petName;
          displayBreed = data['breed'] as String? ?? _petBreed;
          displayGender = data['gender'] as String? ?? _petGender;

          print('Loaded pet data: $displayName, $displayBreed, $displayGender');
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          // Keep default values while loading
          print('Loading pet data...');
        } else if (snapshot.connectionState == ConnectionState.done &&
            (!snapshot.hasData || snapshot.data!.docs.isEmpty)) {
          print('No pet data found in database');
        }

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
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$displayBreed, $displayGender',
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
                          EditPetProfilePage(petName: displayName),
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
            _buildCard(
              title: 'Recent notes',
              iconPath: 'assets/recent_notes.png',
              description:
                  'Add a note to record important information, details or events.',
              buttonText: 'Add note',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecentNotesPage()),
                );
              },
            ),
            _buildCard(
              title: 'Grooming',
              iconPath: 'assets/pet_grooming.png',
              description:
                  'Set a schedule for your pet’s routine care and maintenance.',
              buttonText: 'Add grooming',
              onPressed: () {},
            ),
            _buildCard(
              title: 'Feeding',
              iconPath: 'assets/pet_feeding.png',
              description:
                  'Set a schedule for your pet’s daily meals and portion sizes.',
              buttonText: 'Add feeding',
              onPressed: () {},
            ),
            _buildCard(
              title: 'Ongoing Medications',
              iconPath: 'assets/pet_medication.png',
              description: 'Keep track of ongoing medications.',
              buttonText: 'Add medication',
              onPressed: () {},
            ),
            _buildCard(
              title: 'Vaccines',
              iconPath: 'assets/pet_vaccines.png',
              description: 'There are no vaccines to display.',
              buttonText: 'Add vaccine',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VaccinePage(petName: 'Spencer'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== APPOINTMENTS TAB ======================
class _AppointmentsTab extends StatefulWidget {
  const _AppointmentsTab();

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
          return EmptyStateWidget(
            iconPath: 'assets/schedule.png',
            message: 'No vet appointment scheduled yet.',
            buttonText: 'Add appointment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentPage(),
                ),
              );
            },
          );
        }

        // Group appointments by date
        final appointmentsMap = _groupAppointmentsByDate(snapshot.data!.docs);

        // Get selected day's appointments (normalize to date only for lookup)
        final selectedDayAppointments = _selectedDay != null
            ? appointmentsMap[DateTime(
                    _selectedDay!.year,
                    _selectedDay!.month,
                    _selectedDay!.day,
                  )] ??
                  []
            : [];

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
              child: selectedDayAppointments.isEmpty
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
                            'No appointments on this day',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: selectedDayAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = selectedDayAppointments[index];
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
  const _RemindersTabWrapper();

  @override
  Widget build(BuildContext context) {
    // 3. REPLACING THE LOCAL _RemindersTab with a call to the new file's widget
    return RemindersTab(
      // We pass the required props to keep the logic here
      // The button pressed logic is now inside RemindersTab
      iconPath: 'assets/reminders.png',
      message: 'No reminders for now. Want to set one up?',
      buttonText: 'Add reminder',
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
            color: Color(0xBFB9E591),
          ),
          child: ClipOval(
            child: imagePath.startsWith('assets/')
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/dog.png', fit: BoxFit.contain);
                    },
                  )
                : Image.asset('assets/dog.png', fit: BoxFit.contain),
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
