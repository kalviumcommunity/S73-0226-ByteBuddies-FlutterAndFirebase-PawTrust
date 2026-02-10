import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for pet types
enum PetType { dog, cat, bird, rabbit, other }

/// Enum for pet gender
enum PetGender { male, female }

/// Pet model for PawTrust
/// Stores pet information including owner details
class PetModel {
  final String id;
  final String name;
  final PetType type;
  final String? breed;
  final int age; // in years
  final PetGender gender;
  final String ownerId;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? medicalNotes;
  final double? weight; // in kg

  PetModel({
    required this.id,
    required this.name,
    required this.type,
    this.breed,
    required this.age,
    required this.gender,
    required this.ownerId,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.medicalNotes,
    this.weight,
  });

  /// Create PetModel from Firestore document
  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: _petTypeFromString(data['type'] ?? 'other'),
      breed: data['breed'],
      age: data['age'] ?? 0,
      gender: data['gender'] == 'male' ? PetGender.male : PetGender.female,
      ownerId: data['ownerId'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      medicalNotes: data['medicalNotes'],
      weight: data['weight']?.toDouble(),
    );
  }

  /// Convert PetModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': _petTypeToString(type),
      'breed': breed,
      'age': age,
      'gender': gender == PetGender.male ? 'male' : 'female',
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'medicalNotes': medicalNotes,
      'weight': weight,
    };
  }

  /// Create a copy with updated fields
  PetModel copyWith({
    String? id,
    String? name,
    PetType? type,
    String? breed,
    int? age,
    PetGender? gender,
    String? ownerId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? medicalNotes,
    double? weight,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      ownerId: ownerId ?? this.ownerId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      weight: weight ?? this.weight,
    );
  }

  /// Helper to convert PetType enum to string
  static String _petTypeToString(PetType type) {
    switch (type) {
      case PetType.dog:
        return 'dog';
      case PetType.cat:
        return 'cat';
      case PetType.bird:
        return 'bird';
      case PetType.rabbit:
        return 'rabbit';
      case PetType.other:
        return 'other';
    }
  }

  /// Helper to convert string to PetType enum
  static PetType _petTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return PetType.dog;
      case 'cat':
        return PetType.cat;
      case 'bird':
        return PetType.bird;
      case 'rabbit':
        return PetType.rabbit;
      default:
        return PetType.other;
    }
  }

  /// Get display name for pet type
  String get typeDisplayName {
    switch (type) {
      case PetType.dog:
        return 'Dog';
      case PetType.cat:
        return 'Cat';
      case PetType.bird:
        return 'Bird';
      case PetType.rabbit:
        return 'Rabbit';
      case PetType.other:
        return 'Other';
    }
  }

  /// Get display name for gender
  String get genderDisplayName {
    return gender == PetGender.male ? 'Male' : 'Female';
  }

  @override
  String toString() {
    return 'PetModel(id: $id, name: $name, type: $type, breed: $breed, age: $age, gender: $gender, ownerId: $ownerId)';
  }
}
