// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup_page.dart';
import '../home_page.dart'; // Adjust if home_page is in a different folder

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ Save user data to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    await usersRef.doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'lastLogin': DateTime.now(),
    }, SetOptions(merge: true));
  }

  // ✅ Email/Password Login
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _saveUserToFirestore(userCredential.user!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login Successful!'),
            backgroundColor: const Color(0xFF6F994A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        });
      } on FirebaseAuthException catch (e) {
        String message = 'Invalid credentials. Please try again.';
        if (e.code == 'user-not-found') {
          message = 'No user found with this email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password.';
        }
        _showError(message);
      }
    }
  }

  // ✅ Google Login
  Future<void> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential.user!);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      print("Google login error: $e");
      _showError("Google sign-in failed. Please try again.");
    }
  }

  // ✅ Facebook Login (with better error handling)
  Future<void> _signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();

      print("Facebook login status: ${result.status}");
      print("Facebook login message: ${result.message}");

      if (result.status == LoginStatus.success) {
        final credential =
            FacebookAuthProvider.credential(result.accessToken!.token);

        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        await _saveUserToFirestore(userCredential.user!);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else if (result.status == LoginStatus.cancelled) {
        _showError("Facebook login was cancelled.");
      } else {
        _showError("Facebook login failed: ${result.message}");
      }
    } catch (e) {
      print("Facebook login error: $e");
      _showError("An error occurred during Facebook login. Please try again.");
    }
  }

  // ✅ Twitter Login
  Future<void> _signInWithTwitter() async {
    try {
      final twitterLogin = TwitterLogin(
        apiKey: "YOUR_TWITTER_API_KEY",
        apiSecretKey: "YOUR_TWITTER_API_SECRET",
        redirectURI: "YOUR_TWITTER_REDIRECT_URI",
      );

      final authResult = await twitterLogin.login();

      switch (authResult.status) {
        case TwitterLoginStatus.loggedIn:
          final credential = TwitterAuthProvider.credential(
            accessToken: authResult.authToken!,
            secret: authResult.authTokenSecret!,
          );

          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          await _saveUserToFirestore(userCredential.user!);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          break;

        case TwitterLoginStatus.cancelledByUser:
          _showError("Twitter login was cancelled.");
          break;

        case TwitterLoginStatus.error:
          _showError("Twitter login failed: ${authResult.errorMessage}");
          break;

        default:
          _showError("Unknown error with Twitter login.");
      }
    } catch (e) {
      print("Twitter login error: $e");
      _showError("An error occurred during Twitter login. Please try again.");
    }
  }

  // ✅ Error UI
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6F994A), Color(0xFF112F15)],
            stops: [0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/furever.png', width: 120),
                  const SizedBox(height: 10),
                  const Text(
                    'Log In',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text(
                    'Hey there! Welcome back',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email
                          const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Enter your email',
                              filled: true,
                              fillColor: Color(0xFFF0F0F0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Color(0xFF112F15), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password
                          const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              filled: true,
                              fillColor: const Color(0xFFF0F0F0),
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Color(0xFF112F15), width: 2),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 8) return 'Password must be at least 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Remember me + Forgot password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() => _rememberMe = value ?? false);
                                      },
                                      activeColor: const Color(0xFF112F15),
                                      checkColor: Colors.white,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Remember me', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Forgot password
                                },
                                child: const Text('Forgot Password?', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Login button
                          SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF112F15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                elevation: 0,
                              ),
                              onPressed: _handleLogin,
                              child: const Text(
                                'Log In',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // OR divider
                          Row(
                            children: [
                              const Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'Or sign up with',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ),
                              const Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Social logins
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: _signInWithFacebook,
                                child: Image.asset('assets/facebook.png', width: 40, height: 40),
                              ),
                              GestureDetector(
                                onTap: _signInWithGoogle,
                                child: Image.asset('assets/google.png', width: 40, height: 40),
                              ),
                              GestureDetector(
                                onTap: _signInWithTwitter,
                                child: Image.asset('assets/twitter.png', width: 40, height: 40),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Signup link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an Account? "),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignupPage()),
                                  );
                                },
                                child: const Text(
                                  'Sign up.',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF112F15)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
