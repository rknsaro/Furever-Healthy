// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'login_page.dart'; // Adjust this import path as needed

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Removed screenHeight, screenWidth, baseDesignWidth, and scaleFactor

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6F994A), // 6F994A - stops at 50% (opacity 100)
              Color(0xebcf112f15), // 112F15 - stops at 100% (opacity 92)
            ],
            stops: [0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              // Using fhlogo.png from previous context, set to a fixed size
              Image.asset(
                'assets/fhlogo.png',
                width: 200, // Fixed size
                height: 200, // Fixed size
              ),

              const SizedBox(height: 50), // Fixed spacing

              // Get Started Button
              ElevatedButton(
                onPressed: () {
                  // Direct navigation to LoginPage widget
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Button background color
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40, // Fixed horizontal padding
                    vertical: 15, // Fixed vertical padding
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Fixed border radius
                  ),
                ),
                child: const Row( // Made const as all its children are now const or literals
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18, // Fixed font size
                        color: Colors.black, // Text color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10), // Fixed gap
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black, // Icon color
                      size: 18, // Fixed icon size
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}