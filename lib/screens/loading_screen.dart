import 'package:flutter/material.dart';
import 'login_page.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6F994A), // Adjusted top color
              Color(0xFF112F15), // Adjusted bottom color
            ],
            stops: [0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer to push the logo up
              const Spacer(flex: 3),

              // Logo
              Image.asset(
                'assets/fhlogo.png', // Assuming you have an image with this filename
                height: 250,
              ),

              // Spacer to push the button down
              const Spacer(flex: 2),

              // Get Started Button
              GestureDetector(
                onTap: () {
                  // Navigate to the LoginPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginPage()),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF112F15),
                        size: 35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer for bottom padding
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}