import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fureverhealthy/utils/reminder_service.dart';

const _mint = Color(0xFF6F994A);

// ====================== REMINDERS TAB (STATEFUL) ======================
class RemindersTab extends StatefulWidget {
  final String? selectedPetId;
  final String? selectedPetName;

  const RemindersTab({super.key, this.selectedPetId, this.selectedPetName});

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Please log in to view reminders.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: widget.selectedPetId != null
          ? FirebaseFirestore.instance
                .collection('reminders')
                .where('userId', isEqualTo: user.uid)
                .where('petId', isEqualTo: widget.selectedPetId)
                .snapshots()
          : FirebaseFirestore.instance
                .collection('reminders')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _mint));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading reminders: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          );
        }

        // Sort reminders by reminderDateTime in memory
        final allDocs = snapshot.data?.docs ?? [];
        final sortedDocs = List<QueryDocumentSnapshot>.from(allDocs)
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['reminderDateTime'] as Timestamp?;
            final bTime = bData['reminderDateTime'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1; // nulls go to end
            if (bTime == null) return -1;

            return aTime.compareTo(bTime); // ascending order
          });

        if (sortedDocs.isEmpty) {
          final hasSelection =
              widget.selectedPetId != null && widget.selectedPetId!.isNotEmpty;
          final petName = (widget.selectedPetName?.trim().isNotEmpty ?? false)
              ? widget.selectedPetName!.trim()
              : 'your pet';
          final message = hasSelection
              ? 'No reminders for $petName yet.'
              : 'Select a pet to view reminders.';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/reminders.png',
                  width: 80,
                  height: 80,
                  color: _mint,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sortedDocs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _ReminderCard(
              reminderId: doc.id,
              data: data,
              onDelete: () => _deleteReminder(context, doc.id),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteReminder(BuildContext context, String reminderId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text(
          'Are you sure you want to delete this reminder? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: _mint)),
      );
    }

    // Delete the reminder
    final success = await deleteReminder(reminderId);

    // Close loading indicator
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Show result message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Reminder deleted successfully'
                : 'Failed to delete reminder. Please try again.',
          ),
          backgroundColor: success ? _mint : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final String reminderId;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminderId,
    required this.data,
    required this.onDelete,
  });

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'note':
        return Icons.note;
      case 'feeding':
        return Icons.restaurant;
      case 'grooming':
        return Icons.pets;
      case 'medication':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'note':
        return Colors.blue;
      case 'feeding':
        return Colors.orange;
      case 'grooming':
        return Colors.purple;
      case 'medication':
        return Colors.red;
      default:
        return _mint;
    }
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    final dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] as String?) ?? 'reminder';
    final title = (data['title'] as String?) ?? 'Reminder';
    final description = (data['description'] as String?) ?? '';
    final petName = (data['petName'] as String?) ?? '';
    final reminderDateTime = data['reminderDateTime'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColorForType(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForType(type),
              color: _getColorForType(type),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (petName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'For: $petName',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
                if (reminderDateTime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(reminderDateTime),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Delete reminder',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
