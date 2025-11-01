import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);
const _screenBg = Color(0xFFF6F8FB);

class BookAppointmentPage extends StatefulWidget {
  final String vetName;
  final String vetSpecialty;
  final int vetRating;

  const BookAppointmentPage({
    super.key,
    required this.vetName,
    required this.vetSpecialty,
    required this.vetRating,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  String? selectedPet;
  String? selectedReason;
  int? estimatedCost;
  String selectedType = 'Walk-in';
  String? selectedTime;
  DateTime selectedDate = DateTime.now();

  final List<String> pets = ['Spencer', 'Luna', 'Ggomo'];
  final List<Map<String, dynamic>> reasons = [
    {'label': 'Regular Check-up', 'price': 800},
    {'label': 'Grooming', 'price': 500},
    {'label': 'Vaccination', 'price': 300},
    {'label': 'Emergency', 'price': 1500},
    {'label': 'Consultation', 'price': 500},
  ];

  List<String> morningTimes = [
    '8:00 - 9:00 AM',
    '9:00 - 10:00 AM',
    '10:00 - 11:00 AM',
    '11:00 - 12:00 PM',
  ];
  List<String> afternoonTimes = [
    '1:00 - 2:00 PM',
    '2:00 - 3:00 PM',
    '3:00 - 4:00 PM',
    '4:00 - 5:00 PM',
  ];

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
        title: const Text(
          'Book an Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/notif_bell.png', width: 26),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Vet Card
              _buildSelectedVetCard(),
              const SizedBox(height: 24),

              // Appointment form
              _buildFormSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedVetCard() {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vet icon
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _mint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.person, size: 30, color: _mintDark),
          ),
          const SizedBox(width: 15),

          // Vet info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 5 Star Rating
                Row(
                  children: List.generate(
                    widget.vetRating,
                    (index) =>
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                  ),
                ),
                const SizedBox(height: 4),
                // Name
                Text(
                  widget.vetName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _mintDark,
                  ),
                ),
                const SizedBox(height: 3),
                // Specialty
                Text(
                  widget.vetSpecialty,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                // License Verified
                Row(
                  children: const [
                    Icon(Icons.verified, color: _mint, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'License Verified',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right arrow icon
          const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pets Section
        const Text('Pets', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildPetSelector(),
        const SizedBox(height: 20),

        // Type Section
        const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            _typeButton('Walk-in'),
            const SizedBox(width: 10),
            _typeButton('Online Consultation'),
          ],
        ),
        const SizedBox(height: 20),

        // Select Date
        const Text(
          'Select Date',
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

        // Reason Section
        const Text(
          'Reason',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          hint: const Text('Select reason'),
          items: reasons.map((r) {
            return DropdownMenuItem<String>(
              value: r['label'],
              child: Text('${r['label']} - PHP ${r['price']}'),
            );
          }).toList(),
          onChanged: (value) {
            final selected = reasons.firstWhere(
              (r) => r['label'] == value,
              orElse: () => {'price': 0},
            );
            setState(() {
              selectedReason = value;
              estimatedCost = selected['price'];
            });
          },
          value: selectedReason,
        ),
        const SizedBox(height: 20),

        // Appointment Summary
        _summaryCard(),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => _showCancelDialog(),
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
              onPressed: () {
                // Validate all required fields
                List<String> missingFields = [];

                if (selectedPet == null) {
                  missingFields.add('Pet');
                }
                if (selectedTime == null) {
                  missingFields.add('Appointment Time');
                }
                if (selectedReason == null) {
                  missingFields.add('Reason');
                }

                if (missingFields.isEmpty) {
                  // All fields are filled, proceed with booking
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment Booked Successfully!'),
                      backgroundColor: _mint,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  // Show error message with missing fields
                  String message =
                      'Please fill in the following fields: ${missingFields.join(', ')}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
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
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPetSelector() {
    return DropdownButtonFormField<String>(
      value: selectedPet,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: pets.map((pet) {
        return DropdownMenuItem(value: pet, child: Text(pet));
      }).toList(),
      onChanged: (value) => setState(() => selectedPet = value),
      hint: const Text('Select Pets'),
    );
  }

  Widget _typeButton(String type) {
    final bool selected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _mint : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _mint),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: selected ? Colors.white : _mint,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendar() {
    return CalendarDatePicker(
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years ahead
      onDateChanged: (date) => setState(() => selectedDate = date),
    );
  }

  Widget _buildTimeGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Morning Section
        const Text(
          'Morning',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: morningTimes.length,
          itemBuilder: (context, index) {
            final time = morningTimes[index];
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
                  time,
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: afternoonTimes.length,
          itemBuilder: (context, index) {
            final time = afternoonTimes[index];
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
                  time,
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

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _mintDark,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Pet:', selectedPet ?? '-'),
          _summaryRow('Type:', selectedType),
          _summaryRow('Reason:', selectedReason ?? '-'),
          _summaryRow(
            'Date & Time:',
            '${DateFormat('MMM d, yyyy').format(selectedDate)}, ${selectedTime ?? '-'}',
          ),
          _summaryRow(
            'Estimated Cost:',
            estimatedCost != null ? 'PHP $estimatedCost' : '-',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
