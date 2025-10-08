import 'package:flutter/material.dart';

class FeedingPage extends StatelessWidget {
  const FeedingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding'),
      ),
      body: const Center(
        child: Text('This is the Feeding page.'),
      ),
    );
  }
}