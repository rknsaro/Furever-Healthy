import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fureverhealthy/services/notification_service.dart';

class BreedTipsService {
  static final BreedTipsService _instance = BreedTipsService._internal();
  factory BreedTipsService() => _instance;
  BreedTipsService._internal();

  final NotificationService _notificationService = NotificationService();

  /// Send breed-specific tips to users based on their pets
  Future<void> sendBreedTips({
    String? specificPetId,
    bool forceSend = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _notificationService.initialize();

    try {
      // Get user's pets
      List<DocumentSnapshot> petDocs;
      if (specificPetId != null) {
        // Get specific pet
        final petDoc = await FirebaseFirestore.instance
            .collection('petInfos')
            .doc(specificPetId)
            .get();
        if (!petDoc.exists) {
          debugPrint('Pet document not found: $specificPetId');
          return;
        }
        petDocs = [petDoc];
      } else {
        final petsSnapshot = await FirebaseFirestore.instance
            .collection('petInfos')
            .where('userId', isEqualTo: user.uid)
            .get();
        petDocs = petsSnapshot.docs;
      }

      for (final petDoc in petDocs) {
        final petData = petDoc.data() as Map<String, dynamic>;
        final breed = (petData['breed'] as String?)?.trim();
        final petName = (petData['name'] as String?) ?? 'your pet';

        if (breed == null ||
            breed.isEmpty ||
            breed.toLowerCase() == 'unknown') {
          debugPrint(
            'Skipping breed tips for $petName: breed is null/empty/unknown',
          );
          continue;
        }

        debugPrint('Processing breed tips for $petName: breed = "$breed"');

        // Get breed-specific tips from database or generate them
        final tips = await _getBreedTips(breed.toLowerCase());

        if (tips.isNotEmpty) {
          debugPrint('Found ${tips.length} tips for breed "$breed"');
          await _createBreedTipNotification(
            userId: user.uid,
            petId: petDoc.id,
            petName: petName,
            breed: breed.toLowerCase(),
            tip: tips.first, // Send one tip at a time
            forceSend: forceSend,
          );
        } else {
          debugPrint('No tips found for breed "$breed"');
        }
      }
    } catch (e) {
      debugPrint('Error sending breed tips: $e');
    }
  }

  /// Get breed-specific tips (from database or generate)
  Future<List<String>> _getBreedTips(String breed) async {
    // Try to get tips from Firestore first
    try {
      final tipsDoc = await FirebaseFirestore.instance
          .collection('breedTips')
          .where('breed', isEqualTo: breed)
          .limit(1)
          .get();

      if (tipsDoc.docs.isNotEmpty) {
        final data = tipsDoc.docs.first.data();
        final tips = data['tips'] as List<dynamic>?;
        if (tips != null && tips.isNotEmpty) {
          return tips.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching breed tips from database: $e');
    }

    // Fallback: Return default tips based on breed
    return _getDefaultBreedTips(breed);
  }

  /// Normalize breed name for matching (handles variations)
  String _normalizeBreed(String breed) {
    return breed
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Check if breed matches (handles variations)
  bool _breedMatches(String breed, List<String> patterns) {
    final normalized = _normalizeBreed(breed);
    for (final pattern in patterns) {
      if (normalized.contains(pattern.toLowerCase()) ||
          pattern.toLowerCase().contains(normalized)) {
        return true;
      }
    }
    return false;
  }

  /// Default breed-specific tips
  List<String> _getDefaultBreedTips(String breed) {
    // Dog breed tips
    if (_breedMatches(breed, ['aspin', 'asong pinoy', 'askal'])) {
      return [
        'Aspins are active dogs! Make sure to provide daily exercise of at least 30-60 minutes.',
        'Regular grooming every 4-6 weeks helps keep your Aspin\'s coat healthy and reduces shedding.',
        'Aspins are prone to hip dysplasia. Regular vet checkups and maintaining a healthy weight are important.',
        'Aspins thrive with consistent routines and plenty of affection from their families.',
      ];
    } else if (_breedMatches(breed, ['shih tzu', 'shih-tzu', 'shitzu'])) {
      return [
        'Shih Tzus need daily brushing to prevent matting of their long coat.',
        'Due to their flat face, Shih Tzus can have breathing issues. Avoid overexertion in hot weather.',
        'Regular eye cleaning is essential for Shih Tzus to prevent infections.',
        'Shih Tzus are small but active. Provide daily walks of 15-30 minutes, twice per day.',
      ];
    } else if (_breedMatches(breed, [
      'labrador',
      'lab',
      'labrador retriever',
    ])) {
      return [
        'Labradors are prone to obesity. Monitor their food intake and provide regular exercise.',
        'Labradors need 60-90 minutes of daily exercise to stay healthy and happy.',
        'Regular ear cleaning is important for Labradors, especially after swimming.',
        'Labradors are highly trainable. Use positive reinforcement for best results.',
      ];
    }
    // Cat breed tips
    else if (_breedMatches(breed, [
      'puspin',
      'philippine shorthair',
      'philippine cat',
    ])) {
      return [
        'Puspins are generally healthy! Regular vet checkups and vaccinations are still important.',
        'Provide scratching posts to keep your Puspin\'s claws healthy and protect your furniture.',
        'Puspins adapt well to the Philippines climate. Ensure they have access to fresh water and shade.',
        'Brush your Puspin 1-2 times per week to remove loose hair and reduce shedding.',
      ];
    } else if (_breedMatches(breed, [
      'british shorthair',
      'british shorthair cat',
    ])) {
      return [
        'British Shorthairs are prone to weight gain. Monitor their food portions and provide regular play.',
        'Brush your British Shorthair 2-3 times per week to manage their dense coat.',
        'Watch for signs of Hypertrophic Cardiomyopathy (HCM) - regular heart screening is recommended.',
        'British Shorthairs are calm and gentle. Provide daily play sessions of 15-20 minutes.',
      ];
    } else if (_breedMatches(breed, ['persian', 'persian cat'])) {
      return [
        'Persians require daily grooming to prevent matting of their long coat.',
        'Daily eye cleaning is essential for Persians due to excessive tearing.',
        'Persians are sensitive to heat. Keep them in cool, well-ventilated areas.',
        'Persians are less active. Provide gentle play and avoid overexertion.',
      ];
    }

    // Generic tips for unknown breeds
    return [
      'Regular vet checkups are essential for your pet\'s health.',
      'Provide a balanced diet and fresh water daily.',
      'Regular exercise and mental stimulation keep pets happy and healthy.',
    ];
  }

  /// Create a notification for breed-specific tips
  Future<void> _createBreedTipNotification({
    required String userId,
    required String petId,
    required String petName,
    required String breed,
    required String tip,
    bool forceSend = false,
  }) async {
    try {
      if (!forceSend) {
        // Check if we've already sent this tip recently (within last 7 days)
        final recentTips = await FirebaseFirestore.instance
            .collection('breedTipNotifications')
            .where('userId', isEqualTo: userId)
            .where('petId', isEqualTo: petId)
            .where('breed', isEqualTo: breed)
            .where(
              'createdAt',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
            )
            .get();

        if (recentTips.docs.isNotEmpty) {
          // Already sent a tip recently
          debugPrint('Breed tip already sent recently for $petName ($breed)');
          return;
        }
      }

      // Create notification in Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'type': 'breedTip',
        'title': 'Breed Care Tip for $petName',
        'message': tip,
        'petId': petId,
        'petName': petName,
        'breed': breed,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Track that we sent this tip
      await FirebaseFirestore.instance.collection('breedTipNotifications').add({
        'userId': userId,
        'petId': petId,
        'breed': breed,
        'tip': tip,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Schedule a local notification (send tomorrow to avoid spam)
      final notificationId =
          (petId.hashCode + breed.hashCode).abs() % 2147483647;
      await _notificationService.scheduleReminderNotification(
        id: notificationId,
        title: 'Breed Care Tip for $petName',
        body: tip,
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        payload: petId,
      );

      debugPrint('Breed tip notification created for $petName ($breed)');
    } catch (e) {
      debugPrint('Error creating breed tip notification: $e');
    }
  }

  /// Schedule periodic breed tips (call this daily or weekly)
  Future<void> schedulePeriodicBreedTips() async {
    // This can be called from a background task or when app opens
    await sendBreedTips();
  }

  /// Force send breed tips (bypasses 7-day check - for testing)
  Future<void> forceSendBreedTips() async {
    await sendBreedTips(forceSend: true);
  }
}
