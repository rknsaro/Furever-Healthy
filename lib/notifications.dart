import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _mint = Color(0xFF6F994A);
const _screenBg = Color(0xFFF6F8FB);

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: _mint,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: const _NotificationsList(),
    );
  }
}

class _NotificationsList extends StatefulWidget {
  const _NotificationsList();

  @override
  State<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<_NotificationsList> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>>? _notificationStream;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _appointmentsSubscription;
  final Set<String> _markedReadKeys = {};

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _notificationStream = null;
    } else {
      _notificationStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
      _startAppointmentsSync(user.uid);
    }
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationStream == null) {
      return const _EmptyState(
        message: 'Please sign in to view notifications.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _mint));
        }

        if (snapshot.hasError) {
          return _EmptyState(
            message: 'Failed to load notifications. Please try again later.',
            onRetry: () => setState(() {}),
          );
        }

        final docs =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            )..sort((a, b) {
              final aTime =
                  (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });
        if (docs.isEmpty) {
          return const _EmptyState(message: 'No notifications yet.');
        }

        final unreadDocs = docs.where(
          (doc) => (doc.data()['isRead'] as bool? ?? false) == false,
        );
        if (unreadDocs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markAsRead(unreadDocs.toList());
          });
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return _NotificationTile(docId: doc.id, data: data);
          },
        );
      },
    );
  }

  void _startAppointmentsSync(String userId) {
    final appointmentsQuery = FirebaseFirestore.instance
        .collection('user_appointments')
        .where('userId', isEqualTo: userId);

    _appointmentsSubscription = appointmentsQuery.snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          final appointmentId = doc.id;
          final notificationsRef = FirebaseFirestore.instance.collection(
            'notifications',
          );

          if (change.type == DocumentChangeType.removed) {
            try {
              await notificationsRef.doc(appointmentId).delete();
            } catch (_) {}
            continue;
          }

          final data = doc.data();
          if (data == null) continue;

          final status =
              (data['status'] as String?)?.toLowerCase().trim() ?? 'pending';

          final dismissedRaw = data['dismissedNotifications'];
          final dismissedStatuses = dismissedRaw is Iterable
              ? dismissedRaw.map((e) => e.toString().toLowerCase()).toSet()
              : <String>{};

          if (dismissedStatuses.contains(status)) {
            try {
              await notificationsRef.doc(appointmentId).delete();
            } catch (_) {}
            continue;
          }

          await FirebaseFirestore.instance.runTransaction((txn) async {
            final notificationRef = notificationsRef.doc(appointmentId);
            final existingSnap = await txn.get(notificationRef);
            final previousStatus = (existingSnap.data()?['status'] as String?)
                ?.toLowerCase();
            final bool isStatusChanged =
                !existingSnap.exists || previousStatus != status;

            final payload = <String, dynamic>{
              'userId': userId,
              'appointmentId': appointmentId,
              'status': status,
              'vetName': data['vetName'],
              'petName': data['petName'],
              'date': data['date'],
              'timeSlot': data['timeSlot'],
              'appointmentDateTime': data['appointmentDateTime'],
              'meetingLink': data['meetingLink'],
              'updatedAt': FieldValue.serverTimestamp(),
            };

            if (isStatusChanged) {
              payload['createdAt'] = FieldValue.serverTimestamp();
              payload['isRead'] = false;
            } else {
              payload['isRead'] =
                  existingSnap.data()?['isRead'] as bool? ?? false;
            }

            txn.set(notificationRef, payload, SetOptions(merge: true));
          });
        }
      },
      onError: (error) {
        debugPrint('Error syncing notifications: $error');
      },
    );
  }

  Future<void> _markAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (!mounted || docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    var hasUpdates = false;

    for (final doc in docs) {
      final key = doc.id;
      if (_markedReadKeys.contains(key)) continue;
      _markedReadKeys.add(key);
      batch.update(doc.reference, {'isRead': true});
      hasUpdates = true;
    }

    if (hasUpdates) {
      try {
        await batch.commit();
      } catch (e) {
        debugPrint('Failed to mark notifications as read: $e');
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _NotificationTile({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(data);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _colorForStatus(content.status),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            content.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        PopupMenuButton<_NotificationAction>(
                          icon: const Icon(Icons.more_horiz, size: 20),
                          onSelected: (value) {
                            if (value == _NotificationAction.delete) {
                              _deleteNotification(
                                context,
                                docId,
                                content.status,
                                data['appointmentId'] as String? ?? docId,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: _NotificationAction.delete,
                              child: Text('Delete notification'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    if (content.timestamp != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        content.timestamp!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNotification(
    BuildContext context,
    String docId,
    String status,
    String appointmentId,
  ) async {
    try {
      final notificationsRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId);
      // For appointment-based notifications, also mark dismissed in appointment
      if (appointmentId.isNotEmpty) {
        final appointmentRef = FirebaseFirestore.instance
            .collection('user_appointments')
            .doc(appointmentId);
        await FirebaseFirestore.instance.runTransaction((txn) async {
          final appointmentSnap = await txn.get(appointmentRef);
          if (appointmentSnap.exists) {
            final data = appointmentSnap.data()!;
            final dismissedRaw = data['dismissedNotifications'];
            final dismissedStatuses = dismissedRaw is Iterable
                ? dismissedRaw.map((e) => e.toString().toLowerCase()).toSet()
                : <String>{};

            if (!dismissedStatuses.contains(status)) {
              dismissedStatuses.add(status);
              txn.update(appointmentRef, {
                'dismissedNotifications': dismissedStatuses.toList(),
              });
            }
          }
          txn.delete(notificationsRef);
        });
      } else {
        // Generic notifications (e.g., likes) - just delete the notification doc
        await notificationsRef.delete();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification removed'),
            backgroundColor: _mint,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  _NotificationContent _buildContent(Map<String, dynamic> data) {
    // Handle community like notifications
    final type = (data['type'] as String?)?.toLowerCase().trim();
    if (type == 'like') {
      final actorName =
          (data['actorName'] as String?)?.trim().isNotEmpty == true
          ? data['actorName'] as String
          : 'Someone';
      final message = (data['message'] as String?)?.trim().isNotEmpty == true
          ? data['message'] as String
          : '$actorName liked your post';
      String? timestampText;
      if (data['createdAt'] is Timestamp) {
        final created = (data['createdAt'] as Timestamp).toDate();
        timestampText = DateFormat('MMM d, yyyy • h:mm a').format(created);
      }
      return _NotificationContent(
        status: 'like',
        title: 'New like',
        message: message,
        timestamp: timestampText,
      );
    }

    final status =
        (data['status'] as String?)?.toLowerCase().trim() ?? 'pending';
    final vetName = (data['vetName'] as String?)?.trim().isNotEmpty == true
        ? data['vetName'] as String
        : 'Vet';
    final petName = (data['petName'] as String?)?.trim().isNotEmpty == true
        ? data['petName'] as String
        : 'your pet';

    DateTime? dateTime;
    if (data['appointmentDateTime'] is Timestamp) {
      dateTime = (data['appointmentDateTime'] as Timestamp).toDate();
    } else if (data['appointmentDateTime'] is DateTime) {
      dateTime = data['appointmentDateTime'] as DateTime;
    } else if (data['date'] is Timestamp) {
      dateTime = (data['date'] as Timestamp).toDate();
      final timeSlot = data['timeSlot'] as String?;
      if (timeSlot != null) {
        dateTime = _combineDateWithTimeSlot(dateTime, timeSlot);
      }
    }

    String formattedDate = 'a future date';
    String formattedTime = 'a future time';
    if (dateTime != null) {
      formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
      formattedTime = DateFormat('h:mm a').format(dateTime);
    } else if (data['date'] is String && data['timeSlot'] is String) {
      formattedDate = data['date'] as String;
      formattedTime = data['timeSlot'] as String;
    } else if (data['timeSlot'] is String) {
      formattedTime = data['timeSlot'] as String;
    }

    final template = _statusTemplates[status] ?? _statusTemplates['pending']!;
    final message = template.message
        .replaceAll('{vetName}', vetName)
        .replaceAll('{petName}', petName)
        .replaceAll('{date}', formattedDate)
        .replaceAll('{time}', formattedTime);

    String? timestampText;
    if (data['createdAt'] is Timestamp) {
      final created = (data['createdAt'] as Timestamp).toDate();
      timestampText = DateFormat('MMM d, yyyy • h:mm a').format(created);
    }

    return _NotificationContent(
      status: status,
      title: template.title,
      message: message,
      timestamp: timestampText,
    );
  }

  DateTime _combineDateWithTimeSlot(DateTime date, String timeSlot) {
    try {
      final startSegment = timeSlot.split('-').first.trim();
      final timeFormat = DateFormat('h:mm a');
      final combined = timeFormat.parse(startSegment);
      return DateTime(
        date.year,
        date.month,
        date.day,
        combined.hour,
        combined.minute,
      );
    } catch (_) {
      return date;
    }
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'declined':
        return Colors.redAccent;
      case 'cancelled':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return _mint;
    }
  }
}

class _NotificationContent {
  final String status;
  final String title;
  final String message;
  final String? timestamp;

  const _NotificationContent({
    required this.status,
    required this.title,
    required this.message,
    required this.timestamp,
  });
}

class _NotificationTemplate {
  final String title;
  final String message;

  const _NotificationTemplate({required this.title, required this.message});
}

const Map<String, _NotificationTemplate> _statusTemplates = {
  'pending': _NotificationTemplate(
    title: 'Appointment Pending Confirmation',
    message:
        'Your appointment request with Dr. {vetName} for {petName} on {date} at {time} is pending. Please wait while the vet reviews your request.',
  ),
  'declined': _NotificationTemplate(
    title: 'Appointment Declined',
    message:
        'Your appointment with Dr. {vetName} for {petName} on {date} at {time} was declined. You may try booking another schedule or contact the vet for more details.',
  ),
  'cancelled': _NotificationTemplate(
    title: 'Appointment Cancelled',
    message:
        'Your appointment with Dr. {vetName} for {petName} on {date} at {time} has been cancelled. If this was a mistake, you can reschedule anytime.',
  ),
  'confirmed': _NotificationTemplate(
    title: 'Appointment Confirmed',
    message:
        'Great news! Dr. {vetName} has confirmed your appointment for {petName} on {date} at {time}. Please arrive on time and bring any necessary pet records.',
  ),
  'completed': _NotificationTemplate(
    title: 'Appointment Completed',
    message:
        'Your appointment with Dr. {vetName} for {petName} on {date} at {time} has been completed. Thank you for trusting our veterinary service! Don’t forget to leave feedback or schedule your next visit.',
  ),
};

enum _NotificationAction { delete }

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _EmptyState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: _mint),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: _mint, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
