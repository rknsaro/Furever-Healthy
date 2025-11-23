import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fureverhealthy/utils/reminder_service.dart';

const _mint = Color(0xFF6F994A);

class GroomingPage extends StatefulWidget {
  final String? petId;
  final String? petName;

  const GroomingPage({super.key, this.petId, this.petName});

  @override
  State<GroomingPage> createState() => _GroomingPageState();
}

class _GroomingPageState extends State<GroomingPage> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedPetId;
  String? _selectedPetName;
  List<Map<String, dynamic>> _pets = [];
  bool _isLoadingPets = true;

  @override
  void initState() {
    super.initState();
    if (widget.petId != null) {
      _selectedPetId = widget.petId;
      _selectedPetName = widget.petName;
      _isLoadingPets = false;
    } else {
      _loadPets();
    }
  }

  Future<void> _loadPets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _pets = [];
          _isLoadingPets = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('petInfos')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _pets = snapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, 'name': data['name'] as String? ?? 'Unknown'};
        }).toList();
        _isLoadingPets = false;
      });
    } catch (e) {
      setState(() {
        _pets = [];
        _isLoadingPets = false;
      });
    }
  }

  // ✅ Dialog for adding grooming schedule
  void _showAddGroomingDialog() {
    _typeController.clear();
    _notesController.clear();
    _selectedDate = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Grooming Schedule',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pet Selection (only if no petId provided)
                if (widget.petId == null && !_isLoadingPets) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedPetId,
                    decoration: const InputDecoration(
                      labelText: 'Select Pet',
                      border: OutlineInputBorder(),
                    ),
                    items: _pets.map((pet) {
                      return DropdownMenuItem<String>(
                        value: pet['id'] as String,
                        child: Text(pet['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        _selectedPetId = value;
                        _selectedPetName =
                            _pets.firstWhere((p) => p['id'] == value)['name']
                                as String;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                // Grooming Type
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Grooming Type',
                    hintText: 'e.g. Bath, Nail Trim, Haircut',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setStateDialog(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Add any grooming notes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (widget.petId == null && _selectedPetId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a pet')),
                  );
                  return;
                }
                if (_typeController.text.isNotEmpty && _selectedDate != null) {
                  await _saveGrooming();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _mint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGrooming() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to save grooming')),
          );
        }
        return;
      }

      final petId = widget.petId ?? _selectedPetId;
      final petName = widget.petName ?? _selectedPetName;

      if (petId == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please select a pet')));
        }
        return;
      }

      final docRef = await FirebaseFirestore.instance.collection('groomings').add({
        'userId': user.uid,
        'petId': petId,
        'petName': petName,
        'type': _typeController.text.trim(),
        'date':
            '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
        'dateTimestamp': Timestamp.fromDate(_selectedDate!),
        'notes': _notesController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      // Create reminder and notification
      // Set reminder for the morning of the grooming date (9 AM)
      final reminderDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        9, // 9 AM
      );

      await createReminderAndNotification(
        type: 'grooming',
        title: 'Grooming: ${_typeController.text.trim()}',
        description:
            'Date: ${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}${_notesController.text.trim().isNotEmpty ? '\n${_notesController.text.trim()}' : ''}',
        petId: petId,
        petName: petName,
        reminderDateTime: reminderDateTime,
        itemId: docRef.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grooming schedule saved successfully'),
            backgroundColor: _mint,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving grooming: $e')));
      }
    }
  }

  Widget _buildCard({
    required String title,
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
                Image.asset(
                  'assets/pet_grooming.png',
                  width: 40,
                  height: 40,
                  color: _mint,
                ),
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

  Widget _buildGroomingList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Please log in to view grooming schedules.',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ),
      );
    }

    final petId = widget.petId;

    return StreamBuilder<QuerySnapshot>(
      stream: petId != null
          ? FirebaseFirestore.instance
                .collection('groomings')
                .where('userId', isEqualTo: user.uid)
                .where('petId', isEqualTo: petId)
                .snapshots()
          : FirebaseFirestore.instance
                .collection('groomings')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Error loading groomings: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'No grooming schedules yet.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          );
        }

        // Sort by createdAt in descending order (newest first)
        final sortedDocs = snapshot.data!.docs.toList()
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

        return Column(
          children: sortedDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] as String? ?? '';
            final date = data['date'] as String? ?? '';
            final notes = data['notes'] as String? ?? '';
            final petName = data['petName'] as String?;

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
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (petName != null && widget.petId == null)
                      Text(
                        'For: $petName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '$date${notes.isNotEmpty ? '\n$notes' : ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                isThreeLine:
                    notes.isNotEmpty ||
                    (petName != null && widget.petId == null),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteGrooming(doc.id),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _deleteGrooming(String groomingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groomings')
          .doc(groomingId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grooming schedule deleted'),
            backgroundColor: _mint,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ Header copied from MedicationsPage
      appBar: AppBar(
        backgroundColor: _mint,
        centerTitle: true,
        title: const Text(
          'Pet Grooming',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Grooming section card
            _buildCard(
              title: 'Grooming',
              description:
                  'Set a schedule for your pet’s routine care and maintenance.',
              buttonText: 'Add grooming',
              onPressed: _showAddGroomingDialog,
            ),
            _buildGroomingList(),
          ],
        ),
      ),

      // ✅ Floating Centered Button
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: _mint,
      //   icon: const Icon(Icons.add, color: Colors.white),
      //   label: const Text(
      //     'New Grooming',
      //     style: TextStyle(
      //       color: Colors.white,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      //   onPressed: _showAddGroomingDialog,
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
