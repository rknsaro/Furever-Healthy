// lib/appointments.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fureverhealthy/booking_details_page.dart'; // Import the booking details page

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime _selectedDate = DateTime.now();
  late PageController _datePageController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    final int initialPage = _selectedDate.day - 1;
    _datePageController = PageController(initialPage: initialPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_datePageController.hasClients) {
        _datePageController.jumpToPage(initialPage);
      }
    });
  }

  @override
  void dispose() {
    _datePageController.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final int daysInSelectedMonth = _daysInMonth(_selectedDate.year, _selectedDate.month);
    final DateTime firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F0D6),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book an appointment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFilterButton('Location', isSelected: true),
                      _buildFilterButton('Specialty'),
                      _buildFilterButton('Rating'),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list, color: Colors.grey),
                          onPressed: () {
                            // Handle filter icon tap
                          },
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 60,
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedDate.month,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                        items: List.generate(12, (index) {
                          final month = index + 1;
                          final monthName = DateFormat('MMM').format(DateTime(2024, month));
                          return DropdownMenuItem<int>(
                            value: month,
                            child: Text(
                              monthName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }),
                        onChanged: (int? newMonth) {
                          if (newMonth != null) {
                            setState(() {
                              _selectedDate = DateTime(_selectedDate.year, newMonth, 1);
                              _datePageController.jumpToPage(0);
                            });
                          }
                        },
                        style: const TextStyle(color: Colors.black),
                        isExpanded: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _datePageController,
                      scrollDirection: Axis.horizontal,
                      itemCount: daysInSelectedMonth,
                      itemBuilder: (context, index) {
                        final date = firstDayOfMonth.add(Duration(days: index));
                        final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF61972E) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('MMM d').format(date),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEE').format(date),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available on ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  DoctorCard(
                    doctorName: 'Dr. Lucas Strong',
                    specialty: 'Small Animal Specialist',
                    rating: 5,
                    isLicenseVerified: true,
                    profileImageAsset: 'assets/vet.png',
                    availableTimes: const ['2:15 - 2:45 PM', '3:15 - 3:45 PM'],
                    onBookNow: () {
                      _navigateToBookingDetails(
                        doctorName: 'Dr. Lucas Strong',
                        specialty: 'Small Animal Specialist',
                        profileImageAsset: 'assets/vet.png',
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  DoctorCard(
                    doctorName: 'Dr. Lorem Garcia',
                    specialty: 'Small Animal Specialist',
                    rating: 5,
                    isLicenseVerified: true,
                    profileImageAsset: 'assets/vet.png',
                    availableTimes: const ['10:00 - 10:30 AM', '11:00 - 11:30 AM'],
                    onBookNow: () {
                      _navigateToBookingDetails(
                        doctorName: 'Dr. Lorem Ipsum',
                        specialty: 'Small Animal Specialist',
                        profileImageAsset: 'assets/vet.png',
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF61972E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFF61972E) : Colors.grey.shade300,
        ),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToBookingDetails({
    required String doctorName,
    required String specialty,
    required String profileImageAsset,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsPage(
          doctorName: doctorName,
          specialty: specialty,
          profileImageAsset: profileImageAsset,
          selectedDate: DateFormat('MMM d, yyyy').format(_selectedDate), // Pass only the selected date
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final int rating;
  final bool isLicenseVerified;
  final String profileImageAsset;
  final List<String> availableTimes;
  final VoidCallback onBookNow; // Changed to VoidCallback as time is selected on next page

  const DoctorCard({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.rating,
    required this.isLicenseVerified,
    required this.profileImageAsset,
    required this.availableTimes,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFE8F0D6),
                child: Image.asset(
                  profileImageAsset,
                  width: 40,
                  height: 40,
                  color: const Color(0xFF61972E),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      specialty,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                        const SizedBox(width: 10),
                        if (isLicenseVerified)
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'License Verified',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 15),
          // Available Times and Book Now Buttons
          Column(
            children: availableTimes.map((time) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: onBookNow, // No longer passing time, just navigating
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF61972E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Book now',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}