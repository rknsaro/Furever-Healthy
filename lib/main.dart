import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this line
import 'firebase_options.dart';
import 'auth_wrapper.dart'; // Your wrapper for login logic

// Updated by HFCapistrano - Firebase integration complete

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "assets/.env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Furever Healthy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Mobile-optimized theme settings
        useMaterial3: true,
        // Ensure touch targets meet mobile standards
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      // Mobile-first: prefer portrait orientation
      builder: (context, child) {
        return MediaQuery(
          // Ensure text is readable on mobile devices
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
