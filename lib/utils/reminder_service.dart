import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fureverhealthy/services/notification_service.dart';

/// Creates a reminder and notification when a note, feeding, grooming, or medication is added
Future<void> createReminderAndNotification({
  required String type, // 'note', 'feeding', 'grooming', 'medication'
  required String title,
  required String description,
  required String? petId,
  required String? petName,
  required DateTime? reminderDateTime,
  String? itemId, // The ID of the item (note, feeding, grooming, medication)
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // Create reminder
    final reminderData = <String, dynamic>{
      'userId': user.uid,
      'type': type,
      'title': title,
      'description': description,
      'petId': petId,
      'petName': petName ?? '',
      'itemId': itemId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (reminderDateTime != null) {
      reminderData['reminderDateTime'] = Timestamp.fromDate(reminderDateTime);
    } else {
      reminderData['reminderDateTime'] = FieldValue.serverTimestamp();
    }

    final reminderRef = await FirebaseFirestore.instance
        .collection('reminders')
        .add(reminderData);

    // Create notification in Firestore
    final notificationData = <String, dynamic>{
      'userId': user.uid,
      'type': type,
      'title': title,
      'message': description,
      'petName': petName ?? '',
      'itemId': itemId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);

    // Schedule local notification if reminderDateTime is provided
    if (reminderDateTime != null && reminderDateTime.isAfter(DateTime.now())) {
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Generate a unique ID for the notification (using reminder document ID hash)
      final notificationId = reminderRef.id.hashCode.abs() % 2147483647;

      // Build notification body
      String notificationBody = description;
      if (petName != null && petName.isNotEmpty) {
        notificationBody = 'For $petName: $description';
      }

      // Schedule the notification 15 minutes before the reminder time
      final notificationTime = reminderDateTime.subtract(
        const Duration(minutes: 15),
      );

      // Only schedule if notification time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        await notificationService.scheduleReminderNotification(
          id: notificationId,
          title: title,
          body: notificationBody,
          scheduledDate: notificationTime,
          payload: reminderRef.id, // Store reminder ID in payload
        );
      }

      // Also schedule a notification at the exact reminder time
      final exactNotificationId =
          (reminderRef.id.hashCode.abs() + 1) % 2147483647;
      await notificationService.scheduleReminderNotification(
        id: exactNotificationId,
        title: title,
        body: notificationBody,
        scheduledDate: reminderDateTime,
        payload: reminderRef.id,
      );
    }
  } catch (e) {
    // Silently fail - we don't want to break the main flow if reminder creation fails
    debugPrint('Error creating reminder/notification: $e');
  }
}

/// Deletes a reminder from Firestore and cancels scheduled notifications
Future<bool> deleteReminder(String reminderId) async {
  try {
    // Get the reminder document to check if it exists
    final reminderDoc = await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminderId)
        .get();

    if (!reminderDoc.exists) {
      debugPrint('Reminder not found: $reminderId');
      return false;
    }

    // Cancel scheduled local notifications
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Calculate the notification IDs (same logic as in createReminderAndNotification)
    final notificationId = reminderId.hashCode.abs() % 2147483647;
    final exactNotificationId = (reminderId.hashCode.abs() + 1) % 2147483647;

    // Cancel both notifications (15-min before and exact time)
    await notificationService.cancelNotification(notificationId);
    await notificationService.cancelNotification(exactNotificationId);

    // Delete the reminder from Firestore
    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminderId)
        .delete();

    debugPrint('Reminder deleted successfully: $reminderId');
    return true;
  } catch (e) {
    debugPrint('Error deleting reminder: $e');
    return false;
  }
}
