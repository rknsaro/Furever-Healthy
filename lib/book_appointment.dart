import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fureverhealthy/utils/vet_services_parser.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);
const _screenBg = Color(0xFFF6F8FB);

class BookAppointmentPage extends StatefulWidget {
  final String vetId;
  final String vetName;
  final String vetSpecialty;
  final int vetRating;
  final String vetStatus;
  final String? profileImageUrl;

  const BookAppointmentPage({
    super.key,
    required this.vetId,
    required this.vetName,
    required this.vetSpecialty,
    required this.vetRating,
    required this.vetStatus,
    this.profileImageUrl,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  String? _selectedPetId;
  String? _selectedPetName;
  String? selectedReason;
  int? estimatedCost;
  String? selectedTime;
  DateTime selectedDate = DateTime.now();

  final List<Map<String, String>> _userPets = [];
  bool _isLoadingPets = false;
  String? _petLoadError;

  List<Map<String, dynamic>> reasons = [];
  bool _isLoadingReasons = false;

  List<String> morningTimes = [
    '8:00 - 9:00 AM',
    '9:00 - 10:00 AM',
    '10:00 - 11:00 AM',
    '11:00 - 12:00 PM',
  ];
  List<String> afternoonTimes = [
    '1:00 - 2:00 PM',
    '2:00 - 3:00 PM',
    '3:00 - 4:00 PM',
    '4:00 - 5:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPets();
    _loadReasonsFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: _mint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book an Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/notif_bell.png', width: 26),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Vet Card
              _buildSelectedVetCard(),
              const SizedBox(height: 24),

              // Appointment form
              _buildFormSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedVetCard() {
    final String normalizedStatus = widget.vetStatus.trim().isEmpty
        ? 'Available'
        : widget.vetStatus.trim();
    final bool isUnavailable = normalizedStatus.toLowerCase() == 'unavailable';
    final Color statusColor = isUnavailable ? Colors.red : Colors.green;

    return Container(
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
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vets')
            .doc(widget.vetId)
            .snapshots(),
        builder: (context, snapshot) {
          String? profileImageUrl = widget.profileImageUrl;
          
          if (profileImageUrl == null && snapshot.hasData && snapshot.data!.exists) {
            final vetData = snapshot.data!.data() as Map<String, dynamic>;
            profileImageUrl = vetData['profileImageUrl'] as String?;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vet profile image
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: _mint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? Image.network(
                          profileImageUrl,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 30, color: _mintDark);
                          },
                        )
                      : const Icon(Icons.person, size: 30, color: _mintDark),
                ),
              ),
              const SizedBox(width: 15),

              // Vet info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 5 Star Rating
                    Row(
                      children: List.generate(
                        widget.vetRating,
                        (index) =>
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Status
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          'Status: $normalizedStatus',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Name
                    Text(
                      widget.vetName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _mintDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Specialty
                    Text(
                      widget.vetSpecialty,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              // Right arrow icon
              const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormSection() {
    final bool isVetUnavailable =
        widget.vetStatus.trim().toLowerCase() == 'unavailable';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pets Section
        const Text('Pets', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildPetSelector(),
        const SizedBox(height: 20),

        // Select Date
        const Text(
          'Select Date',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _calendar(),
        const SizedBox(height: 20),

        // Appointment Time
        const Text(
          'Appointment time',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildTimeGrid(),
        const SizedBox(height: 20),

        // Reason Section
        const Text(
          'Reason',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildReasonDropdown(),
        const SizedBox(height: 20),

        // Appointment Summary
        _summaryCard(),
        const SizedBox(height: 20),

        if (isVetUnavailable) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Text(
              'This veterinarian is currently unavailable. Please choose another vet or try again later.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => _showCancelDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVetUnavailable
                  ? null
                  : () async {
                      // Validate all required fields
                      List<String> missingFields = [];

                      if (_selectedPetId == null) {
                        missingFields.add('Pet');
                      }
                      if (selectedTime == null) {
                        missingFields.add('Appointment Time');
                      }
                      if (selectedReason == null) {
                        missingFields.add('Reason');
                      }

                      if (missingFields.isEmpty) {
                        // All fields are filled, proceed with booking
                        try {
                          await _saveAppointmentToFirestore();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Appointment booked! Waiting for vet confirmation.',
                                ),
                                backgroundColor: _mint,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error booking appointment: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      } else {
                        // Show error message with missing fields
                        String message =
                            'Please fill in the following fields: ${missingFields.join(', ')}';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _mint,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPetSelector() {
    if (_isLoadingPets) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _mint),
          ),
        ),
      );
    }

    if (_petLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _petLoadError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadUserPets,
              icon: const Icon(Icons.refresh, color: _mint),
              label: const Text(
                'Retry',
                style: TextStyle(color: _mint, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_userPets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'No pets found. Please add a pet profile before booking.',
          style: TextStyle(color: Colors.black87, fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedPetId,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: _userPets.map((pet) {
        final petName = pet['name'] ?? 'Unnamed Pet';
        final petId = pet['id'] ?? '';
        return DropdownMenuItem(value: petId, child: Text(petName));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPetId = value;
          _selectedPetName = _userPets.firstWhere(
            (pet) => pet['id'] == value,
            orElse: () => {'name': 'Unnamed Pet'},
          )['name'];
        });
      },
      hint: const Text('Select Pet'),
    );
  }

  Widget _calendar() {
    return CalendarDatePicker(
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years ahead
      onDateChanged: (date) => setState(() => selectedDate = date),
    );
  }

  Widget _buildTimeGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Morning Section
        const Text(
          'Morning',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: morningTimes.length,
          itemBuilder: (context, index) {
            final time = morningTimes[index];
            final bool selected = selectedTime == time;
            return GestureDetector(
              onTap: () => setState(() => selectedTime = time),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _mint : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? _mint : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Afternoon Section
        const Text(
          'Afternoon',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: afternoonTimes.length,
          itemBuilder: (context, index) {
            final time = afternoonTimes[index];
            final bool selected = selectedTime == time;
            return GestureDetector(
              onTap: () => setState(() => selectedTime = time),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _mint : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? _mint : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _mintDark,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Pet:', _selectedPetName ?? '-'),
          _summaryRow('Reason:', selectedReason ?? '-'),
          _summaryRow(
            'Date & Time:',
            '${DateFormat('MMM d, yyyy').format(selectedDate)}, ${selectedTime ?? '-'}',
          ),
          _summaryRow(
            'Estimated Cost:',
            estimatedCost != null ? 'PHP $estimatedCost' : '-',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  // Save appointment to Firestore
  Future<void> _saveAppointmentToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Combine date and time for appointment datetime
    final appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _parseHourFromTime(selectedTime!),
      _parseMinuteFromTime(selectedTime!),
    );

    // Get appointment data
    final appointmentData = {
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': user.displayName ?? '',
      'petId': _selectedPetId,
      'petName': _selectedPetName!,
      'vetId': widget.vetId,
      'vetName': widget.vetName,
      'vetSpecialty': widget.vetSpecialty,
      'vetRating': widget.vetRating,
      'appointmentType': 'In person',
      'date': Timestamp.fromDate(selectedDate),
      'timeSlot': selectedTime,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'reason': selectedReason!,
      'cost': estimatedCost ?? 0,
      'status':
          'pending', // pending, declined, confirmed, cancelled (only vets can change)
      'createdAt': Timestamp.now(),
      'dismissedNotifications': <String>[],
    };

    // Save to user_appointments collection
    final docRef = await FirebaseFirestore.instance
        .collection('user_appointments')
        .add(appointmentData);

    await _createOrUpdateNotificationForAppointment(docRef.id, appointmentData);
  }

  // Helper methods to parse time string
  int _parseHourFromTime(String time) {
    // Format: "8:00 - 9:00 AM" or "1:00 - 2:00 PM"
    final parts = time.split(' ')[0].split(':');
    int hour = int.parse(parts[0]);
    final isPM = time.contains('PM');
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    return hour;
  }

  int _parseMinuteFromTime(String time) {
    final parts = time.split(' ')[0].split(':');
    return int.parse(parts[1]);
  }


  Future<void> _loadReasonsFromDatabase() async {
    setState(() {
      _isLoadingReasons = true;
    });

    try {
      List<Map<String, dynamic>> allReasons = [];
      DocumentSnapshot? settingsDoc;
      Map<String, dynamic>? vetData;

      // FIRST: Try to fetch directly from the vet's document in 'vets' collection
      // This is where the vet's own prices and appointment reasons should be stored
      final vetDoc = await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .get();

      if (vetDoc.exists) {
        vetData = vetDoc.data();
        debugPrint('Loaded vet document: ${vetDoc.id}');
        debugPrint('Vet document fields: ${vetData?.keys.toList()}');
        debugPrint('Vet document data: $vetData');
        
        // Check if vet document has appointment reasons or prices
        // Look for common field names: appointmentReasons, reasons, services, prices, etc.
        if (vetData != null) {
          // Try to find reasons in the vet document
          if (vetData.containsKey('appointmentReasons')) {
            final vetReasons = vetData['appointmentReasons'] as List<dynamic>?;
            if (vetReasons != null && vetReasons.isNotEmpty) {
              allReasons = vetReasons.map((r) {
                if (r is Map) {
                  // Preserve ALL fields from the reason object
                  return Map<String, dynamic>.from(r);
                }
                return {'label': r.toString(), 'price': 0};
              }).toList();
            }
          } else if (vetData.containsKey('reasons')) {
            final vetReasons = vetData['reasons'] as List<dynamic>?;
            if (vetReasons != null && vetReasons.isNotEmpty) {
              allReasons = vetReasons.map((r) {
                if (r is Map) {
                  return Map<String, dynamic>.from(r);
                }
                return {'label': r.toString(), 'price': 0};
              }).toList();
            }
          } else if (vetData.containsKey('services')) {
            final vetServices = vetData['services'];
            if (vetServices is Map) {
              // Parse nested services structure
              allReasons.addAll(VetServicesParser.parseNestedServices(
                Map<String, dynamic>.from(vetServices)
              ));
            } else if (vetServices is List && vetServices.isNotEmpty) {
              // Handle list format
              allReasons = vetServices.map((r) {
                if (r is Map) {
                  return Map<String, dynamic>.from(r);
                }
                return {'label': r.toString(), 'price': 0};
              }).toList();
            }
          } else if (vetData.containsKey('prices')) {
            // If prices is a map, convert it to a list of reasons
            final prices = vetData['prices'];
            if (prices is Map && prices.isNotEmpty) {
              allReasons = (prices as Map<String, dynamic>).entries.map((entry) {
                final result = <String, dynamic>{
                  'label': entry.key,
                  'price': entry.value is num ? entry.value : 0,
                };
                if (entry.value is Map) {
                  result.addAll(Map<String, dynamic>.from(entry.value as Map));
                }
                return result;
              }).toList();
            }
          }
          
          // If no structured reasons found, look for any list fields that might contain reasons
          if (allReasons.isEmpty) {
            for (var entry in vetData.entries) {
              if (entry.value is List && (entry.value as List).isNotEmpty) {
                final listValue = entry.value as List<dynamic>;
                // Check if it looks like a list of reasons (contains maps)
                if (listValue.isNotEmpty && listValue.first is Map) {
                  allReasons = listValue.map((r) {
                    if (r is Map) {
                      return Map<String, dynamic>.from(r);
                    }
                    return {'label': r.toString(), 'price': 0};
                  }).toList();
                  break;
                }
              }
            }
          }
        }
      }

      // SECOND: Try app_settings collection with vet_rates_{vetId} format
      // This is the PRIMARY location for vet-specific rates (as shown in Firestore console)
      // Try multiple methods to find the document
      DocumentSnapshot? foundDoc;
      
      // Method 1: Try document ID format: vet_rates_{vetId}
      settingsDoc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('vet_rates_${widget.vetId}')
          .get();
      
      if (settingsDoc.exists) {
        foundDoc = settingsDoc;
        debugPrint('Found vet_rates document by ID: vet_rates_${widget.vetId}');
      } else {
        // Method 2: Query by vetId field
        debugPrint('Document not found by ID, querying by vetId field...');
        final querySnapshot = await FirebaseFirestore.instance
            .collection('app_settings')
            .where('vetId', isEqualTo: widget.vetId)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          foundDoc = querySnapshot.docs.first;
          debugPrint('Found document by vetId field: ${foundDoc.id}');
        } else {
          // Method 3: Try just the vetId as document ID
          settingsDoc = await FirebaseFirestore.instance
              .collection('app_settings')
              .doc(widget.vetId)
              .get();
          
          if (settingsDoc.exists) {
            foundDoc = settingsDoc;
            debugPrint('Found document by vetId as ID: ${widget.vetId}');
          }
        }
      }

      // If vet_rates document exists, parse it (even if we found some reasons in vet document)
      // This ensures we get all the structured rates
      if (foundDoc != null && foundDoc.exists) {
        final data = foundDoc.data() as Map<String, dynamic>;
        
        // Debug: Log all fields in the document
        debugPrint('=== LOADED VET RATES DOCUMENT ===');
        debugPrint('Document ID: ${foundDoc.id}');
        debugPrint('Document fields: ${data.keys.toList()}');
        debugPrint('Full document data: $data');
        
        // Verify vetId matches if field exists
        if (data.containsKey('vetId')) {
          final docVetId = data['vetId'] as String?;
          debugPrint('Document vetId: $docVetId, Expected: ${widget.vetId}');
          if (docVetId != null && docVetId != widget.vetId) {
            debugPrint('WARNING: vetId mismatch! Skipping this document.');
          } else {
            // Parse all services using shared utility
            final parsedServices = VetServicesParser.parseVetRatesDocument(data);
            debugPrint('Parsed ${parsedServices.length} services from document');
            allReasons.addAll(parsedServices);
          }
        } else {
          // No vetId field, parse anyway (might be the right document)
          final parsedServices = VetServicesParser.parseVetRatesDocument(data);
          debugPrint('Parsed ${parsedServices.length} services from document (no vetId field)');
          allReasons.addAll(parsedServices);
        }
      } else if (allReasons.isEmpty) {
        debugPrint('No vet_rates document found for vetId: ${widget.vetId}');
        // Fallback: Try other document formats only if vet_rates doesn't exist
        // Try document ID as the vetId in app_settings
        settingsDoc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc(widget.vetId)
            .get();

        // Try with 'appointment_reasons_' prefix
        if (!settingsDoc.exists) {
          settingsDoc = await FirebaseFirestore.instance
              .collection('app_settings')
              .doc('appointment_reasons_${widget.vetId}')
              .get();
        }

        // FOURTH: Fall back to global appointment_reasons document
        if (!settingsDoc.exists) {
          settingsDoc = await FirebaseFirestore.instance
              .collection('app_settings')
              .doc('appointment_reasons')
              .get();
        }

        if (settingsDoc.exists) {
          final data = settingsDoc.data() as Map<String, dynamic>;
          
          // Debug: Log all fields in the document
          debugPrint('Loaded app_settings document: ${settingsDoc.id}');
          debugPrint('Document fields: ${data.keys.toList()}');
          debugPrint('Document data: $data');

          // Parse all services using shared utility
          allReasons.addAll(VetServicesParser.parseVetRatesDocument(data));

          // Fallback: If no services found, try old format (rating-based or list-based)
          if (allReasons.isEmpty) {
            final ratingKey = 'rating_${widget.vetRating}';
            if (data.containsKey(ratingKey)) {
              final ratingReasons = data[ratingKey] as List<dynamic>?;
              if (ratingReasons != null && ratingReasons.isNotEmpty) {
                allReasons = ratingReasons.map((r) {
                  if (r is Map) {
                    return Map<String, dynamic>.from(r);
                  }
                  return {'label': r.toString(), 'price': 0};
                }).toList();
              }
            }

            if (allReasons.isEmpty && data.containsKey('default')) {
              final defaultReasons = data['default'] as List<dynamic>?;
              if (defaultReasons != null && defaultReasons.isNotEmpty) {
                allReasons = defaultReasons.map((r) {
                  if (r is Map) {
                    return Map<String, dynamic>.from(r);
                  }
                  return {'label': r.toString(), 'price': 0};
                }).toList();
              }
            }

            if (allReasons.isEmpty && data.containsKey('reasons')) {
              final reasonsList = data['reasons'] as List<dynamic>?;
              if (reasonsList != null && reasonsList.isNotEmpty) {
                allReasons = reasonsList.map((r) {
                  if (r is Map) {
                    return Map<String, dynamic>.from(r);
                  }
                  return {'label': r.toString(), 'price': 0};
                }).toList();
              }
            }
          }
        }
      }

      // Debug: Log extracted reasons
      debugPrint('Extracted ${allReasons.length} reasons from vetId: ${widget.vetId}');
      for (var i = 0; i < allReasons.length; i++) {
        debugPrint('Reason $i: ${allReasons[i]}');
      }

      // Set the reasons (whether from vet document or app_settings)
      if (allReasons.isNotEmpty) {
        setState(() {
          reasons = allReasons;
          _isLoadingReasons = false;
        });
      } else {
        // Fallback to default reasons if settings don't exist
        setState(() {
          reasons = [
            {'label': 'Regular Check-up', 'price': 800},
            {'label': 'Grooming', 'price': 500},
            {'label': 'Vaccination', 'price': 300},
            {'label': 'Emergency', 'price': 1500},
            {'label': 'Consultation', 'price': 500},
          ];
          _isLoadingReasons = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reasons from database: $e');
      // Fallback to default reasons on error
      setState(() {
        reasons = [
          {'label': 'Regular Check-up', 'price': 800},
          {'label': 'Grooming', 'price': 500},
          {'label': 'Vaccination', 'price': 300},
          {'label': 'Emergency', 'price': 1500},
          {'label': 'Consultation', 'price': 500},
        ];
        _isLoadingReasons = false;
      });
    }
  }

  Widget _buildReasonDropdown() {
    if (_isLoadingReasons) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _mint),
          ),
        ),
      );
    }

    if (reasons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'No reasons available. Please try again later.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      hint: const Text('Select reason'),
      items: reasons.map((r) {
        final label = r['label'] as String? ?? 
                     r['name'] as String? ?? 
                     r['title'] as String? ?? 
                     r['reason'] as String? ?? 
                     'Unknown';
        final price = (r['price'] as num?)?.toInt() ?? 
                     (r['cost'] as num?)?.toInt() ?? 
                     (r['amount'] as num?)?.toInt() ?? 
                     0;
        
        // Build display text with all available information
        String displayText = label;
        
        // Add price if available
        if (price > 0) {
          displayText += ' - PHP $price';
        }
        
        // Add description if available
        final description = r['description'] as String? ?? 
                          r['desc'] as String? ?? 
                          r['details'] as String?;
        if (description != null && description.isNotEmpty) {
          displayText += '\n$description';
        }
        
        // Add duration if available
        final duration = r['duration'] as String? ?? 
                        r['time'] as String?;
        if (duration != null && duration.isNotEmpty) {
          displayText += ' (Duration: $duration)';
        }
        
        return DropdownMenuItem<String>(
          value: label,
          child: Text(
            displayText,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        final selected = reasons.firstWhere(
          (r) {
            final label = r['label'] as String? ?? 
                         r['name'] as String? ?? 
                         r['title'] as String? ?? 
                         r['reason'] as String? ?? 
                         '';
            return label == value;
          },
          orElse: () => {'price': 0},
        );
        setState(() {
          selectedReason = value;
          // Try multiple price field names
          estimatedCost = (selected['price'] as num?)?.toInt() ?? 
                        (selected['cost'] as num?)?.toInt() ?? 
                        (selected['amount'] as num?)?.toInt();
        });
      },
      value: selectedReason,
    );
  }

  Future<void> _loadUserPets() async {
    setState(() {
      _isLoadingPets = true;
      _petLoadError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingPets = false;
          _userPets.clear();
          _selectedPetId = null;
          _selectedPetName = null;
          _petLoadError = 'Please sign in to view your pets.';
        });
        return;
      }

      final baseQuery = FirebaseFirestore.instance
          .collection('petInfos')
          .where('userId', isEqualTo: user.uid);

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await baseQuery.orderBy('name').get();
      } on FirebaseException catch (orderError) {
        // Missing index or other ordering issue—retry without ordering.
        debugPrint('Order by name failed: ${orderError.message}');
        snapshot = await baseQuery.get();
      }

      final pets = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();
        final rawName = (data['name'] as String?)?.trim();
        final name = (rawName != null && rawName.isNotEmpty)
            ? rawName
            : 'Unnamed Pet';

        return {'id': doc.id, 'name': name};
      }).toList()..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      setState(() {
        _userPets
          ..clear()
          ..addAll(pets);

        if (_userPets.isEmpty) {
          _selectedPetId = null;
          _selectedPetName = null;
        } else if (_selectedPetId == null ||
            !_userPets.any((pet) => pet['id'] == _selectedPetId)) {
          _selectedPetId = _userPets.first['id'];
          _selectedPetName = _userPets.first['name'];
        }

        _isLoadingPets = false;
      });
    } catch (e, stack) {
      debugPrint('Failed to load pets: $e');
      debugPrint(stack.toString());
      setState(() {
        _isLoadingPets = false;
        _petLoadError = 'Failed to load pets. Please try again.';
      });
    }
  }

  Future<void> _createOrUpdateNotificationForAppointment(
    String appointmentId,
    Map<String, dynamic> appointmentData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(appointmentId);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final existingSnap = await txn.get(notificationsRef);
        final previousStatus = (existingSnap.data()?['status'] as String?)
            ?.toLowerCase()
            .trim();
        final status =
            (appointmentData['status'] as String?)?.toLowerCase().trim() ??
            'pending';
        final isStatusChanged =
            !existingSnap.exists || previousStatus != status;

        final payload = <String, dynamic>{
          'userId': user.uid,
          'appointmentId': appointmentId,
          'status': status,
          'vetName': appointmentData['vetName'],
          'petName': appointmentData['petName'],
          'date': appointmentData['date'],
          'timeSlot': appointmentData['timeSlot'],
          'appointmentDateTime': appointmentData['appointmentDateTime'],
          'meetingLink': appointmentData['meetingLink'],
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (isStatusChanged) {
          payload['createdAt'] = FieldValue.serverTimestamp();
          payload['isRead'] = false;
        } else {
          payload['isRead'] = existingSnap.data()?['isRead'] as bool? ?? false;
        }

        txn.set(notificationsRef, payload, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Failed to sync notification: $e');
    }
  }
}
