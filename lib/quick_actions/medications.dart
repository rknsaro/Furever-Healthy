import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fureverhealthy/utils/reminder_service.dart';

const _mint = Color(0xFF6F994A);
const _screenBg = Color(0xFFF6F8FB);

class MedicationsPage extends StatefulWidget {
  final String? medicationId; // For editing existing medications
  final String? petName; // Pre-selected pet name from all_pets.dart

  const MedicationsPage({super.key, this.medicationId, this.petName});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _frequencyIntervalController =
      TextEditingController();

  String _dosageUnit = 'Pill';
  String _scheduleType = 'On Schedule';
  // Frequency (e.g., every 1 Day)
  int _frequencyInterval = 1;
  String _frequencyUnit = 'Day';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<Map<String, dynamic>> _timings = [];
  List<String> _selectedPets = [];
  List<String> _pets = [];
  bool _isLoadingPets = true;
  bool _isLoadingMedication = false;
  bool _isSaving = false;

  final List<String> _dosageUnits = [
    'Pill',
    'Drop',
    'Capsule',
    'Tablet',
    'ml',
    'g',
    'cm',
    'Tube',
    'unit',
  ];
  final List<String> _scheduleTypes = ['On Schedule', 'As Needed'];
  final List<String> _frequencyUnits = ['Day', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {}); // Update character count
    });
    _descriptionController.addListener(() {
      setState(() {}); // Update character count
    });
    _frequencyIntervalController.text = _frequencyInterval.toString();
    _frequencyIntervalController.addListener(() {
      final parsed = int.tryParse(_frequencyIntervalController.text);
      if (parsed != null && parsed > 0) {
        setState(() {
          _frequencyInterval = parsed;
        });
      }
    });

    // If petName is provided, auto-select it
    if (widget.petName != null && widget.petName!.isNotEmpty) {
      _selectedPets = [widget.petName!];
    }

    // Initialize default timing with controller
    final defaultController = TextEditingController(text: '1');
    defaultController.addListener(() {
      final intValue = int.tryParse(defaultController.text) ?? 1;
      if (_timings.isNotEmpty) {
        setState(() {
          _timings[0]['pills'] = intValue;
        });
      }
    });
    _timings = [
      {
        'time': TimeOfDay(hour: 8, minute: 0),
        'pills': 1,
        'controller': defaultController,
      },
    ];

    _loadPets();
    if (widget.medicationId != null) {
      _loadMedication();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _frequencyIntervalController.dispose();
    // Dispose timing controllers
    for (final timing in _timings) {
      final controller = timing['controller'] as TextEditingController?;
      controller?.dispose();
    }
    super.dispose();
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
        _isLoadingPets = false;
      });
    } catch (e) {
      setState(() {
        _pets = [];
        _isLoadingPets = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
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
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
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
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _showDosageUnitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Dosage Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _dosageUnits.map((unit) {
              return ListTile(
                title: Text(unit),
                onTap: () {
                  setState(() {
                    _dosageUnit = unit;
                  });
                  Navigator.pop(context);
                },
                selected: _dosageUnit == unit,
                selectedTileColor: _mint.withOpacity(0.1),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showScheduleTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Schedule Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _scheduleTypes.map((type) {
              return ListTile(
                title: Text(type),
                onTap: () {
                  setState(() {
                    _scheduleType = type;
                  });
                  Navigator.pop(context);
                },
                selected: _scheduleType == type,
                selectedTileColor: _mint.withOpacity(0.1),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showFrequencyUnitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _frequencyUnits.map((unit) {
              return ListTile(
                title: Text(unit),
                onTap: () {
                  setState(() {
                    _frequencyUnit = unit;
                  });
                  Navigator.pop(context);
                },
                selected: _frequencyUnit == unit,
                selectedTileColor: _mint.withOpacity(0.1),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _addTiming() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
    if (picked != null) {
      final controller = TextEditingController(text: '1');
      controller.addListener(() {
        final intValue = int.tryParse(controller.text) ?? 1;
        final index = _timings.indexWhere((t) => t['controller'] == controller);
        if (index != -1) {
          setState(() {
            _timings[index]['pills'] = intValue;
          });
        }
      });
      setState(() {
        _timings.add({'time': picked, 'pills': 1, 'controller': controller});
        _timings.sort((a, b) {
          final aTime = a['time'] as TimeOfDay;
          final bTime = b['time'] as TimeOfDay;
          final aMinutes = aTime.hour * 60 + aTime.minute;
          final bMinutes = bTime.hour * 60 + bTime.minute;
          return aMinutes.compareTo(bMinutes);
        });
      });
    }
  }

  void _removeTiming(int index) {
    final timing = _timings[index];
    final controller = timing['controller'] as TextEditingController?;
    controller?.dispose();
    setState(() {
      _timings.removeAt(index);
    });
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Pets'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _pets.map((pet) {
                  final isSelected = _selectedPets.contains(pet);
                  return ListTile(
                    title: Text(pet),
                    onTap: () {
                      setDialogState(() {
                        if (isSelected) {
                          _selectedPets.remove(pet);
                        } else {
                          if (!_selectedPets.contains(pet)) {
                            _selectedPets.add(pet);
                          }
                        }
                      });
                    },
                    selected: isSelected,
                    selectedTileColor: _mint.withOpacity(0.1),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: _mint)
                        : null,
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadMedication() async {
    if (widget.medicationId == null) return;

    setState(() {
      _isLoadingMedication = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingMedication = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('medications')
          .doc(widget.medicationId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _dosageUnit = data['dosageUnit'] ?? 'Pill';
          _scheduleType = data['scheduleType'] ?? 'On Schedule';

          final frequency = data['frequency'] as Map<String, dynamic>?;
          if (frequency != null) {
            _frequencyInterval = frequency['interval'] as int? ?? 1;
            _frequencyUnit = frequency['unit'] as String? ?? 'Day';
            _frequencyIntervalController.text = _frequencyInterval.toString();
          }

          if (data['startDate'] != null) {
            _startDate = (data['startDate'] as Timestamp).toDate();
          }
          if (data['endDate'] != null) {
            _endDate = (data['endDate'] as Timestamp).toDate();
          }

          _selectedPets =
              (data['pets'] as List?)?.map((e) => e.toString()).toList() ?? [];

          // Dispose old timing controllers before replacing
          for (final timing in _timings) {
            final controller = timing['controller'] as TextEditingController?;
            controller?.dispose();
          }

          final timingsList = data['timings'] as List?;
          if (timingsList != null && timingsList.isNotEmpty) {
            _timings = timingsList.map((t) {
              final timing = Map<String, dynamic>.from(t as Map);
              final pills = timing['pills'] as int? ?? 1;
              final controller = TextEditingController(text: pills.toString());
              controller.addListener(() {
                final intValue = int.tryParse(controller.text) ?? 1;
                final index = _timings.indexWhere(
                  (timing) => timing['controller'] == controller,
                );
                if (index != -1) {
                  setState(() {
                    _timings[index]['pills'] = intValue;
                  });
                }
              });
              return {
                'time': TimeOfDay(
                  hour: timing['hour'] as int? ?? 8,
                  minute: timing['minute'] as int? ?? 0,
                ),
                'pills': pills,
                'controller': controller,
              };
            }).toList();
          } else {
            // If no timings, keep the default one
            _timings = _timings.isEmpty ? [] : _timings;
          }

          _isLoadingMedication = false;
        });
      } else {
        setState(() {
          _isLoadingMedication = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMedication = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading medication: $e')));
      }
    }
  }

  String _getNextMedicationPreview() {
    if (_timings.isEmpty) {
      return 'No timings added';
    }
    // Use the first timing and the selected start date to build a preview
    final firstTiming = _timings.first;
    final time = firstTiming['time'] as TimeOfDay;

    final nextDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      time.hour,
      time.minute,
    );

    final formatted = DateFormat('d MMM, h:mm a').format(nextDateTime);
    return 'Next medication on $formatted';
  }

  Future<void> _saveMedication() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter medication name')),
      );
      return;
    }

    // If petName was pre-selected, ensure it's still in the list
    if (widget.petName != null && widget.petName!.isNotEmpty) {
      if (!_selectedPets.contains(widget.petName)) {
        _selectedPets = [widget.petName!];
      }
    }

    if (_selectedPets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pet')),
      );
      return;
    }

    if (_timings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one timing')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to save medications')),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final medicationData = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dosageUnit': _dosageUnit,
        'scheduleType': _scheduleType,
        'frequency': {'interval': _frequencyInterval, 'unit': _frequencyUnit},
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'pets': _selectedPets,
        'timings': _timings
            .map(
              (t) => {
                'hour': (t['time'] as TimeOfDay).hour,
                'minute': (t['time'] as TimeOfDay).minute,
                'pills': t['pills'],
              },
            )
            .toList(),
        'updatedAt': Timestamp.now(),
      };

      if (widget.medicationId != null) {
        // Update existing medication
        await FirebaseFirestore.instance
            .collection('medications')
            .doc(widget.medicationId)
            .update(medicationData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication updated successfully!'),
              backgroundColor: _mint,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate update
        }
      } else {
        // Create new medication
        medicationData['createdAt'] = Timestamp.now();
        final docRef = await FirebaseFirestore.instance
            .collection('medications')
            .add(medicationData);

        // Get petIds from pet names
        final user = FirebaseAuth.instance.currentUser;
        final Map<String, String> petNameToIdMap = {};
        if (user != null && _selectedPets.isNotEmpty) {
          final petSnapshot = await FirebaseFirestore.instance
              .collection('petInfos')
              .where('userId', isEqualTo: user.uid)
              .get();
          for (final doc in petSnapshot.docs) {
            final data = doc.data();
            final name = (data['name'] as String?)?.trim();
            if (name != null && _selectedPets.contains(name)) {
              petNameToIdMap[name] = doc.id;
            }
          }
        }

        // Create medical history entries for each pet
        for (final petName in _selectedPets) {
          final petId = petNameToIdMap[petName];
          if (petId != null) {
            // Build dosage string from timings
            final dosageParts = _timings
                .map((timing) {
                  final time = timing['time'] as TimeOfDay;
                  final pills = timing['pills'] as int;
                  final unitLabel = pills == 1
                      ? _dosageUnit
                      : '${_dosageUnit}s';
                  return '${pills} $unitLabel at ${time.format(context)}';
                })
                .join(', ');

            final frequencyText = _scheduleType == 'On Schedule'
                ? 'every ${_frequencyInterval} ${_frequencyUnit}${_frequencyInterval > 1 ? 's' : ''}'
                : 'as needed';

            final dosageString = _timings.length > 1
                ? '$dosageParts ($frequencyText)'
                : '$dosageParts ($frequencyText)';

            // Build notes combining description and schedule info
            final notesParts = <String>[];
            if (_descriptionController.text.trim().isNotEmpty) {
              notesParts.add(_descriptionController.text.trim());
            }
            notesParts.add('Schedule: $frequencyText');
            if (_endDate != null) {
              notesParts.add(
                'End date: ${DateFormat('MMM d, yyyy').format(_endDate!)}',
              );
            }

            // Create medical history entry
            final medicalHistoryData = {
              'petId': petId,
              'petName': petName,
              'type': 'Medicine',
              'name': _nameController.text.trim(),
              'date': Timestamp.fromDate(_startDate),
              'vetId': null, // Added by pet owner
              'vetName': 'Pet Owner',
              'userId': user!.uid,
              'notes': notesParts.join('\n'),
              'dosage': dosageString,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };

            await FirebaseFirestore.instance
                .collection('petMedicalHistory')
                .add(medicalHistoryData);
          }
        }

        // Create reminders and notifications for each pet and each timing
        for (final petName in _selectedPets) {
          final petId = petNameToIdMap[petName];
          for (final timing in _timings) {
            final time = timing['time'] as TimeOfDay;
            final pills = timing['pills'] as int;
            final unitLabel = pills == 1 ? _dosageUnit : '${_dosageUnit}s';

            // Calculate next medication time
            final now = DateTime.now();
            var reminderDateTime = DateTime(
              _startDate.year,
              _startDate.month,
              _startDate.day,
              time.hour,
              time.minute,
            );

            // If the start date is in the future, use it; otherwise use today/tomorrow
            if (reminderDateTime.isBefore(now)) {
              // If time has passed today, set for tomorrow
              reminderDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                time.hour,
                time.minute,
              );
              if (reminderDateTime.isBefore(now)) {
                reminderDateTime = reminderDateTime.add(
                  const Duration(days: 1),
                );
              }
            }

            await createReminderAndNotification(
              type: 'medication',
              title: 'Medication: ${_nameController.text.trim()}',
              description:
                  'Time: ${time.format(context)}\nDosage: $pills $unitLabel\nFor: $petName',
              petId: petId,
              petName: petName,
              reminderDateTime: reminderDateTime,
              itemId: docRef.id,
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication added successfully!'),
              backgroundColor: _mint,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate creation
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving medication: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteMedication() async {
    if (widget.medicationId == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('medications')
          .doc(widget.medicationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully!'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting medication: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMedication) {
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
            'Add Medications',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final int nameCharacterCount = _nameController.text.length;
    final int descriptionCharacterCount = _descriptionController.text.length;

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
          'Add medication',
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
            // Medicine details section
            const Text(
              'Medicine details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Name field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$nameCharacterCount/200',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$descriptionCharacterCount/200',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 24),

            // Dosage Unit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dosage Unit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: _showDosageUnitDialog,
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
                      _dosageUnit,
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
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 24),

            // Pets on medication section - only show if petName is not pre-selected
            if (widget.petName == null || widget.petName!.isEmpty) ...[
              const Text(
                'Pets on medication',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
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
                  child: Builder(
                    builder: (context) {
                      String label;
                      if (_isLoadingPets) {
                        label = 'Loading pets...';
                      } else if (_selectedPets.isEmpty) {
                        label = 'Select pets';
                      } else if (_selectedPets.length == 1) {
                        label = _selectedPets.first;
                      } else {
                        label =
                            '${_selectedPets.first} +${_selectedPets.length - 1}';
                      }
                      return Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300, height: 24),
            ],

            // Schedule section
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Medication is taken
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Medication is taken',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: _showScheduleTypeDialog,
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
                      _scheduleType,
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

            // To be given every
            const Text(
              'To be given every',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Interval input
                SizedBox(
                  width: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      controller: _frequencyIntervalController,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Unit chip
                GestureDetector(
                  onTap: _showFrequencyUnitDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _frequencyUnit,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // To be given at times
            const Text(
              'To be given at times',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ..._timings.asMap().entries.map((entry) {
              final index = entry.key;
              final timing = entry.value;
              final time = timing['time'] as TimeOfDay;
              final pills = timing['pills'] as int;
              final unitLabel = pills == 1 ? _dosageUnit : '${_dosageUnit}s';
              final controller =
                  timing['controller'] as TextEditingController? ??
                  TextEditingController(text: pills.toString());

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        time.format(context),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        controller: controller,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unitLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => _removeTiming(index),
                    ),
                  ],
                ),
              );
            }),
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
                onPressed: _addTiming,
                child: const Text(
                  'Add timing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 24),

            // Duration section
            const Text(
              'Duration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Start and End Date in one row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start Date
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectStartDate(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Date',
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
                            DateFormat('dd/MM/yy').format(_startDate),
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
                // End Date
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('End Date'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('No end date'),
                                onTap: () {
                                  setState(() {
                                    _endDate = null;
                                  });
                                  Navigator.pop(context);
                                },
                                selected: _endDate == null,
                                selectedTileColor: _mint.withOpacity(0.1),
                              ),
                              ListTile(
                                title: const Text('Select end date'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _selectEndDate(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Date',
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
                            _endDate == null
                                ? 'No end date'
                                : DateFormat('dd/MM/yy').format(_endDate!),
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
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 24),

            // Preview section
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getNextMedicationPreview(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Save/Add Button and Delete Button (if editing)
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
                onPressed: _isSaving ? null : _saveMedication,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.medicationId != null ? 'Save' : 'Add',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (widget.medicationId != null) ...[
              const SizedBox(height: 12),
              // Delete Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _deleteMedication,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
