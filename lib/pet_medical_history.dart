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
  StreamSubscription<QuerySnapshot>? _historySubscription;
  List<Map<String, dynamic>> _medicalHistory = [];
  bool _isLoading = true;
  bool _isVet = false;
  String? _currentVetId;
  String? _currentVetName;

  @override
  void initState() {
    super.initState();
    _checkIfVet();
    _loadMedicalHistory();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
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

  void _loadMedicalHistory() {
    _historySubscription?.cancel();

    _historySubscription = FirebaseFirestore.instance
        .collection('petMedicalHistory')
        .where('petId', isEqualTo: widget.petId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        setState(() {
          _medicalHistory = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          // Sort by date in memory (descending - most recent first)
          _medicalHistory.sort((a, b) {
            final aDate = a['date'] is Timestamp
                ? (a['date'] as Timestamp).toDate()
                : DateTime(2000);
            final bDate = b['date'] is Timestamp
                ? (b['date'] as Timestamp).toDate()
                : DateTime(2000);
            return bDate.compareTo(aDate); // Descending order
          });
          
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Error loading medical history: $error');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading history: $error')),
          );
        }
      },
    );
  }

  Future<void> _addOrEditEntry({Map<String, dynamic>? existingEntry}) async {
    // Allow anyone to add entries, but only vets can edit existing entries
    if (existingEntry != null && !_isVet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only veterinarians can edit medical history entries'),
        ),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController(
      text: existingEntry?['name'] as String? ?? '',
    );
    final TextEditingController notesController = TextEditingController(
      text: existingEntry?['notes'] as String? ?? '',
    );
    final TextEditingController dosageController = TextEditingController(
      text: existingEntry?['dosage'] as String? ?? '',
    );
    String selectedType = existingEntry?['type'] as String? ?? 'Vaccine';
    DateTime selectedDate = existingEntry?['date'] != null
        ? (existingEntry!['date'] as Timestamp).toDate()
        : DateTime.now();

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
                  existingEntry == null ? 'Add Entry' : 'Edit Entry',
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
                // Type dropdown
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Vaccine', 'Medicine'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Name field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter vaccine or medicine name',
                  ),
                ),
                const SizedBox(height: 16),
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
                      setDialogState(() => selectedDate = pickedDate);
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
                // Dosage field (for medicines)
                if (selectedType == 'Medicine')
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 5mg, 1 tablet',
                    ),
                  ),
                if (selectedType == 'Medicine') const SizedBox(height: 16),
                        // Notes field
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(),
                            hintText: 'Additional notes or instructions',
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  // Determine who is adding/editing
                  final isVetEntry = _isVet;
                  final entryData = {
                    'petId': widget.petId,
                    'petName': widget.petName,
                    'type': selectedType,
                    'name': nameController.text.trim(),
                    'date': Timestamp.fromDate(selectedDate),
                    'vetId': isVetEntry ? (_currentVetId ?? user.uid) : null,
                    'vetName': isVetEntry ? (_currentVetName ?? 'Veterinarian') : 'Pet Owner',
                    'userId': user.uid, // Track who added it
                    'notes': notesController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    if (selectedType == 'Medicine' && dosageController.text.trim().isNotEmpty)
                      'dosage': dosageController.text.trim(),
                  };

                  if (existingEntry == null) {
                    // Add new entry
                    entryData['createdAt'] = FieldValue.serverTimestamp();
                    await FirebaseFirestore.instance
                        .collection('petMedicalHistory')
                        .add(entryData);
                  } else {
                    // Update existing entry
                    await FirebaseFirestore.instance
                        .collection('petMedicalHistory')
                        .doc(existingEntry['id'] as String)
                        .update(entryData);
                  }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  existingEntry == null
                                      ? 'Entry added successfully'
                                      : 'Entry updated successfully',
                                ),
                                backgroundColor: _mint,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving entry: $e')),
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

    nameController.dispose();
    notesController.dispose();
    dosageController.dispose();
  }

  Future<void> _deleteEntry(String entryId) async {
    if (!_isVet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only veterinarians can delete entries'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('petMedicalHistory')
            .doc(entryId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted successfully'),
              backgroundColor: _mint,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting entry: $e')),
          );
        }
      }
    }
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
              'Medical History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _addOrEditEntry(),
            tooltip: 'Add Entry',
          ),
        ],
      ),
      body: Column(
        children: [
          // Pet name header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Text(
              '${widget.petName}\'s Medical History',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // History table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _medicalHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_information_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No medical history recorded',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add a vaccine or medicine entry',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
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
                                headingRowHeight: 50,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 120,
                                columnSpacing: 16,
                                headingRowColor: MaterialStateProperty.all(
                                  _mint.withOpacity(0.1),
                                ),
                                columns: [
                                  DataColumn(
                                    label: SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Date',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 70,
                                      child: Text(
                                        'Type',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Dosage',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 100,
                                      child: Text(
                                        'Veterinarian',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 150,
                                      child: Text(
                                        'Notes',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isVet)
                                    DataColumn(
                                      label: SizedBox(
                                        width: 100,
                                        child: Text(
                                          'Actions',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                                rows: _medicalHistory.map((entry) {
                                  final date = entry['date'] is Timestamp
                                      ? (entry['date'] as Timestamp).toDate()
                                      : DateTime.now();
                                  final type = entry['type'] as String? ?? 'Unknown';
                                  final name = entry['name'] as String? ?? '';
                                  final dosage = entry['dosage'] as String? ?? '-';
                                  final vetName = entry['vetName'] as String? ?? 'Unknown';
                                  final notes = entry['notes'] as String? ?? '';
                                  final entryId = entry['id'] as String;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            DateFormat('MMM dd\nyyyy').format(date),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 70,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: type == 'Vaccine'
                                                  ? Colors.blue.withOpacity(0.1)
                                                  : Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              type,
                                              style: TextStyle(
                                                color: type == 'Vaccine'
                                                    ? Colors.blue[700]
                                                    : Colors.orange[700],
                                                fontWeight: FontWeight.w500,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            name,
                                            style: const TextStyle(fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            dosage,
                                            style: const TextStyle(fontSize: 11),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            vetName,
                                            style: const TextStyle(fontSize: 11),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 150,
                                          child: Text(
                                            notes,
                                            style: const TextStyle(fontSize: 11),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      if (_isVet)
                                        DataCell(
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 18),
                                                  color: _mint,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 36,
                                                  ),
                                                  onPressed: () => _addOrEditEntry(
                                                    existingEntry: entry,
                                                  ),
                                                  tooltip: 'Edit',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, size: 18),
                                                  color: Colors.red,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 36,
                                                  ),
                                                  onPressed: () => _deleteEntry(entryId),
                                                  tooltip: 'Delete',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

