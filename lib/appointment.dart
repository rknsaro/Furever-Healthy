import 'package:flutter/material.dart';
import 'package:fureverhealthy/book_appointment.dart';
import 'package:fureverhealthy/vet_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _showAppointments = false; // Toggle between vets and appointments

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  // Load vets from Firestore
  Future<void> _loadVets() async {
    try {
      // Try 'vets' collection first, then 'veterinarians', then 'users' with role='vet'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vets')
          .get();

      // If no results, try 'veterinarians' collection
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('veterinarians')
            .get();
      }

      // If still no results, try 'users' with role='vet'
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'vet')
            .get();
      }

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'vet')
            .get();
      }

      if (mounted) {
        final vets = <Map<String, dynamic>>[];
        final locations = <String>{};
        final specialties = <String>{};

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String status =
              (data['status'] as String?) ??
              (data['availability'] as String?) ??
              (data['availabilityStatus'] as String?) ??
              ((data['isAvailable'] is bool)
                  ? ((data['isAvailable'] as bool)
                        ? 'Available'
                        : 'Unavailable')
                  : null) ??
              'Available';

          final vet = {
            'vetId': doc.id, // Store the document ID as vetId
            'name': data['name'] ?? data['displayName'] ?? 'Unknown Vet',
            'specialty': data['specialty'] ?? 'General',
            'rating': data['rating'] is int
                ? data['rating']
                : (data['rating'] is double
                      ? (data['rating'] as double).round()
                      : 5),
            'location': data['location'] ?? 'Unknown',
            'verified': data['verified'] ?? true,
            'status': status,
          };
          vets.add(vet);

          // Collect unique locations and specialties for filters
          if (vet['location'] != null && vet['location'] != 'Unknown') {
            locations.add(vet['location'] as String);
          }
          if (vet['specialty'] != null) {
            specialties.add(vet['specialty'] as String);
          }
        }

        setState(() {
          allVets = vets;
          // Don't update Location and Specialty - they are fixed
          // filterOptions['Location'] = locations.toList()..sort();
          // filterOptions['Specialty'] = specialties.toList()..sort();
        });
      }
    } catch (e) {
      print('Error loading vets: $e');
      // Keep empty list if there's an error
    }
  }

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

  final List<String> filters = ['Location', 'Specialty', 'Rating'];

  // Available filter options for each filter type
  final Map<String, List<String>> filterOptions = {
    'Location': ['Batangas'],
    'Specialty': ['Pathology', 'Behaviour', 'Dermatology', 'General'],
    'Rating': ['5 Stars', '4 Stars', '3 Stars'],
  };

  List<Map<String, dynamic>> allVets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: const Text(
                'Book an appointment',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _mintDark,
                ),
              ),
            ),

            // Show appointments or vet list based on toggle
            if (_showAppointments)
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Appointments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _mintDark,
                              ),
                            ),
                          ),
                          // Toggle button to go back to vets view
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAppointments = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _mint,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _mint),
                              ),
                              child: const Text(
                                'Back to Vets',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildAppointmentsList(),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filters Section with View Appointments (scrollable)
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
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
                                              color:
                                                  selectedFilterType == filter
                                                  ? _mint
                                                  : Colors.grey.shade400,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Text(
                                            filter,
                                            style: TextStyle(
                                              color:
                                                  selectedFilterType == filter
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // View Appointments button
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showAppointments = true;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _showAppointments
                                              ? _mint
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: _showAppointments
                                                ? _mint
                                                : Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Text(
                                          'View Appointments',
                                          style: TextStyle(
                                            color: _showAppointments
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (selectedFilterType != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFilterType = null;
                                    selectedFilterValue = null;
                                  });
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: Colors.red,
                                ),
                              ),
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
                            : 'Available Veterinarians',
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
                            vet['status'] as String? ?? 'Available',
                            vet['vetId'] as String,
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build appointments list for current user
  Widget _buildAppointmentsList() {
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
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No appointments found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Sort appointments by appointmentDateTime in memory
        final appointments = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aDate =
                (aData['appointmentDateTime'] as Timestamp?)?.toDate() ??
                (aData['date'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final bDate =
                (bData['appointmentDateTime'] as Timestamp?)?.toDate() ??
                (bData['date'] as Timestamp?)?.toDate() ??
                DateTime.now();

            return aDate.compareTo(bDate);
          });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment =
                appointments[index].data() as Map<String, dynamic>;
            final appointmentId = appointments[index].id;

            return _buildAppointmentCard(appointment, appointmentId);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    String appointmentId,
  ) {
    final date =
        (appointment['appointmentDateTime'] as Timestamp?)?.toDate() ??
        (appointment['date'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final status = appointment['status'] ?? 'pending';
    final petName = appointment['petName'] ?? 'Unknown';
    final userName = appointment['userName'] ?? 'Unknown User';
    final userEmail = appointment['userEmail'] ?? '';
    final vetName = appointment['vetName'] ?? 'Unknown Vet';
    final vetSpecialty = appointment['vetSpecialty'] ?? '';
    final timeSlot = appointment['timeSlot'] ?? '';
    final reason = appointment['reason'] ?? '';
    final cost = appointment['cost'] ?? 0;
    final appointmentType = appointment['appointmentType'] ?? 'In person';

    // Normalize status to lowercase for comparison
    final normalizedStatus = status.toString().toLowerCase();

    Color statusColor;
    String displayStatus;
    switch (normalizedStatus) {
      case 'confirmed':
        statusColor = Colors.green;
        displayStatus = 'Confirmed';
        break;
      case 'declined':
        statusColor = Colors.red;
        displayStatus = 'Declined';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        displayStatus = 'Cancelled';
        break;
      case 'completed':
        statusColor = Colors.blue;
        displayStatus = 'Completed';
        break;
      case 'pending':
        statusColor = Colors.orange;
        displayStatus = 'Pending';
        break;
      default:
        // If status is not one of the allowed values, show as pending
        statusColor = Colors.orange;
        displayStatus = 'Pending';
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet and Owner Info with status on the right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pets, color: _mint, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pet: $petName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _mintDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (userEmail.isNotEmpty)
                      Text(
                        userEmail,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vet Info
          Row(
            children: [
              const Icon(Icons.local_hospital, color: _mint, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vetName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      vetSpecialty,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Appointment Details
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.calendar_today,
                  DateFormat('MMM d, yyyy').format(date),
                ),
              ),
              Expanded(child: _buildInfoItem(Icons.access_time, timeSlot)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.category, reason)),
              Expanded(
                child: _buildInfoItem(Icons.type_specimen, appointmentType),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cost
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Cost:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                'PHP $cost',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _mint,
                ),
              ),
            ],
          ),

          // Online Consultation Join Button or Waiting Message
          if (appointmentType.toLowerCase().contains('online') ||
              appointmentType == 'Online Consultation') ...[
            const Divider(height: 24),
            _buildOnlineConsultationSection(
              normalizedStatus,
              appointment['meetingLink'] as String?,
            ),
          ],

          // Feedback section for completed appointments
          if (normalizedStatus == 'completed') ...[
            const Divider(height: 24),
            _buildFeedbackSection(appointmentId, appointment),
          ],
        ],
      ),
    );
  }

  Widget _buildOnlineConsultationSection(String status, String? meetingLink) {
    if (status == 'pending') {
      // Show waiting message when status is pending
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Waiting for vet confirmation...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'confirmed') {
      // Show Join Consultation button when confirmed
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _joinOnlineMeeting(meetingLink),
          icon: const Icon(Icons.video_camera_front, color: Colors.white),
          label: const Text(
            'Join Consultation',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _mint,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    } else {
      // For other statuses (declined, cancelled, completed), don't show anything
      return const SizedBox.shrink();
    }
  }

  Future<void> _joinOnlineMeeting(String? meetingLink) async {
    if (meetingLink == null || meetingLink.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Meeting link not available. Please contact the vet.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final Uri url = Uri.parse(meetingLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open meeting link. Please check the link.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening meeting: $e')));
      }
    }
  }

  Widget _buildFeedbackSection(
    String appointmentId,
    Map<String, dynamic> appointment,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        // Check if feedback already exists
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final feedbackData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          return _buildExistingFeedback(feedbackData);
        }

        // Show feedback form if no feedback exists
        return _FeedbackForm(
          appointmentId: appointmentId,
          userName: appointment['userName'] ?? 'Unknown User',
          vetName: appointment['vetName'] ?? 'Unknown Vet',
        );
      },
    );
  }

  Widget _buildExistingFeedback(Map<String, dynamic> feedbackData) {
    final rating = feedbackData['rating'] as int? ?? 0;
    final feedbackText = feedbackData['Feedback'] as String? ?? '';
    final date = feedbackData['date'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mint.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _mint.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Feedback',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _mintDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          if (feedbackText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              feedbackText,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
          if (date != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(date.toDate()),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Removed appointment actions - users can only view status
  // Vets will manage status through their own interface

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
    String status,
    String vetId,
  ) {
    final String normalizedStatus = status.trim().isEmpty
        ? 'Available'
        : status.trim();
    final bool isUnavailable = normalizedStatus.toLowerCase() == 'unavailable';
    final Color statusColor = isUnavailable ? Colors.red : Colors.green;
    final int ratingClamped = rating.clamp(0, 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _mint.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFFDFFCF4), Color(0xBFB9E591)],
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/vet_doctor.png',
                      // fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          alignment: Alignment.center,
                          // child: Icon(
                          //   Icons.person,
                          //   color: _mintDark.withOpacity(0.6),
                          //   size: 24,
                          // ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < ratingClamped ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _mintDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: _mint,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Text(
                                  'License Verified',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '(',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                Icon(Icons.verified, color: _mint, size: 16),
                                Text(
                                  ')',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: statusColor, size: 10),
                            const SizedBox(width: 6),
                            Text(
                              normalizedStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _mint,
                              side: const BorderSide(color: _mint),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VetProfilePage(
                                    vetId: vetId,
                                    vetName: name,
                                    vetSpecialty: specialty,
                                    vetRating: rating,
                                    vetLocation: location,
                                  ),
                                ),
                              );
                            },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'View Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUnavailable
                                  ? Colors.grey.shade400
                                  : _mint,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              minimumSize: const Size.fromHeight(46),
                            ),
                            onPressed: isUnavailable
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookAppointmentPage(
                                              vetId: vetId,
                                              vetName: name,
                                              vetSpecialty: specialty,
                                              vetRating: rating,
                                              vetStatus: normalizedStatus,
                                            ),
                                      ),
                                    );
                                  },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Book Now',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isUnavailable)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Currently unavailable',
                        style: TextStyle(
                          color: Colors.red,
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
      ),
    );
  }
}

// Feedback Form Widget
class _FeedbackForm extends StatefulWidget {
  final String appointmentId;
  final String userName;
  final String vetName;

  const _FeedbackForm({
    required this.appointmentId,
    required this.userName,
    required this.vetName,
  });

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'appointmentId': widget.appointmentId,
        'rating': _rating,
        'Name': _nameController.text.trim(),
        'Feedback': _feedbackController.text.trim(),
        'date': Timestamp.now(),
        'vetName': widget.vetName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mint.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _mint.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share Your Feedback',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _mintDark,
            ),
          ),
          const SizedBox(height: 12),

          // Star Rating
          const Text(
            'Rating:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                child: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Name field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Feedback text field
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Feedback',
              hintText: 'Share your experience...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              setState(() {}); // Update counter
            },
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) {
                  return Text(
                    '$currentLength/$maxLength',
                    style: TextStyle(
                      color: currentLength > maxLength!
                          ? Colors.red
                          : Colors.grey,
                    ),
                  );
                },
          ),
          const SizedBox(height: 12),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: _mint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Feedback',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
