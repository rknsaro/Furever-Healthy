import 'package:flutter/material.dart';
import 'package:fureverhealthy/my_pets/all_pets.dart'; 

const _mint = Color(0xFF6F994A);

class AddReminderModalContent extends StatelessWidget {
  final VoidCallback onClose; 

  const AddReminderModalContent({super.key, required this.onClose});

  Widget _buildReminderOption({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    // The InkWell is now safely inside the main content widget
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Image.asset(imagePath, width: 24, height: 24, color: Colors.white),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: Remove fixed width constraint here.
    return Center( // Center the modal content within the Stack/Overlay area
      child: Padding( // Add horizontal padding directly to the modal content
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding to match the container's inner padding
        child: Container(
          // Allow the container to take the full width minus the parent Padding
          // Set to double.infinity to be as wide as possible
          width: double.infinity, 
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _mint, 
            borderRadius: BorderRadius.circular(16), 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 'Add' Header
              const Text(
                'Add',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Reminder Options
              _buildReminderOption(
                title: 'Recent Notes',
                imagePath: 'assets/notes_white.png',
                onTap: onClose, // Use the provided onClose callback
              ),
              _buildReminderOption(
                title: 'Grooming',
                imagePath: 'assets/grooming_white.png',
                onTap: onClose, 
              ),
              _buildReminderOption(
                title: 'Feeding',
                imagePath: 'assets/feeding_white.png',
                onTap: onClose, 
              ),
              _buildReminderOption(
                title: 'Ongoing Medications',
                imagePath: 'assets/medicine_white.png',
                onTap: onClose, 
              ),
              _buildReminderOption(
                title: 'Vaccines',
                imagePath: 'assets/vaccine_white.png',
                onTap: onClose, 
              ),
              const SizedBox(height: 10),
              // 'Close' button
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: onClose,
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== REMINDERS TAB (STATEFUL) ======================
class RemindersTab extends StatefulWidget {
  final String iconPath;
  final String message;
  final String buttonText;

  const RemindersTab({
    super.key,
    required this.iconPath,
    required this.message,
    required this.buttonText,
  });

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  bool _isModalVisible = false;

  void _showModal() {
    setState(() {
      _isModalVisible = true;
    });
  }

  void _hideModal() {
    setState(() {
      _isModalVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Base Content: Empty State Widget
        EmptyStateWidget(
          iconPath: widget.iconPath,
          message: widget.message,
          buttonText: widget.buttonText,
          onPressed: _showModal, // Calls the local state change function
        ),

        // 2. Modal Overlay (Conditional Rendering)
        if (_isModalVisible)
          // Tapping this translucent container hides the modal
          GestureDetector(
            onTap: _hideModal, // Hide modal when tapping the barrier
            child: SizedBox(
              // color: Colors.black54.withOpacity(0.5), 
              width: double.infinity,
              height: double.infinity,
              // The AddReminderModalContent now has its own padding, 
              // so it will stretch wide within this full-sized container.
              child: AddReminderModalContent(onClose: _hideModal),
            ),
          ),
      ],
    );
  }
}