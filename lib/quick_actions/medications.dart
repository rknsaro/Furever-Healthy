import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  String selectedInterval = 'Month';
  DateTime? startDate = DateTime.now();
  DateTime? endDate;
  List<Map<String, dynamic>> timings = [
    {'time': TimeOfDay(hour: 8, minute: 0), 'pills': 1},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
      backgroundColor: _mint,
      centerTitle: true, // ✅ centers the title
      title: const Text(
        'New medication',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    )
    );
  }
}
