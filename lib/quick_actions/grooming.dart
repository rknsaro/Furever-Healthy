import 'package:flutter/material.dart';

class GroomingPage extends StatelessWidget {
  const GroomingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grooming'),
      ),
      body: const Center(
        child: Text('This is the Grooming page.'),
      ),
    );
  }
}