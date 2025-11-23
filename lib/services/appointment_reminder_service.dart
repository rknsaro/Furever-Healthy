import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fureverhealthy/services/notification_service.dart';

class AppointmentReminderService {
  static final AppointmentReminderService _instance =
      AppointmentReminderService._internal();
  factory AppointmentReminderService() => _instance;
  AppointmentReminderService._internal();

  final NotificationService _notificationService = NotificationService();
  bool _isListening = false;
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;

  /// Start listening for appointments and schedule reminders
  Future<void> startListening() async {
    if (_isListening) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _notificationService.initialize();

    // Listen to user's appointments
    _appointmentsSubscription = FirebaseFirestore.instance
        .collection('user_appointments')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots()
        .listen(
          (snapshot) async {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                await _scheduleAppointmentReminders(change.doc);
              } else if (change.type == DocumentChangeType.removed) {
                await _cancelAppointmentReminders(change.doc.id);
              }
            }
          },
          onError: (error) {
            debugPrint('Error in appointment reminder listener: $error');
          },
        );

    // Also schedule reminders for existing appointments
    try {
      final existingAppointments = await FirebaseFirestore.instance
          .collection('user_appointments')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      for (final doc in existingAppointments.docs) {
        await _scheduleAppointmentReminders(doc);
      }
    } catch (e) {
      debugPrint('Error fetching existing appointments: $e');
    }

    _isListening = true;
    debugPrint('Appointment reminder service started');
  }

  /// Stop listening for appointments
  void stopListening() {
    _appointmentsSubscription?.cancel();
    _appointmentsSubscription = null;
    _isListening = false;
    debugPrint('Appointment reminder service stopped');
  }

  /// Schedule reminders for an appointment (1 day before, 1 hour before)
  Future<void> _scheduleAppointmentReminders(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final appointmentDateTime = data['appointmentDateTime'] as Timestamp?;

      if (appointmentDateTime == null) return;

      final appointmentDate = appointmentDateTime.toDate();
      if (appointmentDate.isBefore(DateTime.now())) return; // Past appointment

      final vetName = (data['vetName'] as String?) ?? 'Vet';
      final petName = (data['petName'] as String?) ?? 'your pet';
      final appointmentId = doc.id;

      // Schedule 1 day before reminder
      final oneDayBefore = appointmentDate.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(DateTime.now())) {
        final notificationId = appointmentId.hashCode.abs() % 2147483647;
        await _notificationService.scheduleReminderNotification(
          id: notificationId,
          title: 'Appointment Reminder',
          body:
              'You have an appointment with Dr. $vetName for $petName tomorrow at ${_formatTime(appointmentDate)}.',
          scheduledDate: oneDayBefore,
          payload: appointmentId,
        );
        debugPrint('Scheduled 1-day reminder for appointment $appointmentId');
      }

      // Schedule 1 hour before reminder
      final oneHourBefore = appointmentDate.subtract(const Duration(hours: 1));
      if (oneHourBefore.isAfter(DateTime.now())) {
        final notificationId =
            (appointmentId.hashCode.abs() + 1000) % 2147483647;
        await _notificationService.scheduleReminderNotification(
          id: notificationId,
          title: 'Appointment Soon',
          body:
              'Your appointment with Dr. $vetName for $petName is in 1 hour at ${_formatTime(appointmentDate)}.',
          scheduledDate: oneHourBefore,
          payload: appointmentId,
        );
        debugPrint('Scheduled 1-hour reminder for appointment $appointmentId');
      }
    } catch (e) {
      debugPrint('Error scheduling appointment reminders: $e');
    }
  }

  /// Cancel reminders for a cancelled/deleted appointment
  Future<void> _cancelAppointmentReminders(String appointmentId) async {
    try {
      final notificationId1 = appointmentId.hashCode.abs() % 2147483647;
      final notificationId2 =
          (appointmentId.hashCode.abs() + 1000) % 2147483647;

      await _notificationService.cancelNotification(notificationId1);
      await _notificationService.cancelNotification(notificationId2);
      debugPrint('Cancelled reminders for appointment $appointmentId');
    } catch (e) {
      debugPrint('Error cancelling appointment reminders: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
