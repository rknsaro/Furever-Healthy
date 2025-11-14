import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet_breed.dart';

class PetGuideOverrides {
  final Map<String, PetBreed> dogs;
  final Map<String, PetBreed> cats;

  const PetGuideOverrides({required this.dogs, required this.cats});

  static const empty = PetGuideOverrides(dogs: {}, cats: {});
}

class PetGuideStorage {
  PetGuideStorage._();

  static final PetGuideStorage instance = PetGuideStorage._();

  final ValueNotifier<int> overridesVersion = ValueNotifier<int>(0);

  static const String _dogOverridesKey = 'pet_guide_dog_overrides';
  static const String _catOverridesKey = 'pet_guide_cat_overrides';

  Future<void> saveBreedOverride(PetBreed breed) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _isDog(breed.animalType) ? _dogOverridesKey : _catOverridesKey;
    final raw = prefs.getString(key);
    final Map<String, dynamic> map = raw != null
        ? jsonDecode(raw) as Map<String, dynamic>
        : {};

    map[breed.name.toLowerCase()] = breed.toMap();

    await prefs.setString(key, jsonEncode(map));
    overridesVersion.value = overridesVersion.value + 1;
  }

  Future<PetGuideOverrides> loadOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final dogRaw = prefs.getString(_dogOverridesKey);
    final catRaw = prefs.getString(_catOverridesKey);

    final dogMap = _decodeOverrides(dogRaw);
    final catMap = _decodeOverrides(catRaw);

    return PetGuideOverrides(dogs: dogMap, cats: catMap);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dogOverridesKey);
    await prefs.remove(_catOverridesKey);
    overridesVersion.value = overridesVersion.value + 1;
  }

  Map<String, PetBreed> _decodeOverrides(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) =>
            MapEntry(key, PetBreed.fromMap(value as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  static bool _isDog(String animalType) =>
      animalType.toLowerCase().trim().startsWith('dog');
}
