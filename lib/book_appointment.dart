import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fureverhealthy/utils/vet_services_parser.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);
const _screenBg = Color(0xFFF6F8FB);

class BookAppointmentPage extends StatefulWidget {
  final String vetId;
  final String vetName;
  final String vetSpecialty;
  final int vetRating;
  final String vetStatus;
  final String? profileImageUrl;

  const BookAppointmentPage({
    super.key,
    required this.vetId,
    required this.vetName,
    required this.vetSpecialty,
    required this.vetRating,
    required this.vetStatus,
    this.profileImageUrl,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  String? _selectedPetId;
  String? _selectedPetName;
  String? selectedReason;
  int? estimatedCost;
  String? selectedTime;
  DateTime selectedDate = DateTime.now();

  final List<Map<String, String>> _userPets = [];
  bool _isLoadingPets = false;
  String? _petLoadError;

  List<Map<String, dynamic>> reasons = [];
  bool _isLoadingReasons = false;

  List<String> morningTimes = _defaultMorningSlots();
  List<String> afternoonTimes = _defaultAfternoonSlots();
  Map<String, dynamic>? vetSchedule;
  Map<String, dynamic>? vetAvailability;
  bool _isLoadingSchedule = false;
  List<String> workingDays = _defaultWorkingDays();
  Set<String> bookedTimeSlots = {};
  
  // Store all available dates and time slots from Firebase
  Map<String, List<String>> availableDatesAndSlots = {}; // date -> list of available time slots
  Set<String> allAvailableDates = {}; // Set of all dates that have at least one available slot

  // Default time slots (matching Firebase format: HH:MM)
  static List<String> _defaultMorningSlots() {
    return [
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
    ];
  }

  static List<String> _defaultAfternoonSlots() {
    return [
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
    ];
  }

  // Format time slot for display (convert 24-hour to 12-hour format with range)
  // Format: "08:00" -> "8:00 - 9:00 AM"
  static String _formatTimeSlotForDisplay(String timeSlot) {
    try {
      // Parse the time slot (format: "08:00" or "HH:MM")
      final parts = timeSlot.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        
        // Calculate end time (1 hour later)
        final endHour = (hour + 1) % 24;
        
        // Format start time
        String startTime;
        String startPeriod;
        if (hour == 0) {
          startTime = '12:$minute';
          startPeriod = 'AM';
        } else if (hour < 12) {
          startTime = '$hour:$minute';
          startPeriod = 'AM';
        } else if (hour == 12) {
          startTime = '12:$minute';
          startPeriod = 'PM';
        } else {
          startTime = '${hour - 12}:$minute';
          startPeriod = 'PM';
        }
        
        // Format end time
        String endTime;
        String endPeriod;
        if (endHour == 0) {
          endTime = '12:$minute';
          endPeriod = 'AM';
        } else if (endHour < 12) {
          endTime = '$endHour:$minute';
          endPeriod = 'AM';
        } else if (endHour == 12) {
          endTime = '12:$minute';
          endPeriod = 'NN'; // Use "NN" for noon instead of "PM"
        } else {
          endTime = '${endHour - 12}:$minute';
          endPeriod = 'PM';
        }
        
        // Special case: 11:00 - 12:00 PM should display as "11:00 - 12:00 NN"
        if (hour == 11 && endHour == 12) {
          return '$startTime - $endTime NN';
        }
        
        // If both times are in the same period, only show period once
        if (startPeriod == endPeriod) {
          // If end period is NN, use NN instead
          if (endPeriod == 'NN') {
            return '$startTime - $endTime NN';
          }
          return '$startTime - $endTime $startPeriod';
        } else {
          // Crosses AM/PM boundary (e.g., 11:00 AM - 12:00 PM)
          // If end is NN, format without AM on start
          if (endPeriod == 'NN') {
            return '$startTime - $endTime NN';
          }
          return '$startTime $startPeriod - $endTime $endPeriod';
        }
      }
    } catch (e) {
      // If parsing fails, return original
    }
    return timeSlot;
  }

  static List<String> _defaultWorkingDays() {
    return [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadUserPets();
    _loadReasonsFromDatabase();
    _loadVetSchedule();
  }

  Future<void> _loadVetSchedule() async {
    setState(() {
      _isLoadingSchedule = true;
    });

    try {
      final schedule = await _fetchVetSchedule(widget.vetId);
      var availability = await _fetchVetAvailability(widget.vetId);
      
      // If availability is null but schedule has availability fields, merge them
      if (availability == null && schedule != null) {
        availability = <String, dynamic>{'vetId': widget.vetId};
        final availabilityFields = [
          'blockedDates',
          'unavailableDates',
          'unavailableTimeSlots',
          'blockedTimeSlots',
          'disabledSlots',
          'disabledTimeSlots',
          'disabledMorningSlots',
          'disabledAfternoonSlots',
          'morningAvailable',
          'morningsAvailable',
          'morningsDisabled',
          'afternoonAvailable',
          'afternoonsDisabled',
        ];
        for (var field in availabilityFields) {
          if (schedule.containsKey(field)) {
            availability[field] = schedule[field];
          }
        }
        if (availability.length == 1) {
          availability = null; // Only has vetId, so it's empty
        }
      }
      
      // Extract all available dates and time slots from Firebase
      final extractedData = _extractAvailableDatesAndSlots(availability);
      
      setState(() {
        vetSchedule = schedule;
        vetAvailability = availability;
        availableDatesAndSlots = extractedData['datesAndSlots'] as Map<String, List<String>>;
        allAvailableDates = extractedData['dates'] as Set<String>;
        
        // Get time slots from schedule, or use all available slots from Firebase
        final allAvailableSlots = _getAllAvailableTimeSlots(availability);
        if (allAvailableSlots.isNotEmpty) {
          // Split into morning and afternoon based on hour
          final morning = <String>[];
          final afternoon = <String>[];
          
          for (var slot in allAvailableSlots) {
            final hour = _getHourFromTimeSlot(slot);
            if (hour >= 8 && hour < 12) {
              morning.add(slot);
            } else if (hour >= 12 && hour <= 18) {
              afternoon.add(slot);
            }
          }
          
          morningTimes = morning.isNotEmpty ? morning : _getMorningSlots(schedule);
          afternoonTimes = afternoon.isNotEmpty ? afternoon : _getAfternoonSlots(schedule);
        } else {
          morningTimes = _getMorningSlots(schedule);
          afternoonTimes = _getAfternoonSlots(schedule);
        }
        
        workingDays = _getWorkingDays(schedule);
        _isLoadingSchedule = false;
      });

      // Debug: Log availability data
      debugPrint('=== VET AVAILABILITY DATA ===');
      debugPrint('Schedule: $schedule');
      if (schedule != null) {
        debugPrint('Schedule keys: ${schedule.keys.toList()}');
        if (schedule.containsKey('disabledSlots')) {
          debugPrint('Schedule.disabledSlots: ${schedule['disabledSlots']}');
        }
        if (schedule.containsKey('disabledMorningSlots')) {
          debugPrint('Schedule.disabledMorningSlots: ${schedule['disabledMorningSlots']}');
        }
        if (schedule.containsKey('disabledAfternoonSlots')) {
          debugPrint('Schedule.disabledAfternoonSlots: ${schedule['disabledAfternoonSlots']}');
        }
        if (schedule.containsKey('morningAvailable')) {
          debugPrint('Schedule.morningAvailable: ${schedule['morningAvailable']}');
        }
        if (schedule.containsKey('morningsDisabled')) {
          debugPrint('Schedule.morningsDisabled: ${schedule['morningsDisabled']}');
        }
      }
      debugPrint('Availability: $availability');
      if (availability != null) {
        debugPrint('Availability keys: ${availability.keys.toList()}');
        if (availability.containsKey('disabledSlots')) {
          debugPrint('Availability.disabledSlots: ${availability['disabledSlots']}');
        }
        if (availability.containsKey('unavailableTimeSlots')) {
          debugPrint('Availability.unavailableTimeSlots: ${availability['unavailableTimeSlots']}');
        }
      }
      debugPrint('Available Dates: ${allAvailableDates.length} dates');
      debugPrint('Morning Times: $morningTimes');
      debugPrint('Afternoon Times: $afternoonTimes');
      debugPrint('Working Days: $workingDays');
      debugPrint('Mornings Available: ${_areMorningsAvailable()}');
      debugPrint('Afternoons Available: ${_areAfternoonsAvailable()}');

      _loadBookedTimeSlots();
    } catch (e) {
      debugPrint('Error loading vet schedule: $e');
      setState(() {
        morningTimes = _defaultMorningSlots();
        afternoonTimes = _defaultAfternoonSlots();
        workingDays = _defaultWorkingDays();
        _isLoadingSchedule = false;
      });
    }
  }

  // Fetch vet schedule from Firebase
  // Note: vet_schedules collection has documents with format {vetId}_{date}
  // Each document has: date, timeSlots (map), vetId, createdAt, updatedAt
  // Fetches ALL available schedule documents for the vet
  Future<Map<String, dynamic>?> _fetchVetSchedule(String vetId) async {
    try {
      debugPrint('=== FETCHING ALL VET SCHEDULES FROM vet_schedules ===');
      debugPrint('Fetching schedules for vet: $vetId');
      
      // Query ALL schedule documents for this vet from vet_schedules collection
      // Fetch in batches to ensure we get all documents (Firestore default limit is usually sufficient)
      const int batchSize = 100; // Firestore default is usually 20-50, but we'll use 100 for efficiency
      List<QueryDocumentSnapshot> allDocs = [];
      QueryDocumentSnapshot? lastDoc;
      
      // Fetch all documents in batches
      while (true) {
        Query query = FirebaseFirestore.instance
            .collection('vet_schedules')
            .where('vetId', isEqualTo: vetId)
            .limit(batchSize);
        
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        
        final querySnapshot = await query.get();
        final batchDocs = querySnapshot.docs;
        
        if (batchDocs.isEmpty) {
          break; // No more documents
        }
        
        allDocs.addAll(batchDocs);
        
        // If we got fewer documents than the batch size, we've reached the end
        if (batchDocs.length < batchSize) {
          break;
        }
        
        // Prepare for next batch
        lastDoc = batchDocs.last;
      }

      debugPrint('Total documents fetched: ${allDocs.length}');
      
      if (allDocs.isNotEmpty) {
        debugPrint('Found ${allDocs.length} schedule documents in vet_schedules for vet $vetId');
        
        // Aggregate all schedule data
        final scheduleData = <String, dynamic>{
          'vetId': vetId,
        };
        
        // Process each document (each represents one date)
        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] as String?;
          
          if (date != null && data.containsKey('timeSlots')) {
            // Store timeSlots for this date
            scheduleData[date] = data['timeSlots'];
            final timeSlotsMap = data['timeSlots'] as Map;
            debugPrint('  Found schedule for date $date with ${timeSlotsMap.length} time slots');
            
            // Log all time slots for this date
            timeSlotsMap.forEach((timeKey, timeValue) {
              debugPrint('    Time slot: "$timeKey" = $timeValue');
            });
          } else {
            debugPrint('  Skipping document ${doc.id}: missing date or timeSlots');
          }
        }
        
        debugPrint('Total dates in schedule: ${scheduleData.length - 1}'); // -1 for vetId
        if (scheduleData.length > 1) {
          return scheduleData;
        }
      }

      // No fallback - only use vet_schedules collection
      debugPrint('No schedule documents found in vet_schedules for vet $vetId');
      return null;
    } catch (e) {
      debugPrint('Error fetching vet schedule: $e');
      return null;
    }
  }

  // Fetch vet availability from Firebase
  // Note: vet_schedules collection has documents with format {vetId}_{date}
  // Each document has: date, timeSlots (map with boolean values), vetId
  // Fetches ALL available appointment dates and time slots for the vet
  Future<Map<String, dynamic>?> _fetchVetAvailability(String vetId) async {
    try {
      debugPrint('=== FETCHING ALL VET AVAILABILITY FROM vet_schedules ===');
      debugPrint('Fetching availability for vet: $vetId');
      
      // Query ALL schedule documents for this vet from vet_schedules collection
      // Fetch in batches to ensure we get all documents
      const int batchSize = 100; // Firestore default is usually 20-50, but we'll use 100 for efficiency
      List<QueryDocumentSnapshot> allDocs = [];
      QueryDocumentSnapshot? lastDoc;
      
      // Fetch all documents in batches
      while (true) {
        Query query = FirebaseFirestore.instance
            .collection('vet_schedules')
            .where('vetId', isEqualTo: vetId)
            .limit(batchSize);
        
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        
        final querySnapshot = await query.get();
        final batchDocs = querySnapshot.docs;
        
        if (batchDocs.isEmpty) {
          break; // No more documents
        }
        
        allDocs.addAll(batchDocs);
        
        // If we got fewer documents than the batch size, we've reached the end
        if (batchDocs.length < batchSize) {
          break;
        }
        
        // Prepare for next batch
        lastDoc = batchDocs.last;
      }

      debugPrint('Total documents fetched: ${allDocs.length}');
      
      if (allDocs.isNotEmpty) {
        debugPrint('Found ${allDocs.length} availability documents for vet $vetId');
        
        // Aggregate all availability data
        final availabilityData = <String, dynamic>{
          'vetId': vetId,
        };
        
        int totalAvailableSlots = 0;
        int totalUnavailableSlots = 0;
        
        // Process each document (each represents one date)
        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] as String?;
          
          if (date != null && data.containsKey('timeSlots')) {
            final timeSlots = data['timeSlots'] as Map;
            debugPrint('  Processing date $date with ${timeSlots.length} time slots');
            
            // Count available and unavailable slots
            int availableCount = 0;
            int unavailableCount = 0;
            
            // Store the timeSlots map for this date (includes both true and false values)
            timeSlots.forEach((timeKey, timeValue) {
              if (timeValue is bool) {
                if (timeValue) {
                  availableCount++;
                  debugPrint('    ✓ Available: $timeKey');
                } else {
                  unavailableCount++;
                  debugPrint('    ✗ Unavailable: $timeKey');
                }
              }
            });
            
            totalAvailableSlots += availableCount;
            totalUnavailableSlots += unavailableCount;
            
            // Store the timeSlots map for this date
            availabilityData[date] = timeSlots;
            debugPrint('    Date $date: $availableCount available, $unavailableCount unavailable');
          } else {
            debugPrint('  Skipping document ${doc.id}: missing date or timeSlots');
          }
        }
        
        debugPrint('=== AVAILABILITY SUMMARY ===');
        debugPrint('Total dates: ${availabilityData.length - 1}'); // -1 for vetId
        debugPrint('Total available slots: $totalAvailableSlots');
        debugPrint('Total unavailable slots: $totalUnavailableSlots');
        debugPrint('Final availability data has ${availabilityData.length} fields');
        
        if (availabilityData.length > 1) {
          return availabilityData;
        }
      }

      // No fallback - only use vet_schedules collection
      debugPrint('No availability documents found in vet_schedules for vet $vetId');
      return null;
    } catch (e) {
      debugPrint('Error fetching vet availability: $e');
      return null;
    }
  }

// Get morning slots from schedule
  List<String> _getMorningSlots(Map<String, dynamic>? schedule) {
    if (schedule == null) {
      return _defaultMorningSlots();
    }

    if (schedule.containsKey('morningSlots') && schedule['morningSlots'] is List) {
      final slots = schedule['morningSlots'] as List;
      return slots.map((slot) => slot.toString()).toList();
    }

    if (schedule.containsKey('morning') && schedule['morning'] is List) {
      final slots = schedule['morning'] as List;
      return slots.map((slot) => slot.toString()).toList();
    }

    if (schedule.containsKey('timeSlots') && schedule['timeSlots'] is List) {
      final allSlots = schedule['timeSlots'] as List;
      return allSlots
          .where((slot) {
            final slotStr = slot.toString();
            // Check if it's in 24-hour format (08:00 to 11:59) or old format with AM/8-11
            if (RegExp(r'^\d{2}:\d{2}$').hasMatch(slotStr)) {
              final hour = int.tryParse(slotStr.substring(0, 2));
              return hour != null && hour >= 8 && hour < 12;
            }
            // Fallback for old format
            return slotStr.contains('AM') || 
                   slotStr.contains('8:') ||
                   slotStr.contains('9:') ||
                   slotStr.contains('10:') ||
                   slotStr.contains('11:');
          })
          .map((slot) => slot.toString())
          .toList();
    }

    return _defaultMorningSlots();
  }

  // Get afternoon slots from schedule
  List<String> _getAfternoonSlots(Map<String, dynamic>? schedule) {
    if (schedule == null) {
      return _defaultAfternoonSlots();
    }

    if (schedule.containsKey('afternoonSlots') && schedule['afternoonSlots'] is List) {
      final slots = schedule['afternoonSlots'] as List;
      return slots.map((slot) => slot.toString()).toList();
    }

    if (schedule.containsKey('afternoon') && schedule['afternoon'] is List) {
      final slots = schedule['afternoon'] as List;
      return slots.map((slot) => slot.toString()).toList();
    }

    if (schedule.containsKey('timeSlots') && schedule['timeSlots'] is List) {
      final allSlots = schedule['timeSlots'] as List;
      return allSlots
          .where((slot) {
            final slotStr = slot.toString();
            // Check if it's in 24-hour format (12:00 to 18:59) or old format with PM/1-5
            if (RegExp(r'^\d{2}:\d{2}$').hasMatch(slotStr)) {
              final hour = int.tryParse(slotStr.substring(0, 2));
              return hour != null && hour >= 12 && hour <= 18;
            }
            // Fallback for old format
            return slotStr.contains('PM') || 
                   slotStr.contains('1:') ||
                   slotStr.contains('2:') ||
                   slotStr.contains('3:') ||
                   slotStr.contains('4:') ||
                   slotStr.contains('5:');
          })
          .map((slot) => slot.toString())
          .toList();
    }

    return _defaultAfternoonSlots();
  }

  // Extract all available dates and time slots from Firebase availability
  Map<String, dynamic> _extractAvailableDatesAndSlots(Map<String, dynamic>? availability) {
    final datesAndSlots = <String, List<String>>{};
    final dates = <String>{};
    
    if (availability == null) {
      return {'datesAndSlots': datesAndSlots, 'dates': dates};
    }
    
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    // Iterate through all fields in availability
    availability.forEach((key, value) {
      // Check if it's a date field (YYYY-MM-DD format)
      if (datePattern.hasMatch(key) && value is Map) {
        final dateSlots = value;
        final availableSlots = <String>[];
        
        // Extract all time slots that are set to true (available)
        // Note: In vet_schedules, time slots are stored as strings like "1:00 - 2:00 PM"
        debugPrint('  Processing ${dateSlots.length} time slots for date $key');
        dateSlots.forEach((timeKey, timeValue) {
          final timeStr = timeKey.toString();
          debugPrint('    Checking slot: "$timeStr" = $timeValue (type: ${timeValue.runtimeType})');
          
          if (timeValue is bool && timeValue) {
            // Time slot is available
            debugPrint('      ✓ Available slot found: $timeStr');
            // Extract the start time from the range format (e.g., "1:00 - 2:00 PM" -> "1:00 PM" -> "13:00")
            final normalizedTime = _normalizeTimeSlotFromRange(timeStr);
            if (normalizedTime != null) {
              debugPrint('        Normalized to: $normalizedTime');
              if (!availableSlots.contains(normalizedTime)) {
                availableSlots.add(normalizedTime);
                debugPrint('        Added to available slots list');
              } else {
                debugPrint('        Already in list, skipping duplicate');
              }
            } else {
              debugPrint('        WARNING: Failed to normalize time slot: $timeStr');
              // Try to add the original if normalization fails (might be in correct format already)
              if (RegExp(r'^\d{2}:\d{2}$').hasMatch(timeStr)) {
                debugPrint('        Adding original format as it appears to be correct: $timeStr');
                if (!availableSlots.contains(timeStr)) {
                  availableSlots.add(timeStr);
                }
              }
            }
          } else {
            debugPrint('      ✗ Slot not available: $timeStr = $timeValue');
          }
        });
        
        if (availableSlots.isNotEmpty) {
          datesAndSlots[key] = availableSlots;
          dates.add(key);
        }
      }
    });
    
    debugPrint('Extracted ${dates.length} dates with available slots');
    for (var date in dates) {
      final slots = datesAndSlots[date] ?? [];
      debugPrint('  $date: ${slots.length} slots -> $slots');
    }
    
    return {'datesAndSlots': datesAndSlots, 'dates': dates};
  }
  
  // Get all unique time slots that are available across all dates
  List<String> _getAllAvailableTimeSlots(Map<String, dynamic>? availability) {
    final allSlots = <String>{};
    
    if (availability == null) {
      return [];
    }
    
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    // Iterate through all date fields
    availability.forEach((key, value) {
      if (datePattern.hasMatch(key) && value is Map) {
        final dateSlots = value;
        
        // Extract all time slots that are set to true (available)
        dateSlots.forEach((timeKey, timeValue) {
          if (timeValue is bool && timeValue) {
            final timeStr = timeKey.toString();
            final normalizedTime = _normalizeTimeSlotFromRange(timeStr);
            if (normalizedTime != null) {
              allSlots.add(normalizedTime);
            }
          }
        });
      }
    });
    
    // Sort slots by time
    final sortedSlots = allSlots.toList()..sort((a, b) {
      final hourA = _getHourFromTimeSlot(a);
      final minuteA = _getMinuteFromTimeSlot(a);
      final hourB = _getHourFromTimeSlot(b);
      final minuteB = _getMinuteFromTimeSlot(b);
      
      if (hourA != hourB) {
        return hourA.compareTo(hourB);
      }
      return minuteA.compareTo(minuteB);
    });
    
    return sortedSlots;
  }
  
  // Normalize time slot from range format to HH:MM format
  // Handles formats like: "10:00 - 11:00 AM" -> "10:00" (extracts start time and converts to 24-hour)
  // Also handles ranges that cross AM/PM boundary like "11:00 - 12:00 PM" -> "11:00" (11:00 AM)
  String? _normalizeTimeSlotFromRange(String timeStr) {
    // Trim whitespace
    final trimmed = timeStr.trim();
    
    // If already in HH:MM format, return it
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(trimmed)) {
      return trimmed;
    }
    
    // Extract start time from range format "10:00 - 11:00 AM" or "1:00 - 2:00 PM"
    // Also handle ranges that cross AM/PM boundary like "11:00 - 12:00 PM"
    // Pattern: start time, dash, end time, optional AM/PM
    final rangeMatch = RegExp(r'^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).firstMatch(trimmed);
    if (rangeMatch != null) {
      final startHour = int.tryParse(rangeMatch.group(1) ?? '');
      final startMinute = rangeMatch.group(2) ?? '00';
      final endHour = int.tryParse(rangeMatch.group(3) ?? '');
      final period = rangeMatch.group(5)?.toUpperCase();
      
      if (startHour != null && endHour != null) {
        var hour24 = startHour;
        
        // Handle AM/PM conversion
        if (period == 'PM') {
          // Check if the range crosses AM/PM boundary
          // Only "11:00 - 12:00 PM" crosses the boundary (11 AM to 12 PM)
          // All other PM ranges are entirely in PM (e.g., "1:00 - 2:00 PM" is 1 PM to 2 PM)
          if (startHour == 11 && endHour == 12) {
            // Special case: "11:00 - 12:00 PM" means 11:00 AM to 12:00 PM
            // Start time is AM
            hour24 = 11; // 11:00 AM stays as 11:00
          } else {
            // All other PM ranges: both start and end are PM
            // Convert to 24-hour format
            if (startHour != 12) {
              hour24 = startHour + 12; // 1 PM = 13:00, 2 PM = 14:00, etc.
            } else {
              hour24 = 12; // 12:00 PM = 12:00
            }
          }
        } else if (period == 'AM') {
          // Both times are AM
          if (startHour == 12) {
            hour24 = 0; // 12:00 AM = midnight
          } else {
            hour24 = startHour; // 1-11 AM stay as 1-11
          }
        } else {
          // No AM/PM specified, assume 24-hour format or same period
          // If start hour is 1-11 and end hour is 12, likely AM
          if (startHour < 12 && endHour == 12) {
            hour24 = startHour; // Likely AM
          } else if (startHour >= 12) {
            hour24 = startHour; // Already in 24-hour format
          } else {
            hour24 = startHour; // Default to as-is
          }
        }
        
        return '${hour24.toString().padLeft(2, '0')}:$startMinute';
      }
    }
    
    // Try single time format "10:00 AM" or "10:00 PM"
    final singleTimeMatch = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).firstMatch(trimmed);
    if (singleTimeMatch != null) {
      final hour = int.tryParse(singleTimeMatch.group(1) ?? '');
      final minute = singleTimeMatch.group(2) ?? '00';
      final period = singleTimeMatch.group(3)?.toUpperCase();
      
      if (hour != null) {
        var hour24 = hour;
        // Convert to 24-hour format if PM
        if (period == 'PM' && hour != 12) {
          hour24 = hour + 12;
        } else if (period == 'AM' && hour == 12) {
          hour24 = 0;
        }
        return '${hour24.toString().padLeft(2, '0')}:$minute';
      }
    }
    
    // Try simple HH:MM or H:MM format
    final simpleMatch = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(trimmed);
    if (simpleMatch != null) {
      final hour = int.tryParse(simpleMatch.group(1) ?? '');
      final minute = simpleMatch.group(2) ?? '00';
      if (hour != null) {
        return '${hour.toString().padLeft(2, '0')}:$minute';
      }
    }
    
    debugPrint('_normalizeTimeSlotFromRange: Failed to parse "$timeStr"');
    return null;
  }

  // Get hour from time slot (format: "08:00")
  int _getHourFromTimeSlot(String timeSlot) {
    final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(timeSlot);
    if (timeMatch != null) {
      return int.tryParse(timeMatch.group(1) ?? '') ?? 0;
    }
    return 0;
  }
  
  // Get minute from time slot (format: "08:00")
  int _getMinuteFromTimeSlot(String timeSlot) {
    final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(timeSlot);
    if (timeMatch != null) {
      return int.tryParse(timeMatch.group(2) ?? '') ?? 0;
    }
    return 0;
  }

  // Get working days from schedule
  List<String> _getWorkingDays(Map<String, dynamic>? schedule) {
    if (schedule == null) {
      return _defaultWorkingDays();
    }

    if (schedule.containsKey('workingDays') && schedule['workingDays'] is List) {
      final days = schedule['workingDays'] as List;
      return days.map((day) => day.toString()).toList();
    }

    if (schedule.containsKey('days') && schedule['days'] is List) {
      final days = schedule['days'] as List;
      return days.map((day) => day.toString()).toList();
    }

    return _defaultWorkingDays();
  }

  // Get existing appointments for a date range
  Future<List<Map<String, dynamic>>> _getExistingAppointments(
    String vetId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final appointments = await FirebaseFirestore.instance
          .collection('user_appointments')
          .where('vetId', isEqualTo: vetId)
          .where('appointmentDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return appointments.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching existing appointments: $e');
      return [];
    }
  }

  Future<void> _loadBookedTimeSlots() async {
    try {
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      
      final appointments = await _getExistingAppointments(
        widget.vetId,
        startOfDay,
        endOfDay,
      );

      setState(() {
        bookedTimeSlots = appointments
            .map((apt) => apt['timeSlot'] as String? ?? '')
            .where((slot) => slot.isNotEmpty)
            .toSet();
      });
    } catch (e) {
      debugPrint('Error loading booked time slots: $e');
    }
  }

  // Get blocked dates from availability
  List<DateTime> _getBlockedDates() {
    if (vetAvailability == null) {
      return [];
    }

    final blockedDates = <DateTime>[];

    if (vetAvailability!.containsKey('blockedDates') && 
        vetAvailability!['blockedDates'] is List) {
      final dates = vetAvailability!['blockedDates'] as List;
      for (var date in dates) {
        if (date is Timestamp) {
          blockedDates.add(date.toDate());
        } else if (date is String) {
          try {
            blockedDates.add(DateTime.parse(date));
          } catch (e) {
            debugPrint('Error parsing blocked date: $date');
          }
        }
      }
    }

    if (vetAvailability!.containsKey('unavailableDates') && 
        vetAvailability!['unavailableDates'] is List) {
      final dates = vetAvailability!['unavailableDates'] as List;
      for (var date in dates) {
        if (date is Timestamp) {
          blockedDates.add(date.toDate());
        } else if (date is String) {
          try {
            blockedDates.add(DateTime.parse(date));
          } catch (e) {
            debugPrint('Error parsing unavailable date: $date');
          }
        }
      }
    }

    return blockedDates;
  }

  // Get unavailable time slots from availability
  // Firebase structure: date fields (like "2025-11-22") contain maps of time slots with boolean values
  Map<String, List<String>> _getUnavailableTimeSlots() {
    if (vetAvailability == null) {
      return {};
    }

    final unavailableSlots = <String, List<String>>{};

    // Check for date fields (format: YYYY-MM-DD)
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    vetAvailability!.forEach((key, value) {
      // If this is a date field
      if (datePattern.hasMatch(key) && value is Map) {
        final timeSlots = <String>[];
        final dateSlots = value;
        
        // Iterate through time slots for this date
        dateSlots.forEach((timeKey, timeValue) {
          // If the value is false, the slot is unavailable
          if (timeValue is bool && !timeValue) {
            timeSlots.add(timeKey.toString());
          }
        });
        
        if (timeSlots.isNotEmpty) {
          unavailableSlots[key] = timeSlots;
        }
      }
    });

    // Also check legacy format: unavailableTimeSlots
    if (vetAvailability!.containsKey('unavailableTimeSlots') && 
        vetAvailability!['unavailableTimeSlots'] is Map) {
      final slots = vetAvailability!['unavailableTimeSlots'] as Map;
      slots.forEach((date, times) {
        if (times is List) {
          unavailableSlots[date.toString()] = 
              times.map((time) => time.toString()).toList();
        }
      });
    }

    // Also check legacy format: blockedTimeSlots
    if (vetAvailability!.containsKey('blockedTimeSlots') && 
        vetAvailability!['blockedTimeSlots'] is Map) {
      final slots = vetAvailability!['blockedTimeSlots'] as Map;
      slots.forEach((date, times) {
        if (times is List) {
          final dateStr = date.toString();
          if (unavailableSlots.containsKey(dateStr)) {
            unavailableSlots[dateStr]!.addAll(
                times.map((time) => time.toString()).toList());
          } else {
            unavailableSlots[dateStr] = 
                times.map((time) => time.toString()).toList();
          }
        }
      });
    }

    return unavailableSlots;
  }

  // Check if a date is selectable (for calendar)
  // Only show dates that have available time slots set by the vet in Firebase
  bool _isDateSelectable(DateTime date) {
    // Don't allow past dates
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (dateOnly.isBefore(todayOnly)) {
      return false;
    }
    
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // PRIMARY CHECK: Only show dates that have available slots in Firebase
    // If we have available dates from Firebase, ONLY allow those dates
    if (allAvailableDates.isNotEmpty) {
      if (!allAvailableDates.contains(dateStr)) {
        debugPrint('Date $dateStr not selectable: not in Firebase available dates');
        return false;
      }
      
      // Also verify that this date has at least one available slot
      if (availableDatesAndSlots.containsKey(dateStr)) {
        final slots = availableDatesAndSlots[dateStr]!;
        if (slots.isEmpty) {
          debugPrint('Date $dateStr not selectable: no available slots');
          return false;
        }
      } else {
        debugPrint('Date $dateStr not selectable: no slots found in availableDatesAndSlots');
        return false;
      }
    } else {
      // If no Firebase dates loaded yet, fall back to working days check
      // This handles the case when data is still loading
      if (workingDays.isNotEmpty) {
        final dayName = DateFormat('EEEE').format(date);
        if (!workingDays.contains(dayName)) {
          return false;
        }
      }
    }
    
    // Check for blocked dates (additional safety check)
    if (vetAvailability != null) {
      final blockedDates = _getBlockedDates();
      
      for (var blockedDate in blockedDates) {
        final blockedDateOnly = DateTime(blockedDate.year, blockedDate.month, blockedDate.day);
        if (dateOnly.isAtSameMomentAs(blockedDateOnly)) {
          debugPrint('Date $dateStr not selectable: blocked in Firebase');
          return false;
        }
      }
    }

    return true;
  }


  // Check if mornings are completely unavailable
  bool _areMorningsAvailable() {
    // Check availability document
    if (vetAvailability != null) {
      // Check various field names for morning availability
      final morningFields = [
        'morningAvailable',
        'morningsAvailable',
        'morning',
        'mornings',
        'morningEnabled',
        'morningsEnabled',
      ];
      
      for (var field in morningFields) {
        if (vetAvailability!.containsKey(field)) {
          final value = vetAvailability![field];
          if (value is bool && !value) {
            debugPrint('Mornings disabled via availability.$field = false');
            return false;
          }
          if (value is String && value.toLowerCase() == 'false') {
            debugPrint('Mornings disabled via availability.$field = "false"');
            return false;
          }
        }
      }

      // Check for disabled flags
      if (vetAvailability!.containsKey('morningsDisabled')) {
        final morningsDisabled = vetAvailability!['morningsDisabled'];
        if (morningsDisabled is bool && morningsDisabled) {
          debugPrint('Mornings disabled via availability.morningsDisabled = true');
          return false;
        }
        if (morningsDisabled is String && morningsDisabled.toLowerCase() == 'true') {
          debugPrint('Mornings disabled via availability.morningsDisabled = "true"');
          return false;
        }
      }
    }

    // Check schedule document
    if (vetSchedule != null) {
      // Check various field names for morning availability
      final morningFields = [
        'morningAvailable',
        'morningsAvailable',
        'morning',
        'mornings',
        'morningEnabled',
        'morningsEnabled',
      ];
      
      for (var field in morningFields) {
        if (vetSchedule!.containsKey(field)) {
          final value = vetSchedule![field];
          if (value is bool && !value) {
            debugPrint('Mornings disabled via schedule.$field = false');
            return false;
          }
          if (value is String && value.toLowerCase() == 'false') {
            debugPrint('Mornings disabled via schedule.$field = "false"');
            return false;
          }
        }
      }

      if (vetSchedule!.containsKey('morningsDisabled')) {
        final morningsDisabled = vetSchedule!['morningsDisabled'];
        if (morningsDisabled is bool && morningsDisabled) {
          debugPrint('Mornings disabled via schedule.morningsDisabled = true');
          return false;
        }
        if (morningsDisabled is String && morningsDisabled.toLowerCase() == 'true') {
          debugPrint('Mornings disabled via schedule.morningsDisabled = "true"');
          return false;
        }
      }
      
      // Check if availableMorningSlots is empty (means no mornings available)
      if (vetSchedule!.containsKey('availableMorningSlots') && 
          vetSchedule!['availableMorningSlots'] is List) {
        final availableMorning = vetSchedule!['availableMorningSlots'] as List;
        if (availableMorning.isEmpty) {
          debugPrint('Mornings disabled: availableMorningSlots is empty');
          return false;
        }
      }
      
      // Check if morningSlots is empty
      if (vetSchedule!.containsKey('morningSlots') && 
          vetSchedule!['morningSlots'] is List) {
        final morningSlots = vetSchedule!['morningSlots'] as List;
        if (morningSlots.isEmpty) {
          debugPrint('Mornings disabled: morningSlots is empty');
          return false;
        }
      }
      
      // Check if morning field exists and is false/empty
      if (vetSchedule!.containsKey('morning')) {
        final morning = vetSchedule!['morning'];
        if (morning is bool && !morning) {
          debugPrint('Mornings disabled: schedule.morning = false');
          return false;
        }
        if (morning is List && morning.isEmpty) {
          debugPrint('Mornings disabled: schedule.morning is empty list');
          return false;
        }
      }
      
      // Check if all morning slots are in disabledMorningSlots
      if (vetSchedule!.containsKey('disabledMorningSlots') && 
          vetSchedule!['disabledMorningSlots'] is List) {
        final disabledMorning = vetSchedule!['disabledMorningSlots'] as List;
        final disabledSlotsStr = disabledMorning.map((s) => s.toString()).toList();
        // Check if all default morning slots are disabled
        final allDefaultMorningDisabled = morningTimes.every((slot) => 
          disabledSlotsStr.contains(slot));
        if (allDefaultMorningDisabled && morningTimes.isNotEmpty) {
          debugPrint('Mornings disabled: All morning slots are in disabledMorningSlots');
          return false;
        }
      }
      
      // Check if all morning slots are in disabledSlots
      if (vetSchedule!.containsKey('disabledSlots') && 
          vetSchedule!['disabledSlots'] is List) {
        final disabledSlots = vetSchedule!['disabledSlots'] as List;
        final disabledSlotsStr = disabledSlots.map((s) => s.toString()).toList();
        // Check if all default morning slots are disabled
        final allDefaultMorningDisabled = morningTimes.every((slot) => 
          disabledSlotsStr.contains(slot));
        if (allDefaultMorningDisabled && morningTimes.isNotEmpty) {
          debugPrint('Mornings disabled: All morning slots are in disabledSlots');
          return false;
        }
      }
    }

    return true;
  }

  // Check if afternoons are completely unavailable
  bool _areAfternoonsAvailable() {
    // Check availability document
    if (vetAvailability != null) {
      if (vetAvailability!.containsKey('afternoonAvailable')) {
        final afternoonAvailable = vetAvailability!['afternoonAvailable'];
        if (afternoonAvailable is bool && !afternoonAvailable) {
          return false;
        }
        if (afternoonAvailable is String && afternoonAvailable.toLowerCase() == 'false') {
          return false;
        }
      }
    }

    // Check schedule document
    if (vetSchedule != null) {
      if (vetSchedule!.containsKey('afternoonAvailable')) {
        final afternoonAvailable = vetSchedule!['afternoonAvailable'];
        if (afternoonAvailable is bool && !afternoonAvailable) {
          return false;
        }
        if (afternoonAvailable is String && afternoonAvailable.toLowerCase() == 'false') {
          return false;
        }
      }
      if (vetSchedule!.containsKey('afternoonsDisabled')) {
        final afternoonsDisabled = vetSchedule!['afternoonsDisabled'];
        if (afternoonsDisabled is bool && afternoonsDisabled) {
          return false;
        }
        if (afternoonsDisabled is String && afternoonsDisabled.toLowerCase() == 'true') {
          return false;
        }
      }
      // Check if availableAfternoonSlots is empty
      if (vetSchedule!.containsKey('availableAfternoonSlots') && 
          vetSchedule!['availableAfternoonSlots'] is List) {
        final availableAfternoon = vetSchedule!['availableAfternoonSlots'] as List;
        if (availableAfternoon.isEmpty) {
          return false;
        }
      }
    }

    return true;
  }

  // Check if a time slot is available
  bool _isTimeSlotAvailable(DateTime date, String timeSlot) {
    debugPrint('_isTimeSlotAvailable: Checking $timeSlot for date $date');
    
    // Check if it's a morning slot (format: "08:00" to "12:00" in 24-hour format)
    // Morning slots are 08:00 to 11:59, afternoon starts at 12:00
    final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(timeSlot);
    bool isMorning = false;
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1) ?? '');
      if (hour != null) {
        isMorning = hour >= 8 && hour < 12;
      }
    } else {
      // Fallback for old format
      isMorning = timeSlot.contains('AM') || 
                  timeSlot.contains('8:') || 
                  timeSlot.contains('9:') || 
                  timeSlot.contains('10:') || 
                  timeSlot.contains('11:');
    }
    
    if (isMorning && !_areMorningsAvailable()) {
      debugPrint('Time slot $timeSlot blocked: Mornings are completely unavailable');
      return false;
    }

    // Check if it's an afternoon slot and afternoons are completely unavailable
    if (!isMorning && !_areAfternoonsAvailable()) {
      debugPrint('Time slot $timeSlot blocked: Afternoons are completely unavailable');
      return false;
    }

    // First check availability document
    if (vetAvailability != null) {
      debugPrint('Checking availability document (${vetAvailability!.keys.length} keys)');
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // Check if this date exists in availability (new format: date fields with time slot maps)
      if (vetAvailability!.containsKey(dateStr) && 
          vetAvailability![dateStr] is Map) {
        final dateSlots = vetAvailability![dateStr] as Map;
        debugPrint('Found date $dateStr in availability with ${dateSlots.length} time slots');
        
        // Time slot format is already "HH:MM" (e.g., "08:00"), so we can directly check Firebase
        // Check if this exact time key exists in Firebase
        if (dateSlots.containsKey(timeSlot)) {
          final isAvailable = dateSlots[timeSlot];
          debugPrint('Found time slot $timeSlot in availability for $dateStr: $isAvailable');
          if (isAvailable is bool && !isAvailable) {
            debugPrint('Time slot $timeSlot blocked: set to false in availability.$dateStr');
            return false;
          }
        }
        
        // Also try without leading zero (e.g., "8:00" instead of "08:00") for compatibility
        final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeSlot);
        if (timeMatch != null) {
          var hour = int.tryParse(timeMatch.group(1) ?? '');
          var minute = timeMatch.group(2) ?? '00';
          
          if (hour != null) {
            // Try with single digit hour (e.g., "8:00")
            final timeWithoutZero = '$hour:$minute';
            if (timeWithoutZero != timeSlot && dateSlots.containsKey(timeWithoutZero)) {
              final isAvailable = dateSlots[timeWithoutZero];
              debugPrint('Found time slot $timeWithoutZero in availability for $dateStr: $isAvailable');
              if (isAvailable is bool && !isAvailable) {
                debugPrint('Time slot $timeSlot blocked: $timeWithoutZero is set to false in availability.$dateStr');
                return false;
              }
            }
          }
        }
      }
      
      // Also check legacy format: unavailableTimeSlots
      final unavailableSlots = _getUnavailableTimeSlots();
      if (unavailableSlots.containsKey(dateStr)) {
        final unavailableForDate = unavailableSlots[dateStr]!
            .map((s) => s.toString().trim().toLowerCase())
            .toList();
        if (unavailableForDate.contains(timeSlot.trim().toLowerCase())) {
          debugPrint('Time slot $timeSlot blocked: Found in availability.unavailableTimeSlots for $dateStr');
          return false;
        }
        // Also check partial matches
        for (var unavailableSlot in unavailableSlots[dateStr]!) {
          final unavailableStr = unavailableSlot.toString().trim().toLowerCase();
          final timeSlotStr = timeSlot.trim().toLowerCase();
          if (unavailableStr == timeSlotStr ||
              timeSlotStr.contains(unavailableStr) ||
              unavailableStr.contains(timeSlotStr)) {
            debugPrint('Time slot $timeSlot blocked: Matches availability.unavailableTimeSlots entry: $unavailableSlot for $dateStr');
            return false;
          }
        }
      }

      // Also check for disabled slots in availability
      if (vetAvailability!.containsKey('disabledSlots') && 
          vetAvailability!['disabledSlots'] is List) {
        final disabledSlots = vetAvailability!['disabledSlots'] as List;
        final disabledSlotsStr = disabledSlots.map((s) => s.toString().trim().toLowerCase()).toList();
        if (disabledSlotsStr.contains(timeSlot.trim().toLowerCase())) {
          debugPrint('Time slot $timeSlot blocked: Found in availability.disabledSlots');
          return false;
        }
        // Also check partial matches
        for (var disabledSlot in disabledSlots) {
          final disabledStr = disabledSlot.toString().trim().toLowerCase();
          final timeSlotStr = timeSlot.trim().toLowerCase();
          if (disabledStr == timeSlotStr ||
              timeSlotStr.contains(disabledStr) ||
              disabledStr.contains(timeSlotStr)) {
            debugPrint('Time slot $timeSlot blocked: Matches availability.disabledSlots entry: $disabledSlot');
            return false;
          }
        }
      }
      
      // Check for disabledMorningSlots in availability
      if (isMorning && vetAvailability!.containsKey('disabledMorningSlots') && 
          vetAvailability!['disabledMorningSlots'] is List) {
        final disabledMorning = vetAvailability!['disabledMorningSlots'] as List;
        final disabledSlotsStr = disabledMorning.map((s) => s.toString().trim().toLowerCase()).toList();
        if (disabledSlotsStr.contains(timeSlot.trim().toLowerCase())) {
          debugPrint('Time slot $timeSlot blocked: Found in availability.disabledMorningSlots');
          return false;
        }
        for (var disabledSlot in disabledMorning) {
          final disabledStr = disabledSlot.toString().trim().toLowerCase();
          final timeSlotStr = timeSlot.trim().toLowerCase();
          if (disabledStr == timeSlotStr ||
              timeSlotStr.contains(disabledStr) ||
              disabledStr.contains(timeSlotStr)) {
            debugPrint('Time slot $timeSlot blocked: Matches availability.disabledMorningSlots entry: $disabledSlot');
            return false;
          }
        }
      }
    }

    // Check schedule document for disabled slots
    if (vetSchedule != null) {
      debugPrint('Checking schedule document (${vetSchedule!.keys.length} keys): ${vetSchedule!.keys.toList()}');
      
      // Check for disabledSlots field (general - applies to all dates)
      if (vetSchedule!.containsKey('disabledSlots') && vetSchedule!['disabledSlots'] is List) {
        final disabledSlots = vetSchedule!['disabledSlots'] as List;
        debugPrint('Found schedule.disabledSlots: $disabledSlots');
        final disabledSlotsStr = disabledSlots.map((s) => s.toString().trim()).toList();
        if (disabledSlotsStr.contains(timeSlot.trim())) {
          debugPrint('Time slot $timeSlot blocked: Found in schedule.disabledSlots');
          return false;
        }
        // Also check case-insensitive and partial matches
        for (var disabledSlot in disabledSlotsStr) {
          if (disabledSlot.toLowerCase() == timeSlot.trim().toLowerCase() ||
              timeSlot.trim().toLowerCase().contains(disabledSlot.toLowerCase()) ||
              disabledSlot.toLowerCase().contains(timeSlot.trim().toLowerCase())) {
            debugPrint('Time slot $timeSlot blocked: Matches schedule.disabledSlots entry: $disabledSlot');
            return false;
          }
        }
      } else {
        debugPrint('No schedule.disabledSlots found');
      }

      // Check for disabledMorningSlots
      if (vetSchedule!.containsKey('disabledMorningSlots') && 
          vetSchedule!['disabledMorningSlots'] is List) {
        final disabledMorning = vetSchedule!['disabledMorningSlots'] as List;
        debugPrint('Found schedule.disabledMorningSlots: $disabledMorning');
        final disabledSlotsStr = disabledMorning.map((s) => s.toString().trim()).toList();
        if (disabledSlotsStr.contains(timeSlot.trim())) {
          debugPrint('Time slot $timeSlot blocked: Found in schedule.disabledMorningSlots');
          return false;
        }
        // Also check case-insensitive and partial matches
        for (var disabledSlot in disabledSlotsStr) {
          if (disabledSlot.toLowerCase() == timeSlot.trim().toLowerCase() ||
              timeSlot.trim().toLowerCase().contains(disabledSlot.toLowerCase()) ||
              disabledSlot.toLowerCase().contains(timeSlot.trim().toLowerCase())) {
            debugPrint('Time slot $timeSlot blocked: Matches schedule.disabledMorningSlots entry: $disabledSlot');
            return false;
          }
        }
      } else {
        debugPrint('No schedule.disabledMorningSlots found');
      }

      // Check for disabledAfternoonSlots
      if (vetSchedule!.containsKey('disabledAfternoonSlots') && 
          vetSchedule!['disabledAfternoonSlots'] is List) {
        final disabledAfternoon = vetSchedule!['disabledAfternoonSlots'] as List;
        if (disabledAfternoon.contains(timeSlot)) {
          return false;
        }
      }

      // Check for date-specific disabled slots
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (vetSchedule!.containsKey('disabledTimeSlots') && 
          vetSchedule!['disabledTimeSlots'] is Map) {
        final disabledSlots = vetSchedule!['disabledTimeSlots'] as Map;
        if (disabledSlots.containsKey(dateStr) && disabledSlots[dateStr] is List) {
          final dateDisabledSlots = disabledSlots[dateStr] as List;
          if (dateDisabledSlots.contains(timeSlot)) {
            return false;
          }
        }
      }

      // Check if time slot is in enabled slots list (if enabledSlots exists, only those are available)
      if (vetSchedule!.containsKey('enabledSlots') && vetSchedule!['enabledSlots'] is List) {
        final enabledSlots = vetSchedule!['enabledSlots'] as List;
        if (!enabledSlots.contains(timeSlot)) {
          return false;
        }
      }

      // Check for enabledMorningSlots and enabledAfternoonSlots
      // Determine if it's morning (08:00-11:59) or afternoon (12:00-18:00)
      final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(timeSlot);
      bool isMorning = false;
      if (timeMatch != null) {
        final hour = int.tryParse(timeMatch.group(1) ?? '');
        if (hour != null) {
          isMorning = hour >= 8 && hour < 12;
        }
      } else {
        // Fallback for old format
        isMorning = timeSlot.contains('AM') || 
                   timeSlot.contains('8:') || 
                   timeSlot.contains('9:') || 
                   timeSlot.contains('10:') || 
                   timeSlot.contains('11:');
      }
      
      if (isMorning) {
        if (vetSchedule!.containsKey('enabledMorningSlots') && 
            vetSchedule!['enabledMorningSlots'] is List) {
          final enabledMorning = vetSchedule!['enabledMorningSlots'] as List;
          if (!enabledMorning.contains(timeSlot)) {
            return false;
          }
        }
      } else {
        if (vetSchedule!.containsKey('enabledAfternoonSlots') && 
            vetSchedule!['enabledAfternoonSlots'] is List) {
          final enabledAfternoon = vetSchedule!['enabledAfternoonSlots'] as List;
          if (!enabledAfternoon.contains(timeSlot)) {
            return false;
          }
        }
      }
    } else {
      debugPrint('vetSchedule is null, skipping schedule checks');
    }

    debugPrint('Time slot $timeSlot is AVAILABLE');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Clear selected time if it becomes invalid (in the past)
    if (selectedTime != null && _isTimeSlotInPast(selectedTime!)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedTime = null;
          });
        }
      });
    }
    
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: _mint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book an Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/notif_bell.png', width: 26),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Vet Card
              _buildSelectedVetCard(),
              const SizedBox(height: 24),

              // Appointment form
              _buildFormSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedVetCard() {
    final String normalizedStatus = widget.vetStatus.trim().isEmpty
        ? 'Available'
        : widget.vetStatus.trim();
    final bool isUnavailable = normalizedStatus.toLowerCase() == 'unavailable';
    final Color statusColor = isUnavailable ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(15),
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
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vets')
            .doc(widget.vetId)
            .snapshots(),
        builder: (context, snapshot) {
          String? profileImageUrl = widget.profileImageUrl;
          
          if (profileImageUrl == null && snapshot.hasData && snapshot.data!.exists) {
            final vetData = snapshot.data!.data() as Map<String, dynamic>;
            profileImageUrl = vetData['profileImageUrl'] as String?;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vet profile image
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: _mint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? Image.network(
                          profileImageUrl,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 30, color: _mintDark);
                          },
                        )
                      : const Icon(Icons.person, size: 30, color: _mintDark),
                ),
              ),
              const SizedBox(width: 15),

              // Vet info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 5 Star Rating
                    Row(
                      children: List.generate(
                        widget.vetRating,
                        (index) =>
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Status
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          'Status: $normalizedStatus',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Name
                    Text(
                      widget.vetName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _mintDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Specialty
                    Text(
                      widget.vetSpecialty,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              // Right arrow icon
              const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormSection() {
    final bool isVetUnavailable =
        widget.vetStatus.trim().toLowerCase() == 'unavailable';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pets Section
        const Text('Pets', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildPetSelector(),
        const SizedBox(height: 20),

        // Select Date
        const Text(
          'Select Date',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _calendar(),
        const SizedBox(height: 20),

        // Appointment Time
        const Text(
          'Appointment time',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildTimeGrid(),
        const SizedBox(height: 20),

        // Reason Section
        const Text(
          'Reason',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildReasonDropdown(),
        const SizedBox(height: 20),

        // Appointment Summary
        _summaryCard(),
        const SizedBox(height: 20),

        if (isVetUnavailable) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Text(
              'This veterinarian is currently unavailable. Please choose another vet or try again later.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => _showCancelDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVetUnavailable
                  ? null
                  : () async {
                      // Validate all required fields
                      List<String> missingFields = [];

                      if (_selectedPetId == null) {
                        missingFields.add('Pet');
                      }
                      if (selectedTime == null) {
                        missingFields.add('Appointment Time');
                      }
                      if (selectedReason == null) {
                        missingFields.add('Reason');
                      }

                      if (missingFields.isEmpty) {
                        // Validate that the selected time is not in the past
                        if (selectedTime != null && _isTimeSlotInPast(selectedTime!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cannot book appointments in the past. Please select a future time slot.',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        
                        // All fields are filled, proceed with booking
                        try {
                          await _saveAppointmentToFirestore();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Appointment booked! Waiting for vet confirmation.',
                                ),
                                backgroundColor: _mint,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error booking appointment: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      } else {
                        // Show error message with missing fields
                        String message =
                            'Please fill in the following fields: ${missingFields.join(', ')}';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _mint,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPetSelector() {
    if (_isLoadingPets) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _mint),
          ),
        ),
      );
    }

    if (_petLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _petLoadError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadUserPets,
              icon: const Icon(Icons.refresh, color: _mint),
              label: const Text(
                'Retry',
                style: TextStyle(color: _mint, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_userPets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'No pets found. Please add a pet profile before booking.',
          style: TextStyle(color: Colors.black87, fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedPetId,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: _userPets.map((pet) {
        final petName = pet['name'] ?? 'Unnamed Pet';
        final petId = pet['id'] ?? '';
        return DropdownMenuItem(value: petId, child: Text(petName));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPetId = value;
          _selectedPetName = _userPets.firstWhere(
            (pet) => pet['id'] == value,
            orElse: () => {'name': 'Unnamed Pet'},
          )['name'];
        });
      },
      hint: const Text('Select Pet'),
    );
  }

  Widget _calendar() {
    if (_isLoadingSchedule) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _mint),
        ),
      );
    }

    // Find the first available date to use as initialDate if current selectedDate is not available
    DateTime initialDate = selectedDate;
    if (!_isDateSelectable(selectedDate)) {
      // Find first available date
      final today = DateTime.now();
      for (int i = 0; i < 730; i++) {
        final candidateDate = today.add(Duration(days: i));
        if (_isDateSelectable(candidateDate)) {
          initialDate = candidateDate;
          // Update selectedDate if it was changed
          if (selectedDate != initialDate) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  selectedDate = initialDate;
                });
                _loadBookedTimeSlots();
              }
            });
          }
          break;
        }
      }
    }

    return CalendarDatePicker(
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      selectableDayPredicate: (date) => _isDateSelectable(date),
      onDateChanged: (date) {
        setState(() {
          selectedDate = date;
          if (selectedTime != null && 
              (_isTimeSlotInPast(selectedTime!) || 
               !_isTimeSlotAvailable(date, selectedTime!))) {
            selectedTime = null;
          }
        });
        _loadBookedTimeSlots();
      },
    );
  }

  // Check if a time slot is in the past (only for today's date)
  // timeSlot can be in HH:MM format (e.g., "08:00", "13:00") or formatted string (e.g., "8:00 - 9:00 AM")
  bool _isTimeSlotInPast(String timeSlot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    // Only check for past times if the selected date is today
    if (selectedDay.isAtSameMomentAs(today)) {
      int hour24;
      int minute;
      
      // Check if timeSlot is already in HH:MM format (24-hour format)
      if (RegExp(r'^\d{2}:\d{2}$').hasMatch(timeSlot.trim())) {
        // Already in 24-hour format, parse directly
        final timeParts = timeSlot.trim().split(':');
        hour24 = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      } else {
        // Parse from formatted string (e.g., "8:00 - 9:00 AM" or "11:00 - 12:00 PM")
        final timeParts = timeSlot.split(' ')[0].split(':');
        final hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
        
        // Determine if the start time is AM or PM
        // For "11:00 - 12:00 PM", the start time is 11:00 AM (not PM)
        // Check if it's in the morning list (AM) or afternoon list (PM)
        bool isAM;
        if (morningTimes.contains(timeSlot)) {
          // Morning slots: all are AM, even "11:00 - 12:00 PM" starts at 11:00 AM
          isAM = true;
        } else if (afternoonTimes.contains(timeSlot)) {
          // Afternoon slots: all are PM
          isAM = false;
        } else {
          // Fallback: check if string contains AM (for start time)
          // If it contains both AM and PM, check the start hour
          final hasAM = timeSlot.contains('AM');
          final hasPM = timeSlot.contains('PM');
          
          if (hasAM && !hasPM) {
            isAM = true;
          } else if (hasPM && !hasAM) {
            // If only PM, check if start hour is 12 (noon) or 1-11 (afternoon)
            isAM = hour == 12; // 12:00 PM is noon, but 12:00 - 1:00 PM starts at noon
          } else {
            // Has both AM and PM (like "11:00 - 12:00 PM")
            // The start time is AM if hour is 1-11, PM if hour is 12
            isAM = hour != 12;
          }
        }
        
        hour24 = hour;
        if (!isAM && hour != 12) {
          hour24 += 12;
        } else if (isAM && hour == 12) {
          hour24 = 0;
        }
      }
      
      // Create DateTime for the time slot start time
      final slotDateTime = DateTime(now.year, now.month, now.day, hour24, minute);
      
      // Check if the time slot is in the past
      // If the slot's start time is before or equal to the current time, it's in the past
      // We use isBefore because if it's exactly the same time, we still want to show it
      // (e.g., if it's 9:00 PM exactly, show 9:00 PM slots)
      // But if it's 9:15 PM, then 9:00 PM slots should be filtered (they've already started)
      final isPast = slotDateTime.isBefore(now);
      debugPrint('_isTimeSlotInPast: $timeSlot -> $hour24:$minute -> $slotDateTime -> isPast: $isPast (now: $now)');
      return isPast;
    }
    
    // For future dates, all time slots are available
    return false;
  }

  // Get available time slots (filtered for today, availability, and booked slots)
  // Returns ONLY the time slots that are set to true in Firebase for the selected date
  List<String> get availableMorningTimes {
    debugPrint('=== Computing availableMorningTimes ===');
    debugPrint('Selected Date: $selectedDate');
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    // Get time slots EXACTLY as set in Firebase for this date
    List<String> slotsForDate = [];
    if (availableDatesAndSlots.containsKey(dateStr)) {
      // Get all slots for this date from Firebase
      final allSlotsForDate = availableDatesAndSlots[dateStr]!;
      debugPrint('All available slots for $dateStr from Firebase: $allSlotsForDate');
      
      // Filter for morning slots (8:00-11:59 in 24-hour format)
      slotsForDate = allSlotsForDate
          .where((slot) {
            final hour = _getHourFromTimeSlot(slot);
            final isMorning = hour >= 8 && hour < 12;
            debugPrint('  Checking slot: $slot -> hour: $hour, isMorning: $isMorning');
            if (isMorning) {
              debugPrint('  ✓ Morning slot found: $slot (hour: $hour)');
            } else {
              debugPrint('  ✗ Not morning slot: $slot (hour: $hour)');
            }
            return isMorning;
          })
          .toList();
      
      // Sort by time
      slotsForDate.sort((a, b) {
        final hourA = _getHourFromTimeSlot(a);
        final minuteA = _getMinuteFromTimeSlot(a);
        final hourB = _getHourFromTimeSlot(b);
        final minuteB = _getMinuteFromTimeSlot(b);
        if (hourA != hourB) {
          return hourA.compareTo(hourB);
        }
        return minuteA.compareTo(minuteB);
      });
      
      debugPrint('Morning Times for $dateStr from Firebase (sorted): $slotsForDate');
    } else {
      debugPrint('No slots found in Firebase for date $dateStr');
      debugPrint('Available dates in Firebase: ${allAvailableDates.toList()}');
      debugPrint('Available dates and slots keys: ${availableDatesAndSlots.keys.toList()}');
    }
    
    // First check if mornings are completely unavailable
    final morningsAvailable = _areMorningsAvailable();
    if (!morningsAvailable) {
      debugPrint('availableMorningTimes: Mornings are completely unavailable, returning empty list');
      return [];
    }

    // Filter out past times and booked slots
    final filtered = slotsForDate.where((time) {
      if (_isTimeSlotInPast(time)) {
        debugPrint('  Filtered out: $time (in past)');
        return false;
      }
      
      // Double-check availability (should already be true from Firebase, but verify)
      // Since we're getting slots directly from Firebase where they're set to true,
      // we can skip this check to avoid any filtering issues
      // final isAvailable = _isTimeSlotAvailable(selectedDate, time);
      // if (!isAvailable) {
      //   debugPrint('  Filtered out: $time (not available)');
      //   return false;
      // }
      
      if (bookedTimeSlots.contains(time)) {
        debugPrint('  Filtered out: $time (already booked)');
        return false;
      }
      
      return true;
    }).toList();
    
    debugPrint('availableMorningTimes: ${slotsForDate.length} from Firebase, ${filtered.length} after filtering');
    if (filtered.length != slotsForDate.length) {
      final filteredOut = slotsForDate.where((slot) => !filtered.contains(slot)).toList();
      debugPrint('  Filtered out slots: $filteredOut');
    }
    debugPrint('Final available morning times: $filtered');
    return filtered;
  }

  List<String> get availableAfternoonTimes {
    debugPrint('=== Computing availableAfternoonTimes ===');
    debugPrint('Selected Date: $selectedDate');
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    // Get time slots EXACTLY as set in Firebase for this date
    List<String> slotsForDate = [];
    if (availableDatesAndSlots.containsKey(dateStr)) {
      // Get all slots for this date from Firebase
      final allSlotsForDate = availableDatesAndSlots[dateStr]!;
      debugPrint('All available slots for $dateStr from Firebase: $allSlotsForDate');
      
      // Filter for afternoon slots (12:00-18:00 in 24-hour format)
      slotsForDate = allSlotsForDate
          .where((slot) {
            final hour = _getHourFromTimeSlot(slot);
            final isAfternoon = hour >= 12 && hour <= 18;
            debugPrint('  Checking slot: $slot -> hour: $hour, isAfternoon: $isAfternoon');
            if (isAfternoon) {
              debugPrint('  ✓ Afternoon slot found: $slot (hour: $hour)');
            } else {
              debugPrint('  ✗ Not afternoon slot: $slot (hour: $hour)');
            }
            return isAfternoon;
          })
          .toList();
      
      // Sort by time
      slotsForDate.sort((a, b) {
        final hourA = _getHourFromTimeSlot(a);
        final minuteA = _getMinuteFromTimeSlot(a);
        final hourB = _getHourFromTimeSlot(b);
        final minuteB = _getMinuteFromTimeSlot(b);
        if (hourA != hourB) {
          return hourA.compareTo(hourB);
        }
        return minuteA.compareTo(minuteB);
      });
      
      debugPrint('Afternoon Times for $dateStr from Firebase (sorted): $slotsForDate');
    } else {
      debugPrint('No slots found in Firebase for date $dateStr');
      debugPrint('Available dates in Firebase: ${allAvailableDates.toList()}');
      debugPrint('Available dates and slots keys: ${availableDatesAndSlots.keys.toList()}');
    }
    
    debugPrint('Afternoon Times for $dateStr from Firebase: $slotsForDate');
    
    // First check if afternoons are completely unavailable
    final afternoonsAvailable = _areAfternoonsAvailable();
    debugPrint('Afternoons available check: $afternoonsAvailable');
    if (!afternoonsAvailable) {
      debugPrint('availableAfternoonTimes: Afternoons are completely unavailable, returning empty list');
      return [];
    }

    // Filter out past times and booked slots
    // Note: We don't need to check _isTimeSlotAvailable since we're already getting
    // slots that are set to true in Firebase
    final filtered = slotsForDate.where((time) {
      if (_isTimeSlotInPast(time)) {
        debugPrint('  Filtered out: $time (in past)');
        return false;
      }
      if (bookedTimeSlots.contains(time)) {
        debugPrint('  Filtered out: $time (already booked)');
        return false;
      }
      debugPrint('  ✓ Available: $time');
      return true;
    }).toList();
    
    debugPrint('availableAfternoonTimes: ${slotsForDate.length} from Firebase, ${filtered.length} after filtering');
    if (filtered.length != slotsForDate.length) {
      final filteredOut = slotsForDate.where((slot) => !filtered.contains(slot)).toList();
      debugPrint('  Filtered out slots: $filteredOut');
    }
    debugPrint('Final available afternoon times: $filtered');
    return filtered;
  }

  Widget _buildTimeGrid() {
    if (_isLoadingSchedule) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _mint),
        ),
      );
    }

    final morningSlots = availableMorningTimes;
    final afternoonSlots = availableAfternoonTimes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Morning Section
        const Text(
          'Morning',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (morningSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No morning slots available for today',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: morningSlots.length,
            itemBuilder: (context, index) {
              final time = morningSlots[index];
              final bool selected = selectedTime == time;
              return GestureDetector(
                onTap: () => setState(() => selectedTime = time),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _mint : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? _mint : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _formatTimeSlotForDisplay(time),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),

        // Afternoon Section
        const Text(
          'Afternoon',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (afternoonSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No afternoon slots available for today',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: afternoonSlots.length,
            itemBuilder: (context, index) {
              final time = afternoonSlots[index];
              final bool selected = selectedTime == time;
              return GestureDetector(
                onTap: () => setState(() => selectedTime = time),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _mint : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? _mint : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _formatTimeSlotForDisplay(time),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _mintDark,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Pet:', _selectedPetName ?? '-'),
          _summaryRow('Reason:', selectedReason ?? '-'),
          _summaryRow(
            'Date & Time:',
            selectedTime != null
                ? '${DateFormat('MMM d, yyyy').format(selectedDate)}, ${_formatTimeSlotForDisplay(selectedTime!)}'
                : '${DateFormat('MMM d, yyyy').format(selectedDate)}, -',
          ),
          _summaryRow(
            'Estimated Cost:',
            estimatedCost != null ? 'PHP $estimatedCost' : '-',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  // Save appointment to Firestore
  Future<void> _saveAppointmentToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Combine date and time for appointment datetime
    final appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _parseHourFromTime(selectedTime!),
      _parseMinuteFromTime(selectedTime!),
    );

    // Get appointment data
    final appointmentData = {
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': user.displayName ?? '',
      'petId': _selectedPetId,
      'petName': _selectedPetName!,
      'vetId': widget.vetId,
      'vetName': widget.vetName,
      'vetSpecialty': widget.vetSpecialty,
      'vetRating': widget.vetRating,
      'appointmentType': 'In person',
      'date': Timestamp.fromDate(selectedDate),
      'timeSlot': selectedTime,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'reason': selectedReason!,
      'cost': estimatedCost ?? 0,
      'status':
          'pending', // pending, declined, confirmed, cancelled (only vets can change)
      'createdAt': Timestamp.now(),
      'dismissedNotifications': <String>[],
    };

    // Save to user_appointments collection
    final docRef = await FirebaseFirestore.instance
        .collection('user_appointments')
        .add(appointmentData);

    await _createOrUpdateNotificationForAppointment(docRef.id, appointmentData);
  }

  // Helper methods to parse time string
  int _parseHourFromTime(String time) {
    // Format: "08:00" (24-hour format) or legacy "8:00 - 9:00 AM"
    final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(time);
    if (timeMatch != null) {
      // New format: already in 24-hour format
      return int.parse(timeMatch.group(1)!);
    }
    
    // Legacy format: "8:00 - 9:00 AM" or "1:00 - 2:00 PM"
    final parts = time.split(' ')[0].split(':');
    int hour = int.parse(parts[0]);
    final isPM = time.contains('PM');
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    return hour;
  }

  int _parseMinuteFromTime(String time) {
    // Format: "08:00" (24-hour format) or legacy "8:00 - 9:00 AM"
    final timeMatch = RegExp(r'(\d{2}):(\d{2})').firstMatch(time);
    if (timeMatch != null) {
      // New format: already in 24-hour format
      return int.parse(timeMatch.group(2)!);
    }
    
    // Legacy format
    final parts = time.split(' ')[0].split(':');
    return int.parse(parts[1]);
  }


  Future<void> _loadReasonsFromDatabase() async {
    setState(() {
      _isLoadingReasons = true;
    });

    try {
      List<Map<String, dynamic>> allReasons = [];
      DocumentSnapshot? settingsDoc;
      Map<String, dynamic>? vetData;

      // FIRST: Try to fetch directly from the vet's document in 'vets' collection
      // This is where the vet's own prices and appointment reasons should be stored
      final vetDoc = await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .get();

      if (vetDoc.exists) {
        vetData = vetDoc.data();
        debugPrint('Loaded vet document: ${vetDoc.id}');
        debugPrint('Vet document fields: ${vetData?.keys.toList()}');
        debugPrint('Vet document data: $vetData');
        
        // Check if vet document has appointment reasons or prices
        // Look for common field names: appointmentReasons, reasons, services, prices, etc.
        if (vetData != null) {
          // Try to find reasons in the vet document
          if (vetData.containsKey('appointmentReasons')) {
            final vetReasons = vetData['appointmentReasons'] as List<dynamic>?;
            if (vetReasons != null && vetReasons.isNotEmpty) {
              allReasons = vetReasons.map((r) {
                if (r is Map) {
                  // Preserve ALL fields from the reason object
                  return Map<String, dynamic>.from(r);
                }
                return {'label': r.toString(), 'price': 0};
              }).toList();
            }
          } else if (vetData.containsKey('reasons')) {
            final vetReasons = vetData['reasons'] as List<dynamic>?;
            if (vetReasons != null && vetReasons.isNotEmpty) {
              allReasons = vetReasons.map((r) {
                if (r is Map) {
                  return Map<String, dynamic>.from(r);
                }
                return {'label': r.toString(), 'price': 0};
              }).toList();
            }
          } else if (vetData.containsKey('services')) {
            final vetServices = vetData['services'];
            if (vetServices is Map) {
              // Parse nested services structure
              allReasons.addAll(VetServicesParser.parseNestedServices(
                Map<String, dynamic>.from(vetServices)
              ));
            } else if (vetServices is List && vetServices.isNotEmpty) {
              // Handle list format
              allReasons = vetServices.map((r) {
                if (r is Map) {
                  return Map<String, dynamic>.from(r);
                }
                return {'label': r.toString(), 'price': 0};
              }).toList();
            }
          } else if (vetData.containsKey('prices')) {
            // If prices is a map, convert it to a list of reasons
            final prices = vetData['prices'];
            if (prices is Map && prices.isNotEmpty) {
              allReasons = (prices as Map<String, dynamic>).entries.map((entry) {
                final result = <String, dynamic>{
                  'label': entry.key,
                  'price': entry.value is num ? entry.value : 0,
                };
                if (entry.value is Map) {
                  result.addAll(Map<String, dynamic>.from(entry.value as Map));
                }
                return result;
              }).toList();
            }
          }
          
          // If no structured reasons found, look for any list fields that might contain reasons
          if (allReasons.isEmpty) {
            for (var entry in vetData.entries) {
              if (entry.value is List && (entry.value as List).isNotEmpty) {
                final listValue = entry.value as List<dynamic>;
                // Check if it looks like a list of reasons (contains maps)
                if (listValue.isNotEmpty && listValue.first is Map) {
                  allReasons = listValue.map((r) {
                    if (r is Map) {
                      return Map<String, dynamic>.from(r);
                    }
                    return {'label': r.toString(), 'price': 0};
                  }).toList();
                  break;
                }
              }
            }
          }
        }
      }

      // SECOND: Try app_settings collection with vet_rates_{vetId} format
      // This is the PRIMARY location for vet-specific rates (as shown in Firestore console)
      // Try multiple methods to find the document
      DocumentSnapshot? foundDoc;
      
      // Method 1: Try document ID format: vet_rates_{vetId}
      settingsDoc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('vet_rates_${widget.vetId}')
          .get();
      
      if (settingsDoc.exists) {
        foundDoc = settingsDoc;
        debugPrint('Found vet_rates document by ID: vet_rates_${widget.vetId}');
      } else {
        // Method 2: Query by vetId field
        debugPrint('Document not found by ID, querying by vetId field...');
        final querySnapshot = await FirebaseFirestore.instance
            .collection('app_settings')
            .where('vetId', isEqualTo: widget.vetId)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          foundDoc = querySnapshot.docs.first;
          debugPrint('Found document by vetId field: ${foundDoc.id}');
        } else {
          // Method 3: Try just the vetId as document ID
          settingsDoc = await FirebaseFirestore.instance
              .collection('app_settings')
              .doc(widget.vetId)
              .get();
          
          if (settingsDoc.exists) {
            foundDoc = settingsDoc;
            debugPrint('Found document by vetId as ID: ${widget.vetId}');
          }
        }
      }

      // If vet_rates document exists, parse it (even if we found some reasons in vet document)
      // This ensures we get all the structured rates
      if (foundDoc != null && foundDoc.exists) {
        final data = foundDoc.data() as Map<String, dynamic>;
        
        // Debug: Log all fields in the document
        debugPrint('=== LOADED VET RATES DOCUMENT ===');
        debugPrint('Document ID: ${foundDoc.id}');
        debugPrint('Document fields: ${data.keys.toList()}');
        debugPrint('Full document data: $data');
        
        // Verify vetId matches if field exists
        if (data.containsKey('vetId')) {
          final docVetId = data['vetId'] as String?;
          debugPrint('Document vetId: $docVetId, Expected: ${widget.vetId}');
          if (docVetId != null && docVetId != widget.vetId) {
            debugPrint('WARNING: vetId mismatch! Skipping this document.');
          } else {
            // Parse all services using shared utility
            final parsedServices = VetServicesParser.parseVetRatesDocument(data);
            debugPrint('Parsed ${parsedServices.length} services from document');
            allReasons.addAll(parsedServices);
          }
        } else {
          // No vetId field, parse anyway (might be the right document)
          final parsedServices = VetServicesParser.parseVetRatesDocument(data);
          debugPrint('Parsed ${parsedServices.length} services from document (no vetId field)');
          allReasons.addAll(parsedServices);
        }
      } else if (allReasons.isEmpty) {
        debugPrint('No vet_rates document found for vetId: ${widget.vetId}');
        // Fallback: Try other document formats only if vet_rates doesn't exist
        // Try document ID as the vetId in app_settings
        settingsDoc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc(widget.vetId)
            .get();

        // Try with 'appointment_reasons_' prefix
        if (!settingsDoc.exists) {
          settingsDoc = await FirebaseFirestore.instance
              .collection('app_settings')
              .doc('appointment_reasons_${widget.vetId}')
              .get();
        }

        // FOURTH: Fall back to global appointment_reasons document
        if (!settingsDoc.exists) {
          settingsDoc = await FirebaseFirestore.instance
              .collection('app_settings')
              .doc('appointment_reasons')
              .get();
        }

        if (settingsDoc.exists) {
          final data = settingsDoc.data() as Map<String, dynamic>;
          
          // Debug: Log all fields in the document
          debugPrint('Loaded app_settings document: ${settingsDoc.id}');
          debugPrint('Document fields: ${data.keys.toList()}');
          debugPrint('Document data: $data');

          // Parse all services using shared utility
          allReasons.addAll(VetServicesParser.parseVetRatesDocument(data));

          // Fallback: If no services found, try old format (rating-based or list-based)
          if (allReasons.isEmpty) {
            final ratingKey = 'rating_${widget.vetRating}';
            if (data.containsKey(ratingKey)) {
              final ratingReasons = data[ratingKey] as List<dynamic>?;
              if (ratingReasons != null && ratingReasons.isNotEmpty) {
                allReasons = ratingReasons.map((r) {
                  if (r is Map) {
                    return Map<String, dynamic>.from(r);
                  }
                  return {'label': r.toString(), 'price': 0};
                }).toList();
              }
            }

            if (allReasons.isEmpty && data.containsKey('default')) {
              final defaultReasons = data['default'] as List<dynamic>?;
              if (defaultReasons != null && defaultReasons.isNotEmpty) {
                allReasons = defaultReasons.map((r) {
                  if (r is Map) {
                    return Map<String, dynamic>.from(r);
                  }
                  return {'label': r.toString(), 'price': 0};
                }).toList();
              }
            }

            if (allReasons.isEmpty && data.containsKey('reasons')) {
              final reasonsList = data['reasons'] as List<dynamic>?;
              if (reasonsList != null && reasonsList.isNotEmpty) {
                allReasons = reasonsList.map((r) {
                  if (r is Map) {
                    return Map<String, dynamic>.from(r);
                  }
                  return {'label': r.toString(), 'price': 0};
                }).toList();
              }
            }
          }
        }
      }

      // Debug: Log extracted reasons
      debugPrint('Extracted ${allReasons.length} reasons from vetId: ${widget.vetId}');
      for (var i = 0; i < allReasons.length; i++) {
        debugPrint('Reason $i: ${allReasons[i]}');
      }

      // Set the reasons (whether from vet document or app_settings)
      if (allReasons.isNotEmpty) {
        setState(() {
          reasons = allReasons;
          _isLoadingReasons = false;
        });
      } else {
        // Fallback to default reasons if settings don't exist
        setState(() {
          reasons = [
            {'label': 'Regular Check-up', 'price': 800},
            {'label': 'Grooming', 'price': 500},
            {'label': 'Vaccination', 'price': 300},
            {'label': 'Emergency', 'price': 1500},
            {'label': 'Consultation', 'price': 500},
          ];
          _isLoadingReasons = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reasons from database: $e');
      // Fallback to default reasons on error
      setState(() {
        reasons = [
          {'label': 'Regular Check-up', 'price': 800},
          {'label': 'Grooming', 'price': 500},
          {'label': 'Vaccination', 'price': 300},
          {'label': 'Emergency', 'price': 1500},
          {'label': 'Consultation', 'price': 500},
        ];
        _isLoadingReasons = false;
      });
    }
  }

  Widget _buildReasonDropdown() {
    if (_isLoadingReasons) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _mint),
          ),
        ),
      );
    }

    if (reasons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'No reasons available. Please try again later.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      hint: const Text('Select reason'),
      items: reasons.map((r) {
        final label = r['label'] as String? ?? 
                     r['name'] as String? ?? 
                     r['title'] as String? ?? 
                     r['reason'] as String? ?? 
                     'Unknown';
        final price = (r['price'] as num?)?.toInt() ?? 
                     (r['cost'] as num?)?.toInt() ?? 
                     (r['amount'] as num?)?.toInt() ?? 
                     0;
        
        // Build display text with all available information
        String displayText = label;
        
        // Add price if available
        if (price > 0) {
          displayText += ' - PHP $price';
        }
        
        // Add description if available
        final description = r['description'] as String? ?? 
                          r['desc'] as String? ?? 
                          r['details'] as String?;
        if (description != null && description.isNotEmpty) {
          displayText += '\n$description';
        }
        
        // Add duration if available
        final duration = r['duration'] as String? ?? 
                        r['time'] as String?;
        if (duration != null && duration.isNotEmpty) {
          displayText += ' (Duration: $duration)';
        }
        
        return DropdownMenuItem<String>(
          value: label,
          child: Text(
            displayText,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        final selected = reasons.firstWhere(
          (r) {
            final label = r['label'] as String? ?? 
                         r['name'] as String? ?? 
                         r['title'] as String? ?? 
                         r['reason'] as String? ?? 
                         '';
            return label == value;
          },
          orElse: () => {'price': 0},
        );
        setState(() {
          selectedReason = value;
          // Try multiple price field names
          estimatedCost = (selected['price'] as num?)?.toInt() ?? 
                        (selected['cost'] as num?)?.toInt() ?? 
                        (selected['amount'] as num?)?.toInt();
        });
      },
      value: selectedReason,
    );
  }

  Future<void> _loadUserPets() async {
    setState(() {
      _isLoadingPets = true;
      _petLoadError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingPets = false;
          _userPets.clear();
          _selectedPetId = null;
          _selectedPetName = null;
          _petLoadError = 'Please sign in to view your pets.';
        });
        return;
      }

      final baseQuery = FirebaseFirestore.instance
          .collection('petInfos')
          .where('userId', isEqualTo: user.uid);

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await baseQuery.orderBy('name').get();
      } on FirebaseException catch (orderError) {
        // Missing index or other ordering issue—retry without ordering.
        debugPrint('Order by name failed: ${orderError.message}');
        snapshot = await baseQuery.get();
      }

      final pets = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();
        final rawName = (data['name'] as String?)?.trim();
        final name = (rawName != null && rawName.isNotEmpty)
            ? rawName
            : 'Unnamed Pet';

        return {'id': doc.id, 'name': name};
      }).toList()..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      setState(() {
        _userPets
          ..clear()
          ..addAll(pets);

        if (_userPets.isEmpty) {
          _selectedPetId = null;
          _selectedPetName = null;
        } else if (_selectedPetId == null ||
            !_userPets.any((pet) => pet['id'] == _selectedPetId)) {
          _selectedPetId = _userPets.first['id'];
          _selectedPetName = _userPets.first['name'];
        }

        _isLoadingPets = false;
      });
    } catch (e, stack) {
      debugPrint('Failed to load pets: $e');
      debugPrint(stack.toString());
      setState(() {
        _isLoadingPets = false;
        _petLoadError = 'Failed to load pets. Please try again.';
      });
    }
  }

  Future<void> _createOrUpdateNotificationForAppointment(
    String appointmentId,
    Map<String, dynamic> appointmentData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(appointmentId);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final existingSnap = await txn.get(notificationsRef);
        final previousStatus = (existingSnap.data()?['status'] as String?)
            ?.toLowerCase()
            .trim();
        final status =
            (appointmentData['status'] as String?)?.toLowerCase().trim() ??
            'pending';
        final isStatusChanged =
            !existingSnap.exists || previousStatus != status;

        final payload = <String, dynamic>{
          'userId': user.uid,
          'appointmentId': appointmentId,
          'status': status,
          'vetName': appointmentData['vetName'],
          'petName': appointmentData['petName'],
          'date': appointmentData['date'],
          'timeSlot': appointmentData['timeSlot'],
          'appointmentDateTime': appointmentData['appointmentDateTime'],
          'meetingLink': appointmentData['meetingLink'],
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (isStatusChanged) {
          payload['createdAt'] = FieldValue.serverTimestamp();
          payload['isRead'] = false;
        } else {
          payload['isRead'] = existingSnap.data()?['isRead'] as bool? ?? false;
        }

        txn.set(notificationsRef, payload, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Failed to sync notification: $e');
    }
  }
}

