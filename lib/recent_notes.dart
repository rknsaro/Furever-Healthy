// lib/my_pets/recent_notes.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _mint = Color(0xFF6F994A);
const _screenBg = Color(0xFFF6F8FB);

class RecentNotesPage extends StatefulWidget {
  final String? initialPetName;

  const RecentNotesPage({super.key, this.initialPetName});

  @override
  State<RecentNotesPage> createState() => _RecentNotesPageState();
}

class _RecentNotesPageState extends State<RecentNotesPage> {
  String _noteType = 'General';
  String _activityType = 'Walk';
  String? _selectedPet;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final TextEditingController _noteController = TextEditingController();
  final List<String> noteTypes = ['General', 'Vet appointment', 'Activity'];
  final List<String> activityTypes = ['Walk', 'Run', 'Food', 'Water'];
  List<String> _pets = [];
  bool _isLoadingPets = true;

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.initialPetName;
    _noteController.addListener(() {
      setState(() {}); // Update character count
    });
    _loadPets();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          if (widget.initialPetName != null) {
            _pets = [widget.initialPetName!];
          } else {
            _pets = [];
          }
          _selectedPet ??= _pets.isNotEmpty ? _pets.first : null;
          _isLoadingPets = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('petInfos')
          .where('userId', isEqualTo: user.uid)
          .get();

      final names =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                return (data['name'] as String?)?.trim();
              })
              .whereType<String>()
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      setState(() {
        _pets = names;
        if (_pets.isNotEmpty) {
          if (_selectedPet == null || !_pets.contains(_selectedPet)) {
            _selectedPet = _pets.contains(widget.initialPetName)
                ? widget.initialPetName
                : _pets.first;
          }
        } else {
          _selectedPet = widget.initialPetName;
        }
        _isLoadingPets = false;
      });
    } catch (e) {
      setState(() {
        if (widget.initialPetName != null) {
          _pets = [widget.initialPetName!];
        } else {
          _pets = [];
        }
        _selectedPet ??= _pets.isNotEmpty ? _pets.first : null;
        _isLoadingPets = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _mint,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _mint,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showNoteTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Note Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: noteTypes.map((type) {
              return ListTile(
                title: Text(type),
                onTap: () {
                  setState(() {
                    _noteType = type;
                  });
                  Navigator.pop(context);
                },
                selected: _noteType == type,
                selectedTileColor: _mint.withOpacity(0.1),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showActivityTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Activity Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: activityTypes.map((type) {
              return ListTile(
                title: Text(type),
                onTap: () {
                  setState(() {
                    _activityType = type;
                  });
                  Navigator.pop(context);
                },
                selected: _activityType == type,
                selectedTileColor: _mint.withOpacity(0.1),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showPetSelectionDialog() {
    if (_isLoadingPets) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loading pets...')));
      return;
    }

    if (_pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pets found. Add a pet first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Pet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _pets.map((pet) {
              return ListTile(
                title: Text(pet),
                onTap: () {
                  setState(() {
                    _selectedPet = pet;
                  });
                  Navigator.pop(context);
                },
                selected: _selectedPet == pet,
                selectedTileColor: _mint.withOpacity(0.1),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int characterCount = _noteController.text.length;

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
          'Note',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/notif_bell.png', width: 24),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note Type Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Note Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: _showNoteTypeDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _mint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _noteType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity Type (only shows when Activity is selected)
            if (_noteType == 'Activity') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activity Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showActivityTypeDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _mint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _activityType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Text Field with Character Count
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _noteController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      counterText: '', // Hide default counter
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$characterCount/500',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pets Section
            const Text(
              'Pets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
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
                onPressed: _showPetSelectionDialog,
                child: Text(
                  _isLoadingPets
                      ? 'Loading pets...'
                      : (_selectedPet ?? 'Select pet'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            DateFormat('d MMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Time
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Add Button
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
                onPressed: () {
                  // Handle add note logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note added successfully!'),
                      backgroundColor: _mint,
                    ),
                  );
                },
                child: const Text(
                  'Add',
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
      ),
    );
  }
}
