import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/loading_screen.dart'; // Your welcome/loading screen
import '../home_page.dart'; // Adjust path if needed
import 'package:fureverhealthy/services/appointment_reminder_service.dart';
import 'package:fureverhealthy/services/breed_tips_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes and initialize services
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in - start services
        AppointmentReminderService().startListening();
        // Send breed tips when user logs in (will check for recent tips)
        BreedTipsService().schedulePeriodicBreedTips();
      } else {
        // User signed out - stop services
        AppointmentReminderService().stopListening();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show spinner while waiting for auth state
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is signed in
          return const HomePage();
        }

        // User is NOT signed in, show welcome/loading screen
        return const LoadingScreen();
      },
    );
  }
}
