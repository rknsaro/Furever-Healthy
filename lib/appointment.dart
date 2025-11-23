import 'dart:async';
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
  String? _selectedStatusFilter; // Filter by appointment status
  StreamSubscription<QuerySnapshot>? _vetsSubscription;

  @override
  void initState() {
    super.initState();
    _setupVetsListener();
  }

  @override
  void dispose() {
    _vetsSubscription?.cancel();
    super.dispose();
  }

  // Setup real-time listener for vets from Firestore
  void _setupVetsListener() {
    // Cancel existing subscription if any
    _vetsSubscription?.cancel();

    // Try collections in order: 'vets', 'veterinarians', 'users' with role='vet', 'users' with userType='vet'
    _tryCollection('vets');
  }

  void _tryCollection(String collectionName, {String? whereField, String? whereValue}) {
    _vetsSubscription?.cancel();
    
    Query query;
    if (whereField != null && whereValue != null) {
      query = FirebaseFirestore.instance
          .collection(collectionName)
          .where(whereField, isEqualTo: whereValue);
    } else {
      query = FirebaseFirestore.instance.collection(collectionName);
    }

    _vetsSubscription = query.snapshots().listen(
      (QuerySnapshot snapshot) {
        // If this collection has data, use it; otherwise try next collection
        if (snapshot.docs.isNotEmpty) {
          _processVetsSnapshot(snapshot);
        } else {
          // Try next collection in fallback order
          if (collectionName == 'vets') {
            _tryCollection('veterinarians');
          } else if (collectionName == 'veterinarians') {
            _tryCollection('users', whereField: 'role', whereValue: 'vet');
          } else if (collectionName == 'users' && whereField == 'role') {
            _tryCollection('users', whereField: 'userType', whereValue: 'vet');
          } else {
            // All collections tried, process empty result
            _processVetsSnapshot(snapshot);
          }
        }
      },
      onError: (error) {
        print('Error listening to $collectionName: $error');
        // Try next collection on error
        if (collectionName == 'vets') {
          _tryCollection('veterinarians');
        } else if (collectionName == 'veterinarians') {
          _tryCollection('users', whereField: 'role', whereValue: 'vet');
        } else if (collectionName == 'users' && whereField == 'role') {
          _tryCollection('users', whereField: 'userType', whereValue: 'vet');
        }
      },
    );
  }

  void _processVetsSnapshot(QuerySnapshot snapshot) {
    if (!mounted) return;

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

      // Check for premium status (support multiple field names)
      final premiumBool = data['premium'] as bool?;
      final isPremiumBool = data['isPremium'] as bool?;
      final isPremiumVetBool = data['isPremiumVet'] as bool?;
      final premiumVetBool = data['premiumVet'] as bool?;
      final premiumString = data['premium'] as String?;
      
      bool isPremium = false;
      if (premiumBool != null) {
        isPremium = premiumBool;
      } else if (isPremiumBool != null) {
        isPremium = isPremiumBool;
      } else if (isPremiumVetBool != null) {
        isPremium = isPremiumVetBool;
      } else if (premiumVetBool != null) {
        isPremium = premiumVetBool;
      } else if (premiumString != null) {
        isPremium = premiumString.toLowerCase() == 'true';
      }

      final vet = {
        'vetId': doc.id, // Store the document ID as vetId
        'name': data['name'] ?? data['displayName'] ?? 'Unknown Vet',
        'specialty': data['specialization'] ?? 
                     data['specialty'] ?? 'Specialty Unavailable',
        'profileImageUrl': data['profileImageUrl'] as String?,
        'rating': data['rating'] is int
            ? data['rating']
            : (data['rating'] is double
                  ? (data['rating'] as double).round()
                  : 5),
        'location': data['location'] ?? 'Unknown',
        'verified': data['verified'] ?? true,
        'status': status,
        'isPremium': isPremium,
      };
      vets.add(vet);

      // Collect unique locations and specialties for filters
      if (vet['location'] != null && vet['location'] != 'Unknown') {
        locations.add(vet['location'] as String);
      }
      // Only add specialty to filter list if it's not the default "Specialty Unavailable"
      if (vet['specialty'] != null && 
          vet['specialty'] != 'Specialty Unavailable' &&
          (vet['specialty'] as String).isNotEmpty) {
        specialties.add(vet['specialty'] as String);
      }
    }

    // Sort vets: premium vets first, then by rating (descending)
    vets.sort((a, b) {
      final aPremium = a['isPremium'] as bool? ?? false;
      final bPremium = b['isPremium'] as bool? ?? false;
      
      // Premium vets come first
      if (aPremium && !bPremium) return -1;
      if (!aPremium && bPremium) return 1;
      
      // If both are premium or both are not, sort by rating (descending)
      final aRating = a['rating'] as int? ?? 0;
      final bRating = b['rating'] as int? ?? 0;
      return bRating.compareTo(aRating);
    });

    setState(() {
      allVets = vets;
      allLocations = locations.toList()..sort();
      // Don't update Location and Specialty - they are fixed
      // filterOptions['Location'] = locations.toList()..sort();
      // filterOptions['Specialty'] = specialties.toList()..sort();
    });
  }

  List<Map<String, dynamic>> get filteredVets {
    List<Map<String, dynamic>> filtered;
    
    // Apply filter if selected
    if (selectedFilterType == null || selectedFilterValue == null) {
      filtered = allVets;
    } else {
      filtered = allVets.where((vet) {
        switch (selectedFilterType) {
          case 'Location':
            return vet['location'] == selectedFilterValue;
          case 'Specialty':
            return vet['specialty'] == selectedFilterValue;
          default:
            return true;
        }
      }).toList();
    }
    
    // Show all vets (both available and unavailable) in the list
    // The count badge will only show available vets
    
    // Ensure premium vets are always at the top, even after filtering
    filtered.sort((a, b) {
      final aPremium = a['isPremium'] as bool? ?? false;
      final bPremium = b['isPremium'] as bool? ?? false;
      
      // Premium vets come first
      if (aPremium && !bPremium) return -1;
      if (!aPremium && bPremium) return 1;
      
      // If both are premium or both are not, sort by rating (descending)
      final aRating = a['rating'] as int? ?? 0;
      final bRating = b['rating'] as int? ?? 0;
      return bRating.compareTo(aRating);
    });
    
    return filtered;
  }

  final List<String> filters = ['Location', 'Specialty'];

  // Available filter options for each filter type
  final Map<String, List<String>> filterOptions = {
    'Location': [''],
    'Specialty': ['Pathology', 'Behaviour', 'Dermatology', 'General'],
  };

  List<Map<String, dynamic>> allVets = [];
  List<String> allLocations = []; // Store all unique locations

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    
    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : screenWidth * 0.05,
                vertical: isSmallScreen ? 10 : 12,
              ),
              child: Text(
                'Book an appointment',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : isMediumScreen ? 21 : 22,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : screenWidth * 0.05,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Appointments',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: _mintDark,
                              ),
                            ),
                          ),
                          // Toggle button to go back to vets view
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showAppointments = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16,
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                  minWidth: 100,
                                ),
                                decoration: BoxDecoration(
                                  color: _mint,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _mint),
                                ),
                                child: Text(
                                  'Back to Vets',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          // Status filter tabs
                          _buildStatusFilterTabs(),
                          // Appointments list
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : screenWidth * 0.05,
                              ),
                              child: _buildAppointmentsList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : screenWidth * 0.05,
                    vertical: isSmallScreen ? 8 : 10,
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
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _showFilterDialog(filter),
                                          borderRadius: BorderRadius.circular(30),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            constraints: const BoxConstraints(
                                              minHeight: 44,
                                              minWidth: 80,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: selectedFilterType == filter
                                                  ? LinearGradient(
                                                      colors: [_mint, _mintDark],
                                                    )
                                                  : null,
                                              color: selectedFilterType == filter
                                                  ? null
                                                  : Colors.white,
                                              border: Border.all(
                                                color:
                                                    selectedFilterType == filter
                                                    ? _mint
                                                    : Colors.grey.shade300,
                                                width: selectedFilterType == filter ? 1.5 : 1,
                                              ),
                                              borderRadius: BorderRadius.circular(30),
                                              boxShadow: selectedFilterType == filter
                                                  ? [
                                                      BoxShadow(
                                                        color: _mint.withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getFilterIcon(filter),
                                                  size: 16,
                                                  color: selectedFilterType == filter
                                                      ? Colors.white
                                                      : Colors.grey.shade700,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  filter,
                                                  style: TextStyle(
                                                    color:
                                                        selectedFilterType == filter
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontWeight: selectedFilterType == filter
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // View Appointments button
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showAppointments = true;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(30),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          constraints: const BoxConstraints(
                                            minHeight: 44,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: _showAppointments
                                                ? LinearGradient(
                                                    colors: [_mint, _mintDark],
                                                  )
                                                : null,
                                            color: _showAppointments
                                                ? null
                                                : Colors.white,
                                            border: Border.all(
                                              color: _showAppointments
                                                  ? _mint
                                                  : Colors.grey.shade300,
                                              width: _showAppointments ? 1.5 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(30),
                                            boxShadow: _showAppointments
                                                ? [
                                                    BoxShadow(
                                                      color: _mint.withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: _showAppointments
                                                    ? Colors.white
                                                    : Colors.grey.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'View Appointments',
                                                style: TextStyle(
                                                  color: _showAppointments
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontWeight: _showAppointments
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
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
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedFilterType = null;
                                      selectedFilterValue = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    constraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.clear,
                                      color: Colors.red.shade700,
                                      size: 18,
                                    ),
                                  ),
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
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _mint.withOpacity(0.15),
                                _mint.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _mint.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _mint.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getFilterIcon(selectedFilterType!),
                                size: 16,
                                color: _mintDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$selectedFilterType: ',
                                style: TextStyle(
                                  color: _mintDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                selectedFilterValue!,
                                style: TextStyle(
                                  color: _mintDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedFilterType = null;
                                    selectedFilterValue = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              filteredVets.isEmpty
                                  ? 'No veterinarians found'
                                  : 'Veterinarians',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : isMediumScreen ? 19 : 20,
                                fontWeight: FontWeight.w700,
                                color: _mintDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('vets')
                                .snapshots(),
                            builder: (context, snapshot) {
                              // Get total count from filtered list (respects all filters)
                              int totalCount = filteredVets.length;
                              int availableCount = 0;
                              
                              // Create a map of vet IDs to their real-time status
                              final vetStatusMap = <String, String>{};
                              
                              if (snapshot.hasData) {
                                // Build a map of vet IDs to their real-time status
                                for (var doc in snapshot.data!.docs) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final vetId = doc.id;
                                  
                                  // Get status from real-time data
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
                                  
                                  vetStatusMap[vetId] = status.toLowerCase().trim();
                                }
                              }
                              
                              // Count available vets from the filtered list
                              for (var vet in filteredVets) {
                                final vetId = vet['vetId'] as String;
                                
                                // Get status from real-time map if available, otherwise use cached status
                                String status;
                                if (vetStatusMap.containsKey(vetId)) {
                                  status = vetStatusMap[vetId]!;
                                } else {
                                  // Fallback to cached status
                                  status = (vet['status'] as String? ?? '').toLowerCase().trim();
                                }
                                
                                // Count if available
                                if (status == 'available') {
                                  availableCount++;
                                }
                              }
                              
                              if (totalCount > 0)
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 10 : 12,
                                    vertical: isSmallScreen ? 5 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _mint.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _mint.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '$availableCount of $totalCount available',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontWeight: FontWeight.w600,
                                      color: _mintDark,
                                    ),
                                  ),
                                );
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
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
                            vet['profileImageUrl'] as String?,
                            vet['isPremium'] as bool? ?? false,
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

  // Build status filter tabs
  Widget _buildStatusFilterTabs() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    final statusFilters = [
      {'label': 'All', 'value': null},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Confirmed', 'value': 'confirmed'},
      {'label': 'Completed', 'value': 'completed'},
      {'label': 'Declined', 'value': 'declined'},
      {'label': 'Cancelled', 'value': 'cancelled'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statusFilters.map((filter) {
            final isSelected = _selectedStatusFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = filter['value'];
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 14 : 18,
                      vertical: isSmallScreen ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                _mint,
                                _mint.withOpacity(0.8),
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? _mint : Colors.grey[300]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _mint.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filter['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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
        var appointments = snapshot.data!.docs.toList()
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

        // Filter by status if a filter is selected
        if (_selectedStatusFilter != null) {
          appointments = appointments.where((doc) {
            final appointment = doc.data() as Map<String, dynamic>;
            final status = (appointment['status'] ?? 'pending').toString().toLowerCase();
            return status == _selectedStatusFilter!.toLowerCase();
          }).toList();
        }

        if (appointments.isEmpty && _selectedStatusFilter != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No ${_selectedStatusFilter} appointments found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatusFilter = null;
                    });
                  },
                  child: const Text('Clear filter'),
                ),
              ],
            ),
          );
        }

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  // Show reschedule indicator
                  if (appointment['isRescheduled'] == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.update, color: Colors.orange, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Rescheduled',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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

          // Show original appointment info if rescheduled
          if (appointment['isRescheduled'] == true && appointment['originalDate'] != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.history, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Original Appointment',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy').format((appointment['originalDate'] as Timestamp).toDate())}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  if (appointment['originalTimeSlot'] != null)
                    Text(
                      'Time: ${appointment['originalTimeSlot']}',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

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

          // Reschedule button for confirmed and pending appointments
          if (normalizedStatus == 'confirmed' || normalizedStatus == 'pending') ...[
            const Divider(height: 24),
            _buildRescheduleSection(appointment, appointmentId),
          ],

          // Cancel button for pending appointments only
          if (normalizedStatus == 'pending') ...[
            const SizedBox(height: 12),
            _buildCancelSection(appointmentId),
          ],
        ],
      ),
    );
  }

  Widget _buildRescheduleSection(Map<String, dynamic> appointment, String appointmentId) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _navigateToReschedule(appointment, appointmentId),
        icon: const Icon(Icons.calendar_today, color: _mint),
        label: const Text(
          'Reschedule Appointment',
          style: TextStyle(
            color: _mint,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _mint, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _navigateToReschedule(Map<String, dynamic> appointment, String appointmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RescheduleAppointmentPage(
          appointmentId: appointmentId,
          appointment: appointment,
        ),
      ),
    );
  }

  Widget _buildCancelSection(String appointmentId) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelConfirmationDialog(appointmentId),
        icon: const Icon(Icons.cancel, color: Colors.red),
        label: const Text(
          'Cancel Appointment',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog(String appointmentId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Cancel Appointment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'No',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _cancelAppointment(appointmentId);
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to cancel appointments'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Update appointment status to cancelled
      await FirebaseFirestore.instance
          .collection('user_appointments')
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'cancelledAt': Timestamp.now(),
        'cancelledBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create or update notification for cancellation
      await _createOrUpdateNotificationForCancellation(appointmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: _mint,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createOrUpdateNotificationForCancellation(String appointmentId) async {
    try {
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('user_appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        return;
      }

      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      final vetId = appointmentData['vetId'] as String?;
      final vetName = appointmentData['vetName'] as String?;
      final petName = appointmentData['petName'] as String?;
      final userName = appointmentData['userName'] as String?;
      final userEmail = appointmentData['userEmail'] as String?;

      if (vetId == null) {
        return;
      }

      final notificationsRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(appointmentId);

      await notificationsRef.set({
        'type': 'appointment_cancelled',
        'appointmentId': appointmentId,
        'vetId': vetId,
        'vetName': vetName ?? 'Unknown Vet',
        'userId': appointmentData['userId'],
        'userName': userName ?? 'Unknown User',
        'userEmail': userEmail ?? '',
        'petName': petName ?? 'Unknown Pet',
        'message': '${userName ?? "A user"} cancelled an appointment for ${petName ?? "their pet"}',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to create notification for cancellation: $e');
    }
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
          vetId: appointment['vetId'] as String?,
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
    // For Location filter, use a StatefulBuilder to handle search
    if (filterType == 'Location') {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          final TextEditingController locationSearchController = TextEditingController();
          
          return StatefulBuilder(
            builder: (context, setDialogState) {
              String locationSearchQuery = locationSearchController.text;
              
              // Filter locations based on search query
              final filteredLocations = locationSearchQuery.isEmpty
                  ? allLocations
                  : allLocations.where((location) {
                      return location.toLowerCase().contains(locationSearchQuery.toLowerCase());
                    }).toList();

              return AlertDialog(
                title: Text('Select $filterType'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar for locations
                    TextField(
                      controller: locationSearchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Icon(Icons.search, color: _mint),
                        suffixIcon: locationSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  locationSearchController.clear();
                                  setDialogState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _mint, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _mint, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _mint, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Location list
                    if (filteredLocations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No Veterinarian information found for this location',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: filteredLocations.map((location) {
                              return ListTile(
                                title: Text(location),
                                onTap: () {
                                  setState(() {
                                    selectedFilterType = filterType;
                                    selectedFilterValue = location;
                                  });
                                  locationSearchController.dispose();
                                  Navigator.pop(context);
                                },
                                selected: selectedFilterValue == location,
                                selectedTileColor: _mint.withOpacity(0.1),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      locationSearchController.dispose();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      // For other filter types, use the original dialog
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Select $filterType',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
              ),
            ),
            contentPadding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 24,
              isSmallScreen ? 12 : 20,
              isSmallScreen ? 16 : 24,
              isSmallScreen ? 12 : 20,
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filterOptions[filterType]!.map((option) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 16,
                        vertical: isSmallScreen ? 4 : 8,
                      ),
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _doctorCard(
    String name,
    String specialty,
    int rating,
    String location,
    String status,
    String vetId,
    String? profileImageUrl,
    bool isPremium,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    
    final String normalizedStatus = status.trim().isEmpty
        ? 'Available'
        : status.trim();
    final bool isUnavailable = normalizedStatus.toLowerCase() == 'unavailable';
    final Color statusColor = isUnavailable ? Colors.red : Colors.green;

    // Premium styling
    final Color premiumColor = const Color(0xFFFFD700); // Gold color
    final Color cardBorderColor = isPremium 
        ? premiumColor 
        : _mint.withOpacity(0.35);
    final List<BoxShadow> cardShadow = isPremium
        ? [
            BoxShadow(
              color: premiumColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ];

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 14 : 18),
      decoration: BoxDecoration(
        color: isPremium 
            ? const Color(0xFFFFFBE6) // Subtle gold tint for premium
            : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: cardBorderColor,
          width: isPremium ? 2.5 : 1.5,
        ),
        boxShadow: cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
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
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : isMediumScreen ? 16 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: isSmallScreen ? 60 : isMediumScreen ? 65 : 70,
                      height: isSmallScreen ? 60 : isMediumScreen ? 65 : 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: profileImageUrl == null
                            ? const RadialGradient(
                                colors: [Color(0xFFDFFCF4), Color(0xBFB9E591)],
                              )
                            : null,
                        border: Border.all(
                          color: isPremium ? premiumColor : Colors.grey.shade300,
                          width: isPremium ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? Image.network(
                                profileImageUrl,
                                width: isSmallScreen ? 60 : isMediumScreen ? 65 : 70,
                                height: isSmallScreen ? 60 : isMediumScreen ? 65 : 70,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  final size = isSmallScreen ? 60.0 : isMediumScreen ? 65.0 : 70.0;
                                  return Container(
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                        color: _mint,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  final size = isSmallScreen ? 60.0 : isMediumScreen ? 65.0 : 70.0;
                                  return Container(
                                    width: size,
                                    height: size,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [Color(0xFFDFFCF4), Color(0xBFB9E591)],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: isSmallScreen ? 30 : isMediumScreen ? 32 : 35,
                                      color: _mintDark,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: isSmallScreen ? 60 : isMediumScreen ? 65 : 70,
                                height: isSmallScreen ? 60 : isMediumScreen ? 65 : 70,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [Color(0xFFDFFCF4), Color(0xBFB9E591)],
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: isSmallScreen ? 30 : isMediumScreen ? 32 : 35,
                                  color: _mintDark,
                                ),
                              ),
                      ),
                    ),
                    if (isPremium)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [premiumColor, const Color(0xFFFFA500)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: premiumColor.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('feedback')
                      .where('vetName', isEqualTo: name)
                      .snapshots(),
                  builder: (context, snapshot) {
                    double averageRating = 0.0;
                    int reviewCount = 0;
                    
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      int totalRating = 0;
                      reviewCount = snapshot.data!.docs.length;
                      
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final ratingValue = data['rating'] as int? ?? 0;
                        totalRating += ratingValue;
                      }
                      
                      if (reviewCount > 0) {
                        averageRating = totalRating / reviewCount;
                      }
                    }
                    
                    // If no feedback, show 0.0 instead of default rating
                    if (reviewCount == 0) {
                      averageRating = 0.0;
                    }
                    
                    // If no ratings, don't show stars at all
                    if (reviewCount == 0) {
                      return Column(
                        children: [
                          Text(
                            'No ratings yet',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : isMediumScreen ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      );
                    }
                    
                    // Use the exact average rating for stars (not rounded) to match numeric display
                    final ratingClamped = averageRating.clamp(0.0, 5.0);
                    
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            // Show filled star if index is less than the average rating
                            // Show half star if the average is between index and index+1
                            final starValue = index + 1;
                            final isFilled = starValue <= ratingClamped;
                            final isHalfFilled = starValue - 0.5 <= ratingClamped && ratingClamped < starValue;
                            
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 1 : 1.5),
                              child: isHalfFilled
                                  ? Icon(
                                      Icons.star_half,
                                      color: Colors.amber,
                                      size: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                    )
                                  : Icon(
                                      isFilled ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                    ),
                            );
                          }),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : isMediumScreen ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            SizedBox(width: isSmallScreen ? 12 : isMediumScreen ? 14 : 16),
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : isMediumScreen ? 17 : 19,
                                      fontWeight: FontWeight.w800,
                                      color: isPremium ? premiumColor : _mintDark,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Row(
                              children: [
                                Icon(
                                  _getSpecialtyIcon(specialty),
                                  size: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                  color: _getSpecialtyColor(specialty),
                                ),
                                SizedBox(width: isSmallScreen ? 4 : 6),
                                Expanded(
                                  child: Text(
                                    specialty.isNotEmpty ? specialty : 'Specialty Unavailable',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : isMediumScreen ? 14 : 15,
                                      color: _getSpecialtyColor(specialty),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: _mint,
                                  size: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                ),
                                SizedBox(width: isSmallScreen ? 3 : 4),
                                Flexible(
                                  child: Text(
                                    location,
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: isSmallScreen ? 11 : isMediumScreen ? 12 : 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : isMediumScreen ? 11 : 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8 : 10,
                                    vertical: isSmallScreen ? 5 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isUnavailable
                                        ? null
                                        : LinearGradient(
                                            colors: [
                                              statusColor.withOpacity(0.15),
                                              statusColor.withOpacity(0.08),
                                            ],
                                          ),
                                    color: isUnavailable
                                        ? Colors.red.shade50
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: isSmallScreen ? 6 : 7,
                                        height: isSmallScreen ? 6 : 7,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusColor.withOpacity(0.5),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: isSmallScreen ? 5 : 6),
                                      Text(
                                        normalizedStatus,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: isSmallScreen ? 10 : isMediumScreen ? 11 : 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isPremium) ...[
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 10,
                                        vertical: isSmallScreen ? 4 : 5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            premiumColor,
                                            const Color(0xFFFFA500), // Orange
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: premiumColor.withOpacity(0.5),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.workspace_premium,
                                            color: Colors.white,
                                            size: isSmallScreen ? 12 : isMediumScreen ? 13 : 14,
                                          ),
                                          SizedBox(width: isSmallScreen ? 4 : 5),
                                          Text(
                                            'PREMIUM',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isSmallScreen ? 9 : 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: isSmallScreen ? 44 : 46,
                          child: OutlinedButton(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'View Profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 12 : isMediumScreen ? 13 : 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _mint,
                              side: const BorderSide(color: _mint, width: 1.5),
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 11 : isMediumScreen ? 12 : 13,
                                horizontal: isSmallScreen ? 16 : 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: SizedBox(
                          height: isSmallScreen ? 44 : 46,
                          child: ElevatedButton(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Book Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isSmallScreen ? 12 : isMediumScreen ? 13 : 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUnavailable
                                  ? Colors.grey.shade400
                                  : _mint,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 11 : isMediumScreen ? 12 : 13,
                                horizontal: isSmallScreen ? 16 : 20,
                              ),
                              elevation: isUnavailable ? 0 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                              profileImageUrl: profileImageUrl,
                                            ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isUnavailable)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Currently unavailable',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  // Helper function to get specialty icon
  IconData _getSpecialtyIcon(String specialty) {
    // If no specialty is set, return question mark icon
    if (specialty.isEmpty || specialty.toLowerCase() == 'specialty unavailable') {
      return Icons.help_outline;
    }
    
    final specialtyLower = specialty.toLowerCase();
    if (specialtyLower.contains('behaviour') || specialtyLower.contains('behavior')) {
      return Icons.psychology;
    } else if (specialtyLower.contains('dermatology')) {
      return Icons.medical_services;
    } else if (specialtyLower.contains('pathology')) {
      return Icons.science;
    } else if (specialtyLower.contains('surgery')) {
      return Icons.healing;
    } else if (specialtyLower.contains('emergency')) {
      return Icons.emergency;
    }
    return Icons.medical_information;
  }

  // Helper function to get specialty color
  Color _getSpecialtyColor(String specialty) {
    final specialtyLower = specialty.toLowerCase();
    if (specialtyLower.contains('behaviour') || specialtyLower.contains('behavior')) {
      return Colors.purple.shade700;
    } else if (specialtyLower.contains('dermatology')) {
      return Colors.blue.shade700;
    } else if (specialtyLower.contains('pathology')) {
      return Colors.red.shade700;
    } else if (specialtyLower.contains('surgery')) {
      return Colors.orange.shade700;
    } else if (specialtyLower.contains('emergency')) {
      return Colors.red.shade600;
    }
    return Colors.black87;
  }

  // Helper function to get filter icon
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Location':
        return Icons.location_on;
      case 'Specialty':
        return Icons.medical_services;
      default:
        return Icons.filter_list;
    }
  }
}

// Feedback Form Widget
class _FeedbackForm extends StatefulWidget {
  final String appointmentId;
  final String userName;
  final String? vetId;
  final String vetName;

  const _FeedbackForm({
    required this.appointmentId,
    required this.userName,
    this.vetId,
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
        'vetId': widget.vetId,
        'vetName': widget.vetName, // Keep for display purposes
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

// Reschedule Appointment Page
class RescheduleAppointmentPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointment;

  const RescheduleAppointmentPage({
    super.key,
    required this.appointmentId,
    required this.appointment,
  });

  @override
  State<RescheduleAppointmentPage> createState() => _RescheduleAppointmentPageState();
}

class _RescheduleAppointmentPageState extends State<RescheduleAppointmentPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  
  List<String> morningTimes = [];
  List<String> afternoonTimes = [];
  
  Map<String, dynamic>? vetSchedule;
  Map<String, dynamic>? vetAvailability;
  bool _isLoadingSchedule = false;
  List<String> workingDays = [];
  Set<String> bookedTimeSlots = {};
  
  // Store all available dates and time slots from Firebase
  Map<String, List<String>> availableDatesAndSlots = {}; // date -> list of available time slots
  Set<String> allAvailableDates = {}; // Set of all dates that have at least one available slot

  @override
  void initState() {
    super.initState();
    // Initialize with current appointment date if it's in the future
    final currentAppointmentDate = 
        (widget.appointment['appointmentDateTime'] as Timestamp?)?.toDate() ??
        (widget.appointment['date'] as Timestamp?)?.toDate() ??
        DateTime.now();
    
    if (currentAppointmentDate.isAfter(DateTime.now())) {
      selectedDate = currentAppointmentDate;
    }
    
    // Initialize with current time slot
    selectedTime = widget.appointment['timeSlot'] as String?;
    
    // Load vet schedule and availability from Firebase
    _loadVetSchedule();
  }
  
  // Get vet ID from appointment
  String? get _vetId {
    return widget.appointment['vetId'] as String?;
  }
  
  // Load vet schedule and availability from Firebase
  Future<void> _loadVetSchedule() async {
    if (_vetId == null) {
      setState(() {
        _isLoadingSchedule = false;
        morningTimes = ['8:00 - 9:00 AM', '9:00 - 10:00 AM', '10:00 - 11:00 AM', '11:00 - 12:00 PM'];
        afternoonTimes = ['1:00 - 2:00 PM', '2:00 - 3:00 PM', '3:00 - 4:00 PM', '4:00 - 5:00 PM'];
      });
      return;
    }
    
    setState(() {
      _isLoadingSchedule = true;
    });

    try {
      final schedule = await _fetchVetSchedule(_vetId!);
      var availability = await _fetchVetAvailability(_vetId!);
      
      // Extract all available dates and time slots from Firebase
      final extractedData = _extractAvailableDatesAndSlots(availability);
      
      setState(() {
        vetSchedule = schedule;
        vetAvailability = availability;
        availableDatesAndSlots = extractedData['datesAndSlots'] as Map<String, List<String>>;
        allAvailableDates = extractedData['dates'] as Set<String>;
        
        // Get time slots from schedule, or use all available slots from Firebase
        final allAvailableSlots = _getAllAvailableTimeSlots(availability);
        if (allAvailableSlots.isNotEmpty) {
          // Split into morning and afternoon based on hour
          final morning = <String>[];
          final afternoon = <String>[];
          
          for (var slot in allAvailableSlots) {
            final hour = _getHourFromTimeSlot(slot);
            if (hour >= 8 && hour < 12) {
              morning.add(slot);
            } else if (hour >= 12 && hour <= 18) {
              afternoon.add(slot);
            }
          }
          
          morningTimes = morning.isNotEmpty ? morning : ['8:00', '9:00', '10:00', '11:00'];
          afternoonTimes = afternoon.isNotEmpty ? afternoon : ['13:00', '14:00', '15:00', '16:00'];
        } else {
          morningTimes = ['8:00', '9:00', '10:00', '11:00'];
          afternoonTimes = ['13:00', '14:00', '15:00', '16:00'];
        }
        
        workingDays = _getWorkingDays(schedule);
        _isLoadingSchedule = false;
      });

      _loadBookedTimeSlots();
    } catch (e) {
      debugPrint('Error loading vet schedule: $e');
      setState(() {
        morningTimes = ['8:00', '9:00', '10:00', '11:00'];
        afternoonTimes = ['13:00', '14:00', '15:00', '16:00'];
        workingDays = [];
        _isLoadingSchedule = false;
      });
    }
  }
  
  // Fetch vet schedule from Firebase (similar to book_appointment.dart)
  Future<Map<String, dynamic>?> _fetchVetSchedule(String vetId) async {
    try {
      const int batchSize = 100;
      List<QueryDocumentSnapshot> allDocs = [];
      QueryDocumentSnapshot? lastDoc;
      
      while (true) {
        Query query = FirebaseFirestore.instance
            .collection('vet_schedules')
            .where('vetId', isEqualTo: vetId)
            .limit(batchSize);
        
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        
        final querySnapshot = await query.get();
        final batchDocs = querySnapshot.docs;
        
        if (batchDocs.isEmpty) break;
        
        allDocs.addAll(batchDocs);
        
        if (batchDocs.length < batchSize) break;
        
        lastDoc = batchDocs.last;
      }
      
      if (allDocs.isNotEmpty) {
        final scheduleData = <String, dynamic>{'vetId': vetId};
        
        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] as String?;
          
          if (date != null && data.containsKey('timeSlots')) {
            scheduleData[date] = data['timeSlots'];
          }
        }
        
        if (scheduleData.length > 1) {
          return scheduleData;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching vet schedule: $e');
      return null;
    }
  }
  
  // Fetch vet availability from Firebase
  Future<Map<String, dynamic>?> _fetchVetAvailability(String vetId) async {
    try {
      const int batchSize = 100;
      List<QueryDocumentSnapshot> allDocs = [];
      QueryDocumentSnapshot? lastDoc;
      
      while (true) {
        Query query = FirebaseFirestore.instance
            .collection('vet_schedules')
            .where('vetId', isEqualTo: vetId)
            .limit(batchSize);
        
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        
        final querySnapshot = await query.get();
        final batchDocs = querySnapshot.docs;
        
        if (batchDocs.isEmpty) break;
        
        allDocs.addAll(batchDocs);
        
        if (batchDocs.length < batchSize) break;
        
        lastDoc = batchDocs.last;
      }
      
      if (allDocs.isNotEmpty) {
        final availabilityData = <String, dynamic>{'vetId': vetId};
        
        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] as String?;
          
          if (date != null && data.containsKey('timeSlots')) {
            availabilityData[date] = data['timeSlots'];
          }
        }
        
        if (availabilityData.length > 1) {
          return availabilityData;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching vet availability: $e');
      return null;
    }
  }
  
  // Extract available dates and slots from availability data
  Map<String, dynamic> _extractAvailableDatesAndSlots(Map<String, dynamic>? availability) {
    final datesAndSlots = <String, List<String>>{};
    final dates = <String>{};
    
    if (availability == null) {
      return {'datesAndSlots': datesAndSlots, 'dates': dates};
    }
    
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    availability.forEach((key, value) {
      if (datePattern.hasMatch(key) && value is Map) {
        final availableSlots = <String>[];
        final dateSlots = value;
        
        dateSlots.forEach((timeKey, timeValue) {
          if (timeValue is bool && timeValue) {
            final timeStr = timeKey.toString();
            final normalizedTime = _normalizeTimeSlotFromRange(timeStr);
            if (normalizedTime != null) {
              if (!availableSlots.contains(normalizedTime)) {
                availableSlots.add(normalizedTime);
              }
            }
          }
        });
        
        if (availableSlots.isNotEmpty) {
          datesAndSlots[key] = availableSlots;
          dates.add(key);
        }
      }
    });
    
    return {'datesAndSlots': datesAndSlots, 'dates': dates};
  }
  
  // Get all available time slots from availability
  List<String> _getAllAvailableTimeSlots(Map<String, dynamic>? availability) {
    final allSlots = <String>{};
    
    if (availability == null) return [];
    
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    availability.forEach((key, value) {
      if (datePattern.hasMatch(key) && value is Map) {
        final dateSlots = value;
        
        dateSlots.forEach((timeKey, timeValue) {
          if (timeValue is bool && timeValue) {
            final timeStr = timeKey.toString();
            final normalizedTime = _normalizeTimeSlotFromRange(timeStr);
            if (normalizedTime != null) {
              allSlots.add(normalizedTime);
            }
          }
        });
      }
    });
    
    final sortedSlots = allSlots.toList()..sort((a, b) {
      final hourA = _getHourFromTimeSlot(a);
      final minuteA = _getMinuteFromTimeSlot(a);
      final hourB = _getHourFromTimeSlot(b);
      final minuteB = _getMinuteFromTimeSlot(b);
      
      if (hourA != hourB) {
        return hourA.compareTo(hourB);
      }
      return minuteA.compareTo(minuteB);
    });
    
    return sortedSlots;
  }
  
  // Normalize time slot from range format to HH:MM format
  String? _normalizeTimeSlotFromRange(String timeStr) {
    final trimmed = timeStr.trim();
    
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(trimmed)) {
      return trimmed;
    }
    
    final rangeMatch = RegExp(r'^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).firstMatch(trimmed);
    if (rangeMatch != null) {
      final startHour = int.tryParse(rangeMatch.group(1) ?? '');
      final startMinute = rangeMatch.group(2) ?? '00';
      final endHour = int.tryParse(rangeMatch.group(3) ?? '');
      final period = rangeMatch.group(5)?.toUpperCase();
      
      if (startHour != null && endHour != null) {
        var hour24 = startHour;
        
        if (period == 'PM') {
          if (startHour == 11 && endHour == 12) {
            hour24 = 11;
          } else {
            if (startHour != 12) {
              hour24 = startHour + 12;
            } else {
              hour24 = 12;
            }
          }
        } else if (period == 'AM') {
          if (startHour == 12) {
            hour24 = 0;
          } else {
            hour24 = startHour;
          }
        }
        
        return '${hour24.toString().padLeft(2, '0')}:$startMinute';
      }
    }
    
    return null;
  }
  
  // Get hour from time slot (format: "08:00")
  int _getHourFromTimeSlot(String timeSlot) {
    final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(timeSlot);
    if (timeMatch != null) {
      return int.tryParse(timeMatch.group(1) ?? '') ?? 0;
    }
    return 0;
  }
  
  // Get minute from time slot (format: "08:00")
  int _getMinuteFromTimeSlot(String timeSlot) {
    final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(timeSlot);
    if (timeMatch != null) {
      return int.tryParse(timeMatch.group(2) ?? '') ?? 0;
    }
    return 0;
  }
  
  // Get working days from schedule
  List<String> _getWorkingDays(Map<String, dynamic>? schedule) {
    if (schedule == null) return [];
    
    if (schedule.containsKey('workingDays') && schedule['workingDays'] is List) {
      final days = schedule['workingDays'] as List;
      return days.map((day) => day.toString()).toList();
    }
    
    if (schedule.containsKey('days') && schedule['days'] is List) {
      final days = schedule['days'] as List;
      return days.map((day) => day.toString()).toList();
    }
    
    return [];
  }
  
  // Load booked time slots for selected date
  Future<void> _loadBookedTimeSlots() async {
    if (_vetId == null) return;
    
    try {
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      
      final appointments = await FirebaseFirestore.instance
          .collection('user_appointments')
          .where('vetId', isEqualTo: _vetId)
          .where('appointmentDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      
      setState(() {
        bookedTimeSlots = appointments.docs
            .map((doc) => doc.data()['timeSlot'] as String? ?? '')
            .where((slot) => slot.isNotEmpty)
            .toSet();
      });
    } catch (e) {
      debugPrint('Error loading booked time slots: $e');
    }
  }
  
  // Check if a date is selectable
  bool _isDateSelectable(DateTime date) {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (dateOnly.isBefore(todayOnly)) {
      return false;
    }
    
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    if (allAvailableDates.isNotEmpty) {
      if (!allAvailableDates.contains(dateStr)) {
        return false;
      }
      
      if (availableDatesAndSlots.containsKey(dateStr)) {
        final slots = availableDatesAndSlots[dateStr]!;
        if (slots.isEmpty) {
          return false;
        }
      } else {
        return false;
      }
    } else {
      if (workingDays.isNotEmpty) {
        final dayName = DateFormat('EEEE').format(date);
        if (!workingDays.contains(dayName)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  // Format time slot for display (convert 24-hour to 12-hour format with range)
  // Format: "08:00" -> "8:00 - 9:00 AM"
  String _formatTimeSlotForDisplay(String timeSlot) {
    try {
      // If already in display format (contains range), return as is
      if (timeSlot.contains(' - ') && (timeSlot.contains('AM') || timeSlot.contains('PM') || timeSlot.contains('NN'))) {
        return timeSlot;
      }
      
      // Parse the time slot (format: "08:00" or "HH:MM")
      final parts = timeSlot.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        
        // Calculate end time (1 hour later)
        final endHour = (hour + 1) % 24;
        
        // Format start time
        String startTime;
        String startPeriod;
        if (hour == 0) {
          startTime = '12:$minute';
          startPeriod = 'AM';
        } else if (hour < 12) {
          startTime = '$hour:$minute';
          startPeriod = 'AM';
        } else if (hour == 12) {
          startTime = '12:$minute';
          startPeriod = 'PM';
        } else {
          startTime = '${hour - 12}:$minute';
          startPeriod = 'PM';
        }
        
        // Format end time
        String endTime;
        String endPeriod;
        if (endHour == 0) {
          endTime = '12:$minute';
          endPeriod = 'AM';
        } else if (endHour < 12) {
          endTime = '$endHour:$minute';
          endPeriod = 'AM';
        } else if (endHour == 12) {
          endTime = '12:$minute';
          endPeriod = 'NN'; // Use "NN" for noon instead of "PM"
        } else {
          endTime = '${endHour - 12}:$minute';
          endPeriod = 'PM';
        }
        
        // Special case: 11:00 - 12:00 PM should display as "11:00 - 12:00 NN"
        if (hour == 11 && endHour == 12) {
          return '$startTime - $endTime NN';
        }
        
        // If both times are in the same period, only show period once
        if (startPeriod == endPeriod) {
          // If end period is NN, use NN instead
          if (endPeriod == 'NN') {
            return '$startTime - $endTime NN';
          }
          return '$startTime - $endTime $startPeriod';
        } else {
          // Crosses AM/PM boundary (e.g., 11:00 AM - 12:00 PM)
          // If end is NN, format without AM on start
          if (endPeriod == 'NN') {
            return '$startTime - $endTime NN';
          }
          return '$startTime $startPeriod - $endTime $endPeriod';
        }
      }
    } catch (e) {
      // If parsing fails, return original
    }
    return timeSlot;
  }

  @override
  Widget build(BuildContext context) {
    // Clear selected time if it becomes invalid (in the past)
    if (selectedTime != null && _isTimeSlotInPast(selectedTime!)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedTime = null;
          });
        }
      });
    }

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
          'Reschedule Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card showing current appointment details
              _buildCurrentAppointmentCard(),
              const SizedBox(height: 24),

              // Select Date
              const Text(
                'Select New Date',
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

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () async {
                      if (selectedTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select an appointment time.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Validate that the selected time is not in the past
                      if (selectedTime != null && _isTimeSlotInPast(selectedTime!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cannot reschedule appointments in the past. Please select a future time slot.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        await _rescheduleAppointment();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Appointment rescheduled! Waiting for vet confirmation.',
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
                              content: Text('Error rescheduling appointment: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
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
                      'Confirm Reschedule',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentAppointmentCard() {
    final currentDate = 
        (widget.appointment['appointmentDateTime'] as Timestamp?)?.toDate() ??
        (widget.appointment['date'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final currentTime = widget.appointment['timeSlot'] ?? '';
    final petName = widget.appointment['petName'] ?? 'Unknown';
    final vetName = widget.appointment['vetName'] ?? 'Unknown Vet';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Current Appointment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Pet: $petName', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text('Vet: $vetName', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            'Date: ${DateFormat('MMM d, yyyy').format(currentDate)}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text('Time: $currentTime', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _calendar() {
    // Find first available date if current selected date is not selectable
    DateTime initialDate = selectedDate;
    if (!_isDateSelectable(selectedDate)) {
      final today = DateTime.now();
      for (int i = 0; i < 730; i++) {
        final candidateDate = today.add(Duration(days: i));
        if (_isDateSelectable(candidateDate)) {
          initialDate = candidateDate;
          break;
        }
      }
    }
    
    return CalendarDatePicker(
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years ahead
      selectableDayPredicate: _isDateSelectable,
      onDateChanged: (date) {
        setState(() {
          selectedDate = date;
          selectedTime = null; // Clear selected time when date changes
        });
        _loadBookedTimeSlots(); // Reload booked slots for new date
      },
    );
  }

  bool _isTimeSlotInPast(String timeSlot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    // Only check for past times if the selected date is today
    if (selectedDay.isAtSameMomentAs(today)) {
      // Try to parse HH:MM format first
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeSlot);
      if (timeMatch != null) {
        var hour = int.tryParse(timeMatch.group(1) ?? '') ?? 0;
        final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
        
        // Check if it's AM/PM format
        final hasAM = timeSlot.toUpperCase().contains('AM');
        final hasPM = timeSlot.toUpperCase().contains('PM');
        final hasNN = timeSlot.toUpperCase().contains('NN');
        
        if (hasPM && !hasAM && !hasNN) {
          if (hour != 12) {
            hour += 12;
          }
        } else if (hasAM && !hasPM) {
          if (hour == 12) {
            hour = 0;
          }
        } else if (hasNN) {
          // NN is 12:00 PM
          hour = 12;
        }
        
        final slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);
        return slotDateTime.isBefore(now);
      }
    }
    
    return false;
  }

  List<String> get availableMorningTimes {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final availableSlots = availableDatesAndSlots[dateStr] ?? [];
    
    // Filter morning slots (8:00-11:59) that are available and not booked
    final morning = morningTimes.where((time) {
      final normalizedTime = _normalizeTimeSlotFromRange(time) ?? time;
      final hour = _getHourFromTimeSlot(normalizedTime);
      if (hour >= 8 && hour < 12) {
        // Check if it's in available slots for this date
        if (availableSlots.contains(normalizedTime)) {
          // Check if not booked
          final displayTime = _formatTimeSlotForDisplay(time);
          return !bookedTimeSlots.contains(displayTime) && !_isTimeSlotInPast(displayTime);
        }
      }
      return false;
    }).toList();
    
    // Format for display
    return morning.map((time) => _formatTimeSlotForDisplay(time)).toList();
  }

  List<String> get availableAfternoonTimes {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final availableSlots = availableDatesAndSlots[dateStr] ?? [];
    
    // Filter afternoon slots (12:00-18:00) that are available and not booked
    final afternoon = afternoonTimes.where((time) {
      final normalizedTime = _normalizeTimeSlotFromRange(time) ?? time;
      final hour = _getHourFromTimeSlot(normalizedTime);
      if (hour >= 12 && hour <= 18) {
        // Check if it's in available slots for this date
        if (availableSlots.contains(normalizedTime)) {
          // Check if not booked
          final displayTime = _formatTimeSlotForDisplay(time);
          return !bookedTimeSlots.contains(displayTime) && !_isTimeSlotInPast(displayTime);
        }
      }
      return false;
    }).toList();
    
    // Format for display
    return afternoon.map((time) => _formatTimeSlotForDisplay(time)).toList();
  }

  Widget _buildTimeGrid() {
    if (_isLoadingSchedule) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _mint),
        ),
      );
    }

    final morningSlots = availableMorningTimes;
    final afternoonSlots = availableAfternoonTimes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Morning Section
        const Text(
          'Morning',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (morningSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No morning slots available for today',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: morningSlots.length,
            itemBuilder: (context, index) {
              final time = morningSlots[index];
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
                    _formatTimeSlotForDisplay(time),
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
        if (afternoonSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No afternoon slots available for today',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: afternoonSlots.length,
            itemBuilder: (context, index) {
              final time = afternoonSlots[index];
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
                    _formatTimeSlotForDisplay(time),
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

  int _parseHourFromTime(String time) {
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

  Future<void> _rescheduleAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Get original appointment details
    final originalDate = 
        (widget.appointment['appointmentDateTime'] as Timestamp?)?.toDate() ??
        (widget.appointment['date'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final originalTimeSlot = widget.appointment['timeSlot'] ?? '';

    // Combine date and time for new appointment datetime
    final newAppointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _parseHourFromTime(selectedTime!),
      _parseMinuteFromTime(selectedTime!),
    );

    // Update appointment document
    await FirebaseFirestore.instance
        .collection('user_appointments')
        .doc(widget.appointmentId)
        .update({
      'date': Timestamp.fromDate(selectedDate),
      'timeSlot': selectedTime,
      'appointmentDateTime': Timestamp.fromDate(newAppointmentDateTime),
      'status': 'pending', // Reset to pending for vet approval
      'isRescheduled': true,
      'originalDate': Timestamp.fromDate(originalDate),
      'originalTimeSlot': originalTimeSlot,
      'rescheduledAt': Timestamp.now(),
      'rescheduledBy': user.uid,
    });

    // Update notification
    await _createOrUpdateNotificationForReschedule();
  }

  Future<void> _createOrUpdateNotificationForReschedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.appointmentId);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final appointmentDoc = await txn.get(
          FirebaseFirestore.instance
              .collection('user_appointments')
              .doc(widget.appointmentId)
        );
        
        if (!appointmentDoc.exists) return;

        final appointmentData = appointmentDoc.data()!;
        final payload = <String, dynamic>{
          'userId': user.uid,
          'appointmentId': widget.appointmentId,
          'status': 'pending',
          'vetName': appointmentData['vetName'],
          'petName': appointmentData['petName'],
          'date': appointmentData['date'],
          'timeSlot': appointmentData['timeSlot'],
          'appointmentDateTime': appointmentData['appointmentDateTime'],
          'isRescheduled': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        };

        txn.set(notificationsRef, payload, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Failed to sync notification for reschedule: $e');
    }
  }
}
