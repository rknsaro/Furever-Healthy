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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _careAdviceSubscription;
  final Set<String> _markedReadKeys = {};
  bool _isInitialAppointmentsLoad = true;
  bool _isInitialCareAdviceLoad = true;

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
      _startCareAdviceSync(user.uid); // This is async but we don't need to await
    }
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _careAdviceSubscription?.cancel();
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
        // Skip initial load - only process real-time changes
        if (_isInitialAppointmentsLoad) {
          _isInitialAppointmentsLoad = false;
          debugPrint('Appointments sync: Skipping initial load, only processing real-time changes');
          return;
        }

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

          // Only process modifications that represent actual status changes
          // Skip added documents on subsequent syncs (they were already processed or are old)
          if (change.type != DocumentChangeType.modified) {
            continue;
          }

          final data = doc.data();
          if (data == null) continue;

          final status =
              (data['status'] as String?)?.toLowerCase().trim() ?? 'pending';

          // Check existing notification to see if status changed
          // This prevents notifications when appointments are updated for other reasons (like care advice edits)
          final existingNotification = await notificationsRef.doc(appointmentId).get();
          if (existingNotification.exists) {
            final existingStatus = (existingNotification.data()?['status'] as String?)
                ?.toLowerCase().trim();
            
            // Status hasn't changed - this is just an update to other fields (like care advice edits)
            if (existingStatus == status) {
              debugPrint('Appointment $appointmentId: Status unchanged ($status), skipping notification (likely non-status field update)');
              continue;
            }
          }

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

            // Double check - only create/update notification if status actually changed
            if (!isStatusChanged) {
              debugPrint('Appointment $appointmentId: Status unchanged ($status), skipping notification');
              return;
            }

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
              'isRead': false,
              'updatedAt': FieldValue.serverTimestamp(),
            };
            
            // Preserve existing createdAt if notification already exists, otherwise set new one
            if (existingSnap.exists && existingSnap.data()?['createdAt'] != null) {
              payload['createdAt'] = existingSnap.data()?['createdAt'];
            } else {
              payload['createdAt'] = FieldValue.serverTimestamp();
            }

            txn.set(notificationRef, payload, SetOptions(merge: true));
            debugPrint('Appointment notification updated: $appointmentId - Status changed from $previousStatus to $status');
          });
        }
      },
      onError: (error) {
        debugPrint('Error syncing notifications: $error');
      },
    );
  }

  void _startCareAdviceSync(String userId) async {
    try {
      // First, get user's pets to match care advice by breed
      final petsSnapshot = await FirebaseFirestore.instance
          .collection('petInfos')
          .where('userId', isEqualTo: userId)
          .get();

      final userPetBreeds = petsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return (data['breed'] as String?)?.toLowerCase().trim();
          })
          .whereType<String>()
          .where((breed) => breed.isNotEmpty)
          .toSet();

      debugPrint('Care advice sync: Found ${userPetBreeds.length} pet breeds: $userPetBreeds');

      if (userPetBreeds.isEmpty) {
        debugPrint('Care advice sync: No pets found, skipping');
        return;
      }

      // Get user's appointments to check vet relationships
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('user_appointments')
          .where('userId', isEqualTo: userId)
          .get();

      final userVetIds = appointmentsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return data['vetId'] as String?;
          })
          .whereType<String>()
          .toSet();

      debugPrint('Care advice sync: Found ${userVetIds.length} vet IDs from appointments: $userVetIds');

      // Don't process existing care advice on initial load - only listen for real-time updates
      // This ensures notifications only appear when care advice is actually edited/added

      // Listen to careAdvice collection for new/updated documents only
      _careAdviceSubscription = FirebaseFirestore.instance
          .collection('careAdvice')
          .snapshots()
          .listen(
        (snapshot) async {
          // Skip initial load - only process real-time changes
          if (_isInitialCareAdviceLoad) {
            _isInitialCareAdviceLoad = false;
            debugPrint('Care advice sync: Skipping initial load, only processing real-time changes');
            return;
          }

          debugPrint('Care advice listener: Received snapshot with ${snapshot.docChanges.length} real-time changes');
          for (final change in snapshot.docChanges) {
            // Only process new additions and modifications (real-time updates)
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              final doc = change.doc;
              final data = doc.data();
              if (data != null) {
                debugPrint('Care advice listener: Processing real-time update for document ${doc.id} (type: ${change.type})');
                await _processCareAdviceDocument(
                  doc.id,
                  data,
                  userId,
                  userPetBreeds,
                  userVetIds,
                  petsSnapshot.docs,
                );
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Error in care advice listener: $error');
        },
      );
      debugPrint('Care advice listener: Started listening to careAdvice collection');

    } catch (e) {
      debugPrint('Error starting care advice sync: $e');
    }
  }


  Future<void> _processCareAdviceDocument(
    String careAdviceId,
    Map<String, dynamic> adviceData,
    String userId,
    Set<String> userPetBreeds,
    Set<String> userVetIds,
    List<QueryDocumentSnapshot> petsSnapshot,
  ) async {
    try {
      // Get vetId from care advice document
      final vetId = (adviceData['vetId'] as String?)?.trim();
      if (vetId == null || vetId.isEmpty) {
        debugPrint('Care advice $careAdviceId: No vetId field found');
        return;
      }

      // Check if user has appointments with this vet
      if (!userVetIds.contains(vetId)) {
        debugPrint('Care advice $careAdviceId: User has no appointments with vet $vetId');
        return;
      }

      // Get vet name
      String vetName = 'Vet';
      try {
        final vetDoc = await FirebaseFirestore.instance
            .collection('vets')
            .doc(vetId)
            .get();
        if (vetDoc.exists) {
          final vetData = vetDoc.data();
          vetName = (vetData?['name'] as String?)?.trim() ??
                    (vetData?['displayName'] as String?)?.trim() ??
                    (vetData?['vetName'] as String?)?.trim() ??
                    'Vet';
        }
      } catch (e) {
        debugPrint('Care advice $careAdviceId: Error fetching vet name: $e');
      }

      // Match by breed
      final adviceBreed = (adviceData['breed'] as String?)?.toLowerCase().trim();
      if (adviceBreed == null || adviceBreed.isEmpty) {
        debugPrint('Care advice $careAdviceId: No breed field found');
        return;
      }

      debugPrint('Care advice $careAdviceId: Checking breed match - advice breed: "$adviceBreed", user breeds: $userPetBreeds');

      // Check if user has a pet with matching breed (more flexible matching)
      bool breedMatches = false;
      
      for (final userBreed in userPetBreeds) {
        // Normalize both breeds for comparison (remove extra spaces, normalize case)
        final normalizedUserBreed = userBreed.toLowerCase().trim();
        final normalizedAdviceBreed = adviceBreed.toLowerCase().trim();
        
        // Exact match after normalization
        if (normalizedUserBreed == normalizedAdviceBreed) {
          breedMatches = true;
          debugPrint('Care advice $careAdviceId: Exact breed match found: "$userBreed" == "$adviceBreed"');
          break;
        }
        
        // Partial match (one contains the other)
        if (normalizedUserBreed.contains(normalizedAdviceBreed) || 
            normalizedAdviceBreed.contains(normalizedUserBreed)) {
          breedMatches = true;
          debugPrint('Care advice $careAdviceId: Partial breed match found: "$userBreed" contains or is contained in "$adviceBreed"');
          break;
        }
        
        // Try matching without common words
        final userBreedClean = normalizedUserBreed
            .replaceAll(RegExp(r'\b(shorthair|longhair|mix|mixed|domestic)\b', caseSensitive: false), '')
            .trim();
        final adviceBreedClean = normalizedAdviceBreed
            .replaceAll(RegExp(r'\b(shorthair|longhair|mix|mixed|domestic)\b', caseSensitive: false), '')
            .trim();
            
        if (userBreedClean.isNotEmpty && adviceBreedClean.isNotEmpty) {
          if (userBreedClean == adviceBreedClean ||
              userBreedClean.contains(adviceBreedClean) ||
              adviceBreedClean.contains(userBreedClean)) {
            breedMatches = true;
            debugPrint('Care advice $careAdviceId: Cleaned breed match found: "$userBreedClean" matches "$adviceBreedClean"');
            break;
          }
        }
      }

      if (!breedMatches) {
        debugPrint('Care advice $careAdviceId: No breed match - advice breed: "$adviceBreed", user breeds: $userPetBreeds');
        return;
      }

      final notificationsRef = FirebaseFirestore.instance.collection(
        'notifications',
      );

      // Create a unique notification ID for this care advice per user
      // Use careAdvice document ID + userId to ensure uniqueness per user
      final notificationId = 'careAdvice_${careAdviceId}_$userId';

      debugPrint('Care advice $careAdviceId: Attempting to create notification with ID: $notificationId');

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final notificationRef = notificationsRef.doc(notificationId);
        final existingSnap = await txn.get(notificationRef);

        debugPrint('Care advice $careAdviceId: Notification $notificationId exists: ${existingSnap.exists}');

        final title = (adviceData['title'] as String?)?.trim() ?? 'Care Advice';
        final advice = (adviceData['advice'] as String?)?.trim() ?? '';
        
        // Find matching pet name for better message
        String? petName;
        for (final petDoc in petsSnapshot) {
          final petData = petDoc.data() as Map<String, dynamic>;
          final petBreed = (petData['breed'] as String?)?.toLowerCase().trim();
          if (petBreed != null && adviceBreed.isNotEmpty) {
            if (petBreed == adviceBreed ||
                petBreed.contains(adviceBreed) ||
                adviceBreed.contains(petBreed)) {
              petName = petData['name'] as String?;
              break;
            }
          }
        }

        // Check if content actually changed (for modified documents)
        final isNew = !existingSnap.exists;
        final existingTitle = existingSnap.data()?['title'] as String?;
        final existingAdvice = existingSnap.data()?['advice'] as String?;
        final contentChanged = isNew || 
            (existingTitle != title) || 
            (existingAdvice != advice);

        // Only create/update notification if it's new or content changed
        if (contentChanged) {
          final payload = <String, dynamic>{
            'userId': userId,
            'careAdviceId': careAdviceId,
            'vetId': vetId,
            'type': 'careAdvice',
            'title': title,
            'advice': advice,
            'breed': adviceBreed,
            'petName': petName ?? 'your pet',
            'vetName': vetName,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (isNew) {
            payload['createdAt'] = FieldValue.serverTimestamp();
            payload['isRead'] = false;
            debugPrint('Care advice notification created: $notificationId for user $userId - "$title" for breed $adviceBreed');
          } else {
            // For edits, keep existing createdAt but mark as unread
            payload['createdAt'] = existingSnap.data()?['createdAt'] ?? FieldValue.serverTimestamp();
            payload['isRead'] = false;
            debugPrint('Care advice notification updated: $notificationId for user $userId - "$title" (care advice was edited)');
          }

          txn.set(notificationRef, payload);
        } else {
          debugPrint('Care advice notification unchanged: $notificationId (no content changes)');
        }
      });
    } catch (e) {
      debugPrint('Error processing care advice document $careAdviceId: $e');
    }
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
                                data['appointmentId'] as String? ?? 
                                data['careAdviceId'] as String? ?? 
                                docId,
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
      if (appointmentId.isNotEmpty && status != 'careAdvice') {
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
        // Generic notifications (e.g., likes, care advice) - just delete the notification doc
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
    // Handle care advice notifications
    final type = (data['type'] as String?)?.toLowerCase().trim();
    if (type == 'careadvice') {
      final title = (data['title'] as String?)?.trim() ?? 'Care Advice';
      final vetName = (data['vetName'] as String?)?.trim().isNotEmpty == true
          ? data['vetName'] as String
          : 'Vet';
      final petName = (data['petName'] as String?)?.trim().isNotEmpty == true
          ? data['petName'] as String
          : 'your pet';
      final advice = (data['advice'] as String?)?.trim() ?? '';
      final message = advice.isNotEmpty
          ? 'Dr. $vetName has added care advice for $petName: ${advice.length > 100 ? "${advice.substring(0, 100)}..." : advice}'
          : 'Dr. $vetName has added care advice for $petName.';
      String? timestampText;
      if (data['createdAt'] is Timestamp) {
        final created = (data['createdAt'] as Timestamp).toDate();
        timestampText = DateFormat('MMM d, yyyy • h:mm a').format(created);
      }
      return _NotificationContent(
        status: 'careAdvice',
        title: title,
        message: message,
        timestamp: timestampText,
      );
    }

    // Handle community like notifications
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
      case 'careAdvice':
        return Colors.purple;
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
