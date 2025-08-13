import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'pet_data.dart'; // Import the new PetData model

class PetProfilePage extends StatefulWidget {
  final String petName;
  final String petBreed;
  // Add new parameters to receive initial data for all editable fields
  final String initialImageAsset;
  final String initialGender;
  final String initialAge;
  final String initialHeight;
  final String initialWeight;

  const PetProfilePage({
    super.key,
    required this.petName,
    required this.petBreed,
    required this.initialImageAsset, // Now correctly passed as required
    required this.initialGender,
    required this.initialAge,
    required this.initialHeight,
    required this.initialWeight,
  });

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Editable state variables for pet details
  late String _currentPetName;
  late String _currentPetBreed;
  late String _currentPetImageAsset;
  late String _currentGender;
  late String _currentAge;
  late String _currentHeight;
  late String _currentWeight;

  // State to control calendar visibility for each section
  bool _showGroomingCalendar = false;
  bool _showVaccinationCalendar = false;
  bool _showCheckupCalendar = false;

  String? _selectedRepeatOption; // For Repeat dropdown
  String? _selectedReminderOption; // For Reminder dropdown

  // List of sample pet images for selection
  final List<String> _petImages = [
    'assets/dog.png', // Make sure you have these assets
    'assets/cat.png',
    // 'assets/pet_dog_2.png', // Uncomment if you have this asset
    // Add more pet image paths here
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedRepeatOption = 'Every month';
    _selectedReminderOption = 'Day before';

    // Initialize state variables with values passed from widget.
    // This is crucial for pre-populating the profile with existing pet data.
    _currentPetName = widget.petName;
    _currentPetBreed = widget.petBreed;
    _currentPetImageAsset = widget.initialImageAsset;
    _currentGender = widget.initialGender;
    _currentAge = widget.initialAge;
    _currentHeight = widget.initialHeight;
    _currentWeight = widget.initialWeight;
  }

  // Function to show the image selection dialog
  void _showImageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose a Pet Image'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _petImages.map((imagePath) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPetImageAsset = imagePath;
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(imagePath),
                    backgroundColor: Colors.grey[200],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show an editable text field dialog
  Future<void> _showEditDetailDialog(String title, String currentValue, Function(String) onSave) async {
    TextEditingController controller = TextEditingController(text: currentValue);
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter new $title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: const Color(0xFFE8F0D6),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF61972E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                onSave(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to show gender selection dialog
  void _showGenderSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.male, color: Color(0xFF61972E)),
                title: const Text('Male'),
                onTap: () {
                  setState(() {
                    _currentGender = 'Male';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.female, color: Color(0xFF61972E)),
                title: const Text('Female'),
                onTap: () {
                  setState(() {
                    _currentGender = 'Female';
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0D6),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF61972E),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () {
                // IMPORTANT: Pass the updated data back when popping
                Navigator.pop(
                  context,
                  PetData(
                    name: _currentPetName,
                    breed: _currentPetBreed,
                    imageAsset: _currentPetImageAsset,
                    gender: _currentGender,
                    age: _currentAge,
                    height: _currentHeight,
                    weight: _currentWeight,
                  ),
                );
              },
            ),
            title: Image.asset(
              'assets/furever2.png', // Ensure this asset exists
              height: 40,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                onPressed: () {
                  print('Notification icon tapped!');
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP SECTION: Pet Profile Picture, Name, and Breed
                    Container(
                      color: const Color(0xFFE8F0D6),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showImageSelectionDialog, // Call dialog on tap
                            child: CircleAvatar(
                              radius: 60, // Keep this radius for the background circle
                              backgroundColor: Colors.grey[300],
                              // Use a conditional child to display either the image or the default icon
                              child: _currentPetImageAsset.isEmpty
                                  ? Icon(Icons.pets, size: 20, color: Colors.grey[600]) // Adjust icon size if needed
                                  : ClipOval( // ClipOval to ensure the image is circular
                                        child: Image.asset(
                                          _currentPetImageAsset,
                                          fit: BoxFit.cover, // Ensures the image covers the circle
                                          width: 120, // Should match 2 * radius for full coverage
                                          height: 120, // Should match 2 * radius for full coverage
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Pet Name - now editable
                          GestureDetector(
                            onTap: () => _showEditDetailDialog('Pet Name', _currentPetName, (newValue) {
                              setState(() {
                                _currentPetName = newValue;
                              });
                            }),
                            child: Text(
                              _currentPetName, // Use the state variable
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Pet Breed - now editable
                          GestureDetector(
                            onTap: () => _showEditDetailDialog('Pet Breed', _currentPetBreed, (newValue) {
                              setState(() {
                                _currentPetBreed = newValue;
                              });
                            }),
                            child: Text(
                              _currentPetBreed, // Use the state variable
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pet Details Section (Gender, Age, Height, Weight)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDetailItem(
                                  _currentGender.toLowerCase() == 'male' ? Icons.male : Icons.female,
                                  _currentGender,
                                  onTap: _showGenderSelectionDialog, // Editable
                                ),
                                _buildDetailItem(
                                  Icons.cake_outlined,
                                  _currentAge,
                                  onTap: () => _showEditDetailDialog('Age', _currentAge, (newValue) {
                                    setState(() {
                                      _currentAge = newValue;
                                    });
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDetailItem(
                                  Icons.height,
                                  _currentHeight,
                                  onTap: () => _showEditDetailDialog('Height', _currentHeight, (newValue) {
                                    setState(() {
                                      _currentHeight = newValue;
                                    });
                                  }),
                                ),
                                _buildDetailItem(
                                  Icons.scale,
                                  _currentWeight,
                                  onTap: () => _showEditDetailDialog('Weight', _currentWeight, (newValue) {
                                    setState(() {
                                      _currentWeight = newValue;
                                    });
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rest of your sections (Grooming, Vaccination, Check-up)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildActionCard(
                            context,
                            'Grooming',
                            () {
                              setState(() {
                                _showGroomingCalendar = !_showGroomingCalendar;
                                _showVaccinationCalendar = false;
                                _showCheckupCalendar = false;
                              });
                            },
                            _showGroomingCalendar,
                          ),
                          Visibility(
                            visible: _showGroomingCalendar,
                            child: _buildCalendarAndReminderSection(title: 'Grooming'),
                          ),
                          const SizedBox(height: 15),

                          _buildActionCard(
                            context,
                            'Vaccination',
                            () {
                              setState(() {
                                _showVaccinationCalendar = !_showVaccinationCalendar;
                                _showGroomingCalendar = false;
                                _showCheckupCalendar = false;
                              });
                            },
                            _showVaccinationCalendar,
                          ),
                          Visibility(
                            visible: _showVaccinationCalendar,
                            child: _buildCalendarAndReminderSection(title: 'Vaccination'),
                          ),
                          const SizedBox(height: 15),

                          _buildActionCard(
                            context,
                            'Check-up',
                            () {
                              setState(() {
                                _showCheckupCalendar = !_showCheckupCalendar;
                                _showGroomingCalendar = false;
                                _showVaccinationCalendar = false;
                              });
                            },
                            _showCheckupCalendar,
                          ),
                          Visibility(
                            visible: _showCheckupCalendar,
                            child: _buildCalendarAndReminderSection(title: 'Check-up'),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for pet details (now with onTap for editing)
  Widget _buildDetailItem(IconData iconData, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Add onTap here
        child: Column(
          children: [
            Icon(
              iconData,
              size: 30,
              color: const Color(0xFF61972E),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for action cards (unchanged)
  Widget _buildActionCard(BuildContext context, String title, VoidCallback onTap, bool isCalendarOpen) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            Icon(isCalendarOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey, size: 28),
          ],
        ),
      ),
    );
  }

  // New helper method to build the calendar and reminder section (unchanged)
  Widget _buildCalendarAndReminderSection({required String title}) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              rightChevronIcon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFFE8F0D6),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF61972E),
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: true,
              weekendTextStyle: const TextStyle(color: Colors.grey),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              weekendStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          _buildDropdownRow('Repeat', _selectedRepeatOption, ['Every month', 'Every 3 months', 'Every 6 months', 'Every year'], (String? newValue) {
            setState(() {
              _selectedRepeatOption = newValue;
            });
          }),
          const SizedBox(height: 15),
          _buildDropdownRow('Reminder', _selectedReminderOption, ['Day before', 'Week before', 'On the day', '3 days before'], (String? newValue) {
            setState(() {
              _selectedReminderOption = newValue;
            });
          }),
        ],
      ),
    );
  }

  // Helper method for Repeat and Reminder dropdowns (unchanged)
  Widget _buildDropdownRow(String label, String? selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0D6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF61972E)),
                onChanged: onChanged,
                items: items.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                dropdownColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}