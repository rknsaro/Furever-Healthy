import 'package:flutter/material.dart';
import 'screens/loading_screen.dart'; // Adjust path if needed
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // this is now used

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ✅ use the generated config
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
      ),
      home: const LoadingScreen(), // Your starting screen
      debugShowCheckedModeBanner: false,
    );
  }
}
