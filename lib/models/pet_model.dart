// lib/models/pet_model.dart
import 'package:flutter/material.dart';

class Pet {
  String name;
  String breed;
  String gender;
  String age;
  String height;
  String weight;
  String imageAsset; // This will store the path to the pet's image

  Pet({
    required this.name,
    required this.breed,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.imageAsset,
  });

  // Optional: A copyWith method for easier immutability when updating
  Pet copyWith({
    String? name,
    String? breed,
    String? gender,
    String? age,
    String? height,
    String? weight,
    String? imageAsset,
  }) {
    return Pet(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }
}