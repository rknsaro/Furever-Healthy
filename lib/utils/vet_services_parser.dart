import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Utility class to parse vet services from Firebase documents
class VetServicesParser {
  /// Recursively parse nested services structure
  /// Handles: services > Category > Service Name > {price, enabled, ...}
  static List<Map<String, dynamic>> parseNestedServices(
    Map<String, dynamic> services,
    [String? categoryPath]
  ) {
    List<Map<String, dynamic>> result = [];

    services.forEach((key, value) {
      if (value is Map) {
        // Check if this map contains a 'price' field (it's a service)
        if (value.containsKey('price') || value.containsKey('enabled')) {
          // This is a service object
          final serviceData = Map<String, dynamic>.from(value);
          final serviceName = categoryPath != null ? '$categoryPath: $key' : key;
          final price = (serviceData['price'] as num?)?.toInt() ?? 0;
          final enabled = serviceData['enabled'] as bool? ?? true;

          // Only add if enabled
          if (enabled) {
            result.add({
              'label': serviceName,
              'price': price,
              'category': categoryPath ?? '',
              'type': 'service',
              ...serviceData, // Include all other fields
            });
          }
        } else {
          // This is a category, recurse deeper
          final newPath = categoryPath != null ? '$categoryPath > $key' : key;
          result.addAll(parseNestedServices(
            Map<String, dynamic>.from(value),
            newPath,
          ));
        }
      } else if (value is num) {
        // Direct price value
        final serviceName = categoryPath != null ? '$categoryPath: $key' : key;
        result.add({
          'label': serviceName,
          'price': value.toInt(),
          'type': 'service',
        });
      }
    });

    return result;
  }

  /// Parse all services from a vet_rates document
  static List<Map<String, dynamic>> parseVetRatesDocument(
    Map<String, dynamic> data,
  ) {
    List<Map<String, dynamic>> allServices = [];

    // Parse nested services structure (services > Category > Service Name > price)
    if (data.containsKey('services') && data['services'] is Map) {
      final services = data['services'] as Map<String, dynamic>;
      allServices.addAll(parseNestedServices(services));
    }

    // Parse custom_services (flat map: serviceName -> price)
    if (data.containsKey('custom_services') && data['custom_services'] is Map) {
      final customServices = data['custom_services'] as Map<String, dynamic>;
      customServices.forEach((serviceName, value) {
        if (value is num) {
          allServices.add({
            'label': serviceName,
            'price': value.toInt(),
            'type': 'custom_service',
          });
        } else if (value is Map) {
          final serviceData = Map<String, dynamic>.from(value);
          allServices.add({
            'label': serviceName,
            'price': (serviceData['price'] as num?)?.toInt() ?? 0,
            ...serviceData,
            'type': 'custom_service',
          });
        }
      });
    }

    // Parse dog_vaccination_rates
    if (data.containsKey('dog_vaccination_rates') && 
        data['dog_vaccination_rates'] is Map) {
      final dogVaccRates = data['dog_vaccination_rates'] as Map<String, dynamic>;
      dogVaccRates.forEach((serviceName, value) {
        if (value is num) {
          allServices.add({
            'label': 'Dog Vaccination: $serviceName',
            'price': value.toInt(),
            'type': 'dog_vaccination',
          });
        } else if (value is Map) {
          // Handle nested structure if needed
          final serviceData = Map<String, dynamic>.from(value);
          allServices.add({
            'label': 'Dog Vaccination: $serviceName',
            'price': (serviceData['price'] as num?)?.toInt() ?? 0,
            ...serviceData,
            'type': 'dog_vaccination',
          });
        }
      });
    }

    // Parse cat_vaccination_rates
    // Structure: {default: 1000, consultation_fee_php: 500, ...}
    if (data.containsKey('cat_vaccination_rates') && 
        data['cat_vaccination_rates'] is Map) {
      final catVaccRates = data['cat_vaccination_rates'] as Map<String, dynamic>;
      catVaccRates.forEach((serviceName, value) {
        if (value is num) {
          // Format label based on key name
          String label = serviceName == 'default' 
              ? 'Cat Vaccination' 
              : 'Cat Vaccination: ${serviceName.replaceAll('_', ' ').replaceAll('php', 'PHP')}';
          allServices.add({
            'label': label,
            'price': value.toInt(),
            'type': 'cat_vaccination',
          });
        } else if (value is Map) {
          final serviceData = Map<String, dynamic>.from(value);
          allServices.add({
            'label': 'Cat Vaccination: $serviceName',
            'price': (serviceData['price'] as num?)?.toInt() ?? 0,
            ...serviceData,
            'type': 'cat_vaccination',
          });
        }
      });
    }

    // Parse vaccination_rates
    if (data.containsKey('vaccination_rates') && 
        data['vaccination_rates'] is Map) {
      final vaccRates = data['vaccination_rates'] as Map<String, dynamic>;
      vaccRates.forEach((serviceName, value) {
        if (value is num) {
          allServices.add({
            'label': 'Vaccination: $serviceName',
            'price': value.toInt(),
            'type': 'vaccination',
          });
        } else if (value is Map) {
          final serviceData = Map<String, dynamic>.from(value);
          allServices.add({
            'label': 'Vaccination: $serviceName',
            'price': (serviceData['price'] as num?)?.toInt() ?? 0,
            ...serviceData,
            'type': 'vaccination',
          });
        }
      });
    }

    // Parse deworming_rates
    if (data.containsKey('deworming_rates') && 
        data['deworming_rates'] is Map) {
      final dewormRates = data['deworming_rates'] as Map<String, dynamic>;
      dewormRates.forEach((serviceName, value) {
        if (value is num) {
          // Format label: large_pet -> Large Pet, small_pet -> Small Pet
          String label = serviceName
              .split('_')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');
          allServices.add({
            'label': 'Deworming: $label',
            'price': value.toInt(),
            'type': 'deworming',
          });
        } else if (value is Map) {
          final serviceData = Map<String, dynamic>.from(value);
          allServices.add({
            'label': 'Deworming: $serviceName',
            'price': (serviceData['price'] as num?)?.toInt() ?? 0,
            ...serviceData,
            'type': 'deworming',
          });
        }
      });
    }

    return allServices;
  }

  /// Fetch and parse services from app_settings collection
  /// Tries multiple document ID formats and also queries by vetId field
  static Future<List<Map<String, dynamic>>> fetchVetServices(String vetId) async {
    try {
      // First, try document ID format: vet_rates_{vetId}
      var doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('vet_rates_$vetId')
          .get();

      // If not found, try querying by vetId field
      if (!doc.exists) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('app_settings')
            .where('vetId', isEqualTo: vetId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          doc = querySnapshot.docs.first;
        }
      }

      // If still not found, try just the vetId as document ID
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc(vetId)
            .get();
      }

      if (!doc.exists) {
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      
      // Verify the vetId matches (if vetId field exists in document)
      if (data.containsKey('vetId')) {
        final docVetId = data['vetId'] as String?;
        if (docVetId != null && docVetId != vetId) {
          // Document exists but vetId doesn't match
          return [];
        }
      }

      return parseVetRatesDocument(data);
    } catch (e) {
      debugPrint('Error fetching vet services: $e');
      return [];
    }
  }
}

