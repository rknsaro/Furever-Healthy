// lib/pet_profile.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Import the table_calendar package

class PetProfilePage extends StatefulWidget {
  final String petName;
  final String petBreed;
  final String gender;
  final String age;
  final String height;
  final String weight;
  final String petImageAsset;

  const PetProfilePage({
    super.key,
    required this.petName,
    required this.petBreed,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.petImageAsset,
  });

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay; // Nullable to indicate no selection initially
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showCalendar = false; // State to control calendar visibility

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Initialize selected day to today
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0D6),
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF61972E), // Header color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/furever2.png', // Logo from assets
              height: 40,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {
              print('Notification icon tapped!');
              // Implement notification logic
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Profile Header Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFC5E7A6), // Light green background
                    child: Image.asset(
                      'assets/${widget.petImageAsset}', // Use widget.petImageAsset
                      width: 60,
                      height: 60,
                      color: const Color(0xFF61972E), // Tint the image
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.petName, // Use widget.petName
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    widget.petBreed, // Use widget.petBreed
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pet Details Section (Male, Age, Height, Weight)
            Container(
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
                      _buildDetailItem(Icons.male, 'Gender', widget.gender), // Use widget.gender
                      _buildDetailItem(Icons.cake, 'Age', widget.age), // Use widget.age
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailItem(Icons.height, 'Height', widget.height), // Use widget.height
                      _buildDetailItem(Icons.line_weight, 'Weight', widget.weight), // Use widget.weight
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Grooming Section
            _buildActionCard(
              context,
              'Grooming',
              Icons.cut, // Placeholder icon
              () { print('Grooming tapped!'); },
            ),
            const SizedBox(height: 15),

            // Vaccination Section
            _buildActionCard(
              context,
              'Vaccination',
              Icons.vaccines, // Placeholder icon
              () { print('Vaccination tapped!'); },
            ),
            const SizedBox(height: 15),

            // Check-up Section with Calendar Dropdown
            _buildActionCard(
              context,
              'Check-up',
              Icons.calendar_month, // Placeholder icon
              () {
                setState(() {
                  _showCalendar = !_showCalendar; // Toggle calendar visibility
                });
                print('Check-up tapped! Calendar visibility: $_showCalendar');
              },
              trailingIcon: _showCalendar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, // Change arrow based on visibility
            ),
            // Conditionally show the calendar
            Visibility(
              visible: _showCalendar,
              child: Container(
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
                child: TableCalendar(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2050, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    // Use `isSameDay` to ensure that you are comparing dates correctly.
                    return isSameDay(_selectedDay, day);
                  },
                  calendarFormat: _calendarFormat,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay; // update `_focusedDay` here as well
                      print('Selected Date: $_selectedDay'); // Print selected date
                      // Optionally close the calendar after selection
                      // _showCalendar = false;
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
                  // Calendar Style Customization (Optional)
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false, // Hide the format button (Week/2 Weeks/Month)
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFFE8F0D6), // Light green for today
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: const Color(0xFF61972E), // Dark green for selected day
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: true, // Show days from previous/next month
                    weekendTextStyle: const TextStyle(color: Colors.grey),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    weekendStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF61972E), size: 30),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap, {IconData? trailingIcon}) {
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
            Row(
              children: [
                Icon(icon, color: const Color(0xFF61972E), size: 28),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
            Icon(trailingIcon ?? Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}