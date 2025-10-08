import 'package:flutter/material.dart';

class MedicationsPage extends StatelessWidget {
  const MedicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
      ),
      body: const Center(
        child: Text('This is the Medications page.'),
      ),
    );
  }
}