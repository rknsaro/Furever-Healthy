import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const _mint = Color(0xFF6F994A);
const _screenBg = Color(0xFFF6F8FB);

class PetMedicalHistoryPage extends StatefulWidget {
  final String petId;
  final String petName;

  const PetMedicalHistoryPage({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<PetMedicalHistoryPage> createState() => _PetMedicalHistoryPageState();
}

class _PetMedicalHistoryPageState extends State<PetMedicalHistoryPage> {
  StreamSubscription<QuerySnapshot>? _immunizationSubscription;
  Map<String, Map<String, dynamic>> _immunizations = {}; // vaccineName -> data
  bool _isLoading = true;
  bool _isVet = false;
  String? _currentVetId;
  String? _currentVetName;
  String? _petSpecies; // 'Dog' or 'Cat'
  String? _currentUserId; // Current logged-in user ID
  
  // Filter state
  String? _filterVeterinarian;
  DateTime? _filterDateStart;
  DateTime? _filterDateEnd;
  String? _filterVaccineType;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _loadPetSpecies();
    _checkIfVet();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUserId = user?.uid;
    });
  }

  @override
  void dispose() {
    _immunizationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPetSpecies() async {
    try {
      final petDoc = await FirebaseFirestore.instance
          .collection('petInfos')
          .doc(widget.petId)
          .get();

      if (petDoc.exists && petDoc.data() != null) {
        final petData = petDoc.data()!;
        final species = petData['speciesType'] as String? ?? 'Dog';
        
        setState(() {
          _petSpecies = species;
        });
      } else {
        // Default to Dog if pet not found
        setState(() {
          _petSpecies = 'Dog';
        });
      }
      
      // Load immunizations after species is loaded
      _loadImmunizations();
    } catch (e) {
      print('Error loading pet species: $e');
      // Default to Dog on error
      setState(() {
        _petSpecies = 'Dog';
      });
      _loadImmunizations();
    }
  }

  Future<void> _checkIfVet() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isVet = false);
        return;
      }

      // Check if user exists in vets collection
      final vetDoc = await FirebaseFirestore.instance
          .collection('vets')
          .doc(user.uid)
          .get();

      if (vetDoc.exists) {
        final vetData = vetDoc.data();
        setState(() {
          _isVet = true;
          _currentVetId = user.uid;
          _currentVetName = vetData?['name'] as String? ??
              vetData?['displayName'] as String? ??
              'Veterinarian';
        });
      } else {
        setState(() => _isVet = false);
      }
    } catch (e) {
      print('Error checking vet status: $e');
      setState(() => _isVet = false);
    }
  }

  void _loadImmunizations() {
    _immunizationSubscription?.cancel();

    _immunizationSubscription = FirebaseFirestore.instance
        .collection('petImmunizations')
        .where('petId', isEqualTo: widget.petId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        setState(() {
          // Clear existing data
          _immunizations = {};
          
          // Map documents by vaccine name - only show what's in Firebase for this pet
          // Filter by species if the record has species info
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final vaccineName = data['vaccineName'] as String?;
            final recordSpecies = data['speciesType'] as String?;
            
            // Only include if vaccine name exists and species matches (if species is specified in record)
            if (vaccineName != null) {
              // If record has species info, filter by it; otherwise include all
              if (recordSpecies == null || recordSpecies == _petSpecies || _petSpecies == null) {
                _immunizations[vaccineName] = {
                  'id': doc.id,
                  ...data,
                };
              }
            }
          }
          
          // Debug: Log species and vaccines count
          if (_petSpecies != null) {
            print('Loaded immunizations for ${_petSpecies}: ${_immunizations.length} entries');
          }
          
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Error loading immunizations: $error');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading immunizations: $error')),
          );
        }
      },
    );
  }

  Future<void> _addOrEditVaccine(String? vaccineName, {Map<String, dynamic>? existingData}) async {
    // Check if user is the creator of this record
    if (existingData != null) {
      final recordUserId = existingData['userId'] as String?;
      if (recordUserId != null && recordUserId != _currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only edit records you created'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final TextEditingController vaccineNameController = TextEditingController(
      text: vaccineName ?? existingData?['vaccineName'] as String? ?? '',
    );
    String? selectedVetId;
    String? selectedVetName;
    DateTime selectedDate = existingData?['date'] != null
        ? (existingData!['date'] as Timestamp).toDate()
        : DateTime.now();

    // If editing, set initial values
    if (existingData != null) {
      selectedVetId = existingData['vetId'] as String?;
      selectedVetName = existingData['vetName'] as String?;
    } else {
      // If adding and user is a vet, pre-fill vet info
      if (_isVet) {
        selectedVetId = _currentVetId;
        selectedVetName = _currentVetName;
      }
    }

    // Create controller for veterinarian name field
    final TextEditingController veterinarianController = TextEditingController(
      text: selectedVetName != null && selectedVetName != 'Unknown'
          ? selectedVetName.replaceFirst(RegExp(r'^Dr\.?\s*'), '').trim() // Remove "Dr." prefix if present
          : '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  existingData == null ? 'Add Vaccine' : 'Edit Vaccine',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Vaccine name field (only for adding new vaccines)
                        if (existingData == null)
                          TextField(
                            controller: vaccineNameController,
                            decoration: const InputDecoration(
                              labelText: 'Vaccine Name',
                              border: OutlineInputBorder(),
                              hintText: 'Enter vaccine name',
                            ),
                          ),
                        if (existingData == null) const SizedBox(height: 16),
                        // Date picker
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: _mint,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Veterinarian field (editable for all users)
                        TextField(
                          controller: veterinarianController,
                          decoration: const InputDecoration(
                            labelText: 'Veterinarian',
                            border: OutlineInputBorder(),
                            hintText: 'Enter veterinarian name',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: _mint),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate vaccine name
                          final finalVaccineName = existingData == null
                              ? vaccineNameController.text.trim()
                              : (existingData['vaccineName'] as String? ?? '');
                          
                          if (finalVaccineName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a vaccine name')),
                            );
                            return;
                          }

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            // Get veterinarian name from text field
                            final veterinarianName = veterinarianController.text.trim();
                            
                            final entryData = {
                              'petId': widget.petId,
                              'petName': widget.petName,
                              'vaccineName': finalVaccineName,
                              'speciesType': _petSpecies, // Store species with the record
                              'date': Timestamp.fromDate(selectedDate),
                              'vetId': selectedVetId,
                              'vetName': veterinarianName.isNotEmpty ? veterinarianName : 'Unknown',
                              'userId': user.uid,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (existingData == null) {
                              // Add new entry
                              entryData['createdAt'] = FieldValue.serverTimestamp();
                              await FirebaseFirestore.instance
                                  .collection('petImmunizations')
                                  .add(entryData);
                            } else {
                              // Update existing entry
                              await FirebaseFirestore.instance
                                  .collection('petImmunizations')
                                  .doc(existingData['id'] as String)
                                  .update(entryData);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    existingData == null
                                        ? 'Vaccine added successfully'
                                        : 'Vaccine updated successfully',
                                  ),
                                  backgroundColor: _mint,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error saving vaccine: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mint,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to format vet name with "Dr." prefix
  String _formatVetName(String? vetName) {
    if (vetName == null || vetName.isEmpty || vetName == '-') {
      return '-';
    }
    // Remove "Dr." if already present to avoid duplication
    String cleanName = vetName.trim();
    if (cleanName.startsWith('Dr.') || cleanName.startsWith('Dr ')) {
      cleanName = cleanName.replaceFirst(RegExp(r'^Dr\.?\s*'), '').trim();
    }
    return 'Dr. $cleanName';
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/furever2.png', height: 30),
            const SizedBox(width: 8),
            const Text(
              'Vaccine',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pet name header with Add button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.petName}\'s Vaccines',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                    _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                    color: _mint,
                  ),
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),
          // Filter section
          if (_showFilters)
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 600;
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          // Veterinarian filter
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? double.infinity : 160,
                              minWidth: isSmallScreen ? double.infinity : 140,
                            ),
                            child: Builder(
                              builder: (context) {
                                final uniqueVetNames = _immunizations.values
                                    .map((data) => data['vetName'] as String?)
                                    .where((name) => name != null && name != 'Unknown' && name.isNotEmpty)
                                    .toSet()
                                    .toList()
                                  ..sort();
                                
                                return DropdownButtonFormField<String?>(
                                  value: _filterVeterinarian,
                                  decoration: const InputDecoration(
                                    labelText: 'Veterinarian',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<String?>(value: null, child: Text('All')),
                                    ...uniqueVetNames.map((name) => DropdownMenuItem<String?>(
                                      value: name,
                                      child: Text(
                                        _formatVetName(name),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _filterVeterinarian = value;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          // Vaccine type filter
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? double.infinity : 160,
                              minWidth: isSmallScreen ? double.infinity : 140,
                            ),
                            child: DropdownButtonFormField<String?>(
                              value: _filterVaccineType,
                              decoration: const InputDecoration(
                                labelText: 'Vaccine Type',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              items: () {
                                final vaccineNames = _immunizations.keys.toList()..sort();
                                return <DropdownMenuItem<String?>>[
                                  const DropdownMenuItem<String?>(value: null, child: Text('All')),
                                  ...vaccineNames.map((name) => DropdownMenuItem<String?>(
                                    value: name,
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                                ];
                              }(),
                              onChanged: (value) {
                                setState(() {
                                  _filterVaccineType = value;
                                });
                              },
                            ),
                          ),
                          // Date range start
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? double.infinity : 140,
                              minWidth: isSmallScreen ? double.infinity : 120,
                            ),
                            child: InkWell(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _filterDateStart ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: _mint,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Colors.black87,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    _filterDateStart = pickedDate;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date From',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                child: Text(
                                  _filterDateStart != null
                                      ? DateFormat(isSmallScreen ? 'MM/dd/yy' : 'MMM dd, yyyy').format(_filterDateStart!)
                                      : 'Select date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _filterDateStart != null ? Colors.black87 : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          // Date range end
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? double.infinity : 140,
                              minWidth: isSmallScreen ? double.infinity : 120,
                            ),
                            child: InkWell(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _filterDateEnd ?? DateTime.now(),
                                  firstDate: _filterDateStart ?? DateTime(2000),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: _mint,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Colors.black87,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    _filterDateEnd = pickedDate;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date To',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                child: Text(
                                  _filterDateEnd != null
                                      ? DateFormat(isSmallScreen ? 'MM/dd/yy' : 'MMM dd, yyyy').format(_filterDateEnd!)
                                      : 'Select date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _filterDateEnd != null ? Colors.black87 : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          // Clear filters button
                          SizedBox(
                            width: isSmallScreen ? double.infinity : null,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filterVeterinarian = null;
                                  _filterDateStart = null;
                                  _filterDateEnd = null;
                                  _filterVaccineType = null;
                                });
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          // Vaccine table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isSmallScreen = screenWidth < 400;
                      
                      // Calculate column widths based on screen size
                      final vaccineWidth = isSmallScreen ? 100.0 : 120.0;
                      final dateWidth = isSmallScreen ? 90.0 : 100.0;
                      final vetWidth = isSmallScreen ? 100.0 : 120.0;
                      final actionWidth = isSmallScreen ? 80.0 : 100.0;
                      final totalWidth = vaccineWidth + dateWidth + vetWidth + actionWidth + 48; // +48 for padding
                      
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: totalWidth,
                                maxWidth: screenWidth > totalWidth ? screenWidth - 16 : totalWidth,
                              ),
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
                              child: DataTable(
                                headingRowHeight: isSmallScreen ? 45 : 50,
                                columnSpacing: isSmallScreen ? 8 : 12,
                                headingRowColor: MaterialStateProperty.all(
                                  _mint, // Green header
                                ),
                                columns: [
                                  DataColumn(
                                    label: SizedBox(
                                      width: vaccineWidth,
                                      child: Text(
                                        'Vaccine',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: dateWidth,
                                      child: Text(
                                        'Date',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: vetWidth,
                                      child: Text(
                                        'Veterinarian',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: actionWidth,
                                      child: Text(
                                        'Actions',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _buildTableRows(isSmallScreen, vaccineWidth, dateWidth, vetWidth, actionWidth),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Get filtered immunizations based on current filters
  Map<String, Map<String, dynamic>> get _filteredImmunizations {
    Map<String, Map<String, dynamic>> filtered = Map.from(_immunizations);
    
    // Filter by veterinarian
    if (_filterVeterinarian != null) {
      filtered = Map.fromEntries(filtered.entries.where((entry) {
        final vetName = entry.value['vetName'] as String?;
        return vetName == _filterVeterinarian;
      }));
    }
    
    // Filter by date range
    if (_filterDateStart != null || _filterDateEnd != null) {
      filtered = Map.fromEntries(filtered.entries.where((entry) {
        final date = entry.value['date'] as Timestamp?;
        if (date == null) return false;
        final vaccineDate = date.toDate();
        final start = DateTime(_filterDateStart?.year ?? 2000, _filterDateStart?.month ?? 1, _filterDateStart?.day ?? 1);
        final end = DateTime(_filterDateEnd?.year ?? 2100, _filterDateEnd?.month ?? 12, _filterDateEnd?.day ?? 31, 23, 59, 59);
        return vaccineDate.isAfter(start.subtract(const Duration(days: 1))) && 
               vaccineDate.isBefore(end.add(const Duration(days: 1)));
      }));
    }
    
    // Filter by vaccine type
    if (_filterVaccineType != null) {
      filtered = Map.fromEntries(filtered.entries.where((entry) {
        return entry.key == _filterVaccineType;
      }));
    }
    
    return filtered;
  }

  List<DataRow> _buildTableRows(bool isSmallScreen, double vaccineWidth, double dateWidth, double vetWidth, double actionWidth) {
    final filtered = _filteredImmunizations;
    final vaccineNames = filtered.keys.toList()..sort((a, b) => a.compareTo(b));
    return vaccineNames.map((vaccineName) {
      final vaccineData = filtered[vaccineName];
      final hasData = vaccineData != null;
      final recordUserId = hasData ? (vaccineData['userId'] as String?) : null;
      final canEdit = recordUserId == _currentUserId; // Only creator can edit
      
      return DataRow(
        color: MaterialStateProperty.all(_mint.withOpacity(0.1)), // Light green background
        cells: [
          DataCell(
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: vaccineWidth,
              ),
              child: Text(
                vaccineName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DataCell(
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dateWidth,
              ),
              child: Text(
                hasData && vaccineData['date'] != null
                    ? DateFormat(isSmallScreen ? 'MM/dd/yy' : 'yyyy-MM-dd').format(
                        (vaccineData['date'] as Timestamp).toDate(),
                      )
                    : '-',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  color: hasData && vaccineData['date'] != null
                      ? Colors.black87
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
          DataCell(
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: vetWidth,
              ),
              child: Text(
                hasData
                    ? _formatVetName(vaccineData['vetName'] as String?)
                    : '-',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  color: hasData
                      ? Colors.black87
                      : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DataCell(
            canEdit && hasData
                ? _buildActionButton(
                    vaccineName,
                    vaccineData,
                    isSmallScreen: isSmallScreen,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildActionButton(String vaccineName, Map<String, dynamic> vaccineData, {bool isSmallScreen = false}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isSmallScreen ? 70 : 85,
        minHeight: 0,
        maxHeight: double.infinity,
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          _addOrEditVaccine(vaccineName, existingData: vaccineData);
        },
        icon: const Icon(
          Icons.edit,
          color: Colors.white,
          size: 16,
        ),
        label: Text(
          'Edit',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 11 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _mint,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 6 : 10,
            vertical: isSmallScreen ? 6 : 8,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

}
