import 'dart:convert';

class PetBreed {
  final String name;
  final String animalType;
  final String breedGroup;
  final String size;
  final String lifeSpan;
  final String description;
  final Map<String, int> characteristics;
  final Map<String, String> careGuide;

  const PetBreed({
    required this.name,
    required this.animalType,
    required this.breedGroup,
    required this.size,
    required this.lifeSpan,
    required this.description,
    required this.characteristics,
    required this.careGuide,
  });

  PetBreed copyWith({
    String? name,
    String? animalType,
    String? breedGroup,
    String? size,
    String? lifeSpan,
    String? description,
    Map<String, int>? characteristics,
    Map<String, String>? careGuide,
  }) {
    return PetBreed(
      name: name ?? this.name,
      animalType: animalType ?? this.animalType,
      breedGroup: breedGroup ?? this.breedGroup,
      size: size ?? this.size,
      lifeSpan: lifeSpan ?? this.lifeSpan,
      description: description ?? this.description,
      characteristics:
          characteristics ?? Map<String, int>.from(this.characteristics),
      careGuide: careGuide ?? Map<String, String>.from(this.careGuide),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'animalType': animalType,
      'breedGroup': breedGroup,
      'size': size,
      'lifeSpan': lifeSpan,
      'description': description,
      'characteristics': characteristics,
      'careGuide': careGuide,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory PetBreed.fromMap(Map<String, dynamic> map) {
    return PetBreed(
      name: (map['name'] ?? '') as String,
      animalType: (map['animalType'] ?? '') as String,
      breedGroup:
          (map['breedGroup'] ?? map['breed_group'] ?? 'Unknown') as String,
      size: (map['size'] ?? 'Unknown') as String,
      lifeSpan: (map['lifeSpan'] ?? map['life_span'] ?? 'Unknown') as String,
      description: (map['description'] ?? '') as String,
      characteristics: _parseCharacteristics(map['characteristics']),
      careGuide: _parseCareGuide(map['careGuide'] ?? map['care_guide']),
    );
  }

  factory PetBreed.fromJson(String source) =>
      PetBreed.fromMap(jsonDecode(source) as Map<String, dynamic>);

  static Map<String, int> _parseCharacteristics(dynamic raw) {
    if (raw == null) {
      return const {};
    }
    final Map<String, dynamic> dynamicMap;
    if (raw is Map<String, dynamic>) {
      dynamicMap = raw;
    } else if (raw is Map) {
      dynamicMap = raw.map((key, value) => MapEntry(key.toString(), value));
    } else {
      return const {};
    }

    return dynamicMap.map(
      (key, value) => MapEntry(
        key,
        (value is num) ? value.round() : int.tryParse(value.toString()) ?? 0,
      ),
    );
  }

  static Map<String, String> _parseCareGuide(dynamic raw) {
    if (raw == null) {
      return const {};
    }
    final Map<String, dynamic> dynamicMap;
    if (raw is Map<String, dynamic>) {
      dynamicMap = raw;
    } else if (raw is Map) {
      dynamicMap = raw.map((key, value) => MapEntry(key.toString(), value));
    } else {
      return const {};
    }
    return dynamicMap.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }
}
