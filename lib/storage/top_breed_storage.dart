
import 'package:shared_preferences/shared_preferences.dart';

import '../models/breed_profile.dart';

class TopBreedStorage {
  static final TopBreedStorage _instance = TopBreedStorage._internal();

  factory TopBreedStorage() => _instance;

  TopBreedStorage._internal();

  static const String _dogKey = 'top_breeds_dog';
  static const String _catKey = 'top_breeds_cat';

  Future<Map<String, PetBreed>> loadDogBreeds() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_dogKey);
    return PetBreed.decodeBreedMap(data);
  }

  Future<Map<String, PetBreed>> loadCatBreeds() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_catKey);
    return PetBreed.decodeBreedMap(data);
  }

  Future<void> saveBreed({
    required String species,
    required String canonicalKey,
    required PetBreed breed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = species.toLowerCase() == 'cat' ? _catKey : _dogKey;
    final existing = PetBreed.decodeBreedMap(prefs.getString(key));
    existing[canonicalKey] = breed;
    await prefs.setString(key, PetBreed.encodeBreedMap(existing));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dogKey);
    await prefs.remove(_catKey);
  }
}
