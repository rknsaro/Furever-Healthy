// lib/booking_details_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDetailsPage extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String profileImageAsset;
  final String selectedDate; // Date is still passed from previous page

  const BookingDetailsPage({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.profileImageAsset,
    required this.selectedDate,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  String? _selectedPetName; // State for selected pet
  String _selectedAppointmentType = 'Walk-in'; // State for appointment type
  String? _selectedTimeSlot; // State for selected time slot
  String _selectedReason = 'Regular Check-up'; // State for reason

  // Example data for pets and reasons
  final List<Map<String, String>> _availablePets = [
    {'name': 'Deabak', 'image': 'assets/dog.png'}, // Assuming a dog icon
    {'name': 'Ggomo', 'image': 'assets/cat.png'}, // Assuming a cat icon
    {'name': 'Buddy', 'image': 'assets/dog.png'},
  ];
  final List<String> _reasons = ['Regular Check-up', 'Vaccination', 'Emergency', 'Consultation'];

  // Hardcoded costs for reasons (you might fetch this dynamically)
  final Map<String, String> _reasonCosts = {
    'Regular Check-up': 'PHP 300',
    'Vaccination': 'PHP 500',
    'Emergency': 'PHP 1000',
    'Consultation': 'PHP 300',
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0D6),
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF61972E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/furever2.png', // Main app logo
              height: 40,
            ),
          ],
        ),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Details Card
              Container(
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFE8F0D6),
                      child: Image.asset(
                        widget.profileImageAsset,
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
                            widget.doctorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            widget.specialty,
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
                                    index < 5 ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                              const SizedBox(width: 10),
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
              ),
              const SizedBox(height: 20),

              // Select Pet Section
              const Text(
                'Select Pet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 80, // Height for the pet selection row
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availablePets.length,
                  itemBuilder: (context, index) {
                    final pet = _availablePets[index];
                    final isSelected = _selectedPetName == pet['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPetName = pet['name'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF61972E) : Colors.white,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              pet['image']!,
                              height: 30,
                              color: isSelected ? Colors.white : const Color(0xFF61972E),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              pet['name']!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Type of Appointment
              const Text(
                'Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildAppointmentTypeButton('Walk-in'),
                  const SizedBox(width: 10),
                  _buildAppointmentTypeButton('Online Consultation'),
                ],
              ),
              const SizedBox(height: 20),

              // Appointment time
              const Text(
                'Appointment time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: [
                  _buildTimeSlotButton('8:00 - 8:45 AM'),
                  _buildTimeSlotButton('9:00 - 9:45 AM'),
                  _buildTimeSlotButton('10:00 - 10:45 AM'),
                  _buildTimeSlotButton('11:00 - 11:45 AM'),
                  _buildTimeSlotButton('1:00 - 1:45 PM'),
                  _buildTimeSlotButton('2:00 - 2:45 PM'),
                  _buildTimeSlotButton('3:00 - 3:45 PM'),
                  _buildTimeSlotButton('4:00 - 4:45 PM'),
                  _buildTimeSlotButton('5:00 - 5:45 PM'),
                ],
              ),
              const SizedBox(height: 20),

              // Reason Dropdown
              const Text(
                'Reason',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedReason,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                    items: _reasons.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('$value  ${_reasonCosts[value]}', style: const TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedReason = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Appointment Summary
              const Text(
                'Appointment Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Container(
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
                    _buildSummaryRow('Pet:', _selectedPetName ?? 'Not selected'),
                    _buildSummaryRow('Type:', _selectedAppointmentType),
                    _buildSummaryRow('Reason:', _selectedReason),
                    _buildSummaryRow('Date & Time:', '${widget.selectedDate}, ${_selectedTimeSlot ?? 'Not selected'}'),
                    _buildSummaryRow('Estimated Cost:', _reasonCosts[_selectedReason] ?? 'N/A', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Cancel
                        Navigator.pop(context); // Go back
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0D6D6), // A light red/pink for cancel
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFE57373), fontSize: 16), // Darker red text
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate selections before confirming
                        if (_selectedPetName == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a pet.')),
                          );
                          return;
                        }
                        if (_selectedTimeSlot == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select an appointment time.')),
                          );
                          return;
                        }

                        // Handle Confirm Appointment
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Appointment Confirmed!')),
                        );
                        // You might want to navigate back to the home page or a success page
                        Navigator.popUntil(context, (route) => route.isFirst); // Go back to home
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF61972E), // Green for confirm
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentTypeButton(String type) {
    bool isSelected = _selectedAppointmentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAppointmentType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF61972E) : Colors.white,
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
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotButton(String time) {
    bool isSelected = _selectedTimeSlot == time;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeSlot = time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF61972E) : Colors.white,
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
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}