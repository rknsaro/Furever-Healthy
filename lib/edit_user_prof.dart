import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

const _mint = Color(0xFF6F994A);
const _bg = Color(0xFFF9F9F9);

// Philippines Phone Number Formatter
class PhilippinesPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow deletion
    if (text.isEmpty) {
      return newValue;
    }

    // Extract only digits
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // Must start with 63 (country code)
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '+63',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    // If it doesn't start with 63, add it
    String phoneDigits = digitsOnly;
    if (!phoneDigits.startsWith('63')) {
      phoneDigits = '63$phoneDigits';
    }

    // Extract the 10-digit mobile number (after 63)
    String mobileNumber = '';
    if (phoneDigits.length > 2) {
      mobileNumber = phoneDigits.substring(2);
    }

    // Limit to 10 digits for Philippines mobile number
    if (mobileNumber.length > 10) {
      return oldValue;
    }

    // Format: +63 XXX XXX XXXX
    String formatted = '+63';
    if (mobileNumber.isNotEmpty) {
      if (mobileNumber.length <= 3) {
        formatted += ' $mobileNumber';
      } else if (mobileNumber.length <= 6) {
        formatted +=
            ' ${mobileNumber.substring(0, 3)} ${mobileNumber.substring(3)}';
      } else {
        formatted +=
            ' ${mobileNumber.substring(0, 3)} ${mobileNumber.substring(3, 6)} ${mobileNumber.substring(6)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditUserProfPage extends StatefulWidget {
  const EditUserProfPage({super.key});

  @override
  State<EditUserProfPage> createState() => _EditUserProfPageState();
}

class _EditUserProfPageState extends State<EditUserProfPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedPhoto;
  Uint8List? _pickedBytes;
  String? _currentProfileImageUrl;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _originalPasswordMask = '**********';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          String phoneNumber = data['phoneNumber'] ?? '';
          // Ensure phone number starts with +63 if it's a valid number
          if (phoneNumber.isNotEmpty && !phoneNumber.startsWith('+63')) {
            // If it's just digits, add +63 prefix
            if (RegExp(r'^\d+$').hasMatch(phoneNumber)) {
              phoneNumber = '+63$phoneNumber';
            } else if (phoneNumber.startsWith('63') &&
                phoneNumber.length >= 10) {
              phoneNumber = '+${phoneNumber}';
            }
          }
          setState(() {
            _nameController.text = data['name'] ?? '';
            _usernameController.text = data['username'] ?? '';
            _phoneController.text = phoneNumber;
            _emailController.text = data['email'] ?? user.email ?? '';
            _passwordController.text = _originalPasswordMask; // Masked password
            _currentProfileImageUrl = data['profileImageUrl'] as String?;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedPhoto = file;
          _pickedBytes = bytes;
        });
      } else {
        setState(() => _pickedPhoto = file);
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      String? imageUrl;

      if (_pickedPhoto != null || _pickedBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        if (kIsWeb && _pickedBytes != null) {
          final uploadTask = storageRef.putData(
            _pickedBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          // Wait for upload to complete
          final snapshot = await uploadTask;

          // Get download URL after successful upload
          imageUrl = await snapshot.ref.getDownloadURL();
          print('Image uploaded successfully: $imageUrl');
        } else if (!kIsWeb && _pickedPhoto != null) {
          final uploadTask = storageRef.putFile(File(_pickedPhoto!.path));

          // Wait for upload to complete
          final snapshot = await uploadTask;

          // Get download URL after successful upload
          imageUrl = await snapshot.ref.getDownloadURL();
          print('Image uploaded successfully: $imageUrl');
        }
      }

      return imageUrl ?? _currentProfileImageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      // Re-throw to handle in _saveChanges
      rethrow;
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload profile image if changed
      String? profileImageUrl;
      try {
        profileImageUrl = await _uploadProfileImage();
      } catch (e) {
        print('Profile image upload error: $e');
        // Continue with other updates even if image upload fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image upload failed: $e. Continuing with other updates...',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Update Firestore
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      // Update password if changed (not masked)
      if (_passwordController.text != _originalPasswordMask &&
          _passwordController.text.isNotEmpty &&
          _passwordController.text.length >= 6) {
        try {
          await user.updatePassword(_passwordController.text.trim());
          print('Password updated successfully');
        } catch (e) {
          print('Password update error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Password update failed: $e'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // Update email if changed (requires re-authentication, so we'll skip it for now)
      // Firebase requires re-authentication before changing email
      // We'll still update it in Firestore but not in Firebase Auth
      // if (_emailController.text.trim() != user.email) {
      //   try {
      //     await user.updateEmail(_emailController.text.trim());
      //   } catch (e) {
      //     print('Email update error: $e');
      //     // Email update requires re-authentication
      //   }
      // }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);
      print('Firestore updated successfully');

      // Update display name
      try {
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();
        print('Display name updated successfully');
      } catch (e) {
        print('Display name update error: $e');
        // Continue even if display name update fails
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: _mint,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            margin: EdgeInsets.all(20),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error in _saveChanges: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    bool showToggle = false,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText && _obscurePassword,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _mint, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  )
                : Icon(icon, color: Colors.grey[600], size: 20),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header with green background
            Container(
              width: double.infinity,
              color: _mint,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Picture
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _mint, width: 3),
                          image: _pickedPhoto != null || _pickedBytes != null
                              ? DecorationImage(
                                  image: kIsWeb && _pickedBytes != null
                                      ? MemoryImage(_pickedBytes!)
                                      : FileImage(File(_pickedPhoto!.path))
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : _currentProfileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_currentProfileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: AssetImage('assets/user_prof.png'),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Fields
                    _buildTextField(
                      label: 'Name',
                      controller: _nameController,
                      icon: Icons.edit_outlined,
                    ),
                    _buildTextField(
                      label: 'Username',
                      controller: _usernameController,
                      icon: Icons.edit_outlined,
                    ),
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.edit_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhilippinesPhoneFormatter()],
                    ),
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.edit_outlined,
                    ),
                    _buildTextField(
                      label: 'Password',
                      controller: _passwordController,
                      icon: Icons.edit_outlined,
                      obscureText: true,
                      showToggle: true,
                    ),

                    const SizedBox(height: 24),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mint,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
