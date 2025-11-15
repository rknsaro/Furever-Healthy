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
      characteristics: characteristics ?? this.characteristics,
      careGuide: careGuide ?? this.careGuide,
    );
  }

  Map<String, dynamic> toJson() {
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

  factory PetBreed.fromJson(Map<String, dynamic> json) {
    final characteristicsRaw =
        json['characteristics'] as Map<String, dynamic>? ?? const {};
    final careGuideRaw = json['careGuide'] as Map<String, dynamic>? ?? const {};

    return PetBreed(
      name: json['name'] as String? ?? 'Unknown Breed',
      animalType: json['animalType'] as String? ?? 'Pet',
      breedGroup: json['breedGroup'] as String? ?? 'Unknown',
      size: json['size'] as String? ?? 'Unknown',
      lifeSpan: json['lifeSpan'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      characteristics: characteristicsRaw.map(
        (key, value) => MapEntry(
          key,
          value is int ? value : int.tryParse(value.toString()) ?? 0,
        ),
      ),
      careGuide: careGuideRaw.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  static Map<String, PetBreed> decodeBreedMap(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded.map((key, value) {
      return MapEntry(
        key,
        PetBreed.fromJson(Map<String, dynamic>.from(value as Map)),
      );
    });
  }

  static String encodeBreedMap(Map<String, PetBreed> breeds) {
    final map = breeds.map((key, value) => MapEntry(key, value.toJson()));
    return jsonEncode(map);
  }
}
