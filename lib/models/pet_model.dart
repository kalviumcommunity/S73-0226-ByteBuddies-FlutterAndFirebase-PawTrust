import 'package:cloud_firestore/cloud_firestore.dart';

enum PetType { dog, cat, other }

enum PetGender { male, female }

class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final PetType type;
  final String? breed;
  final int age;
  final PetGender gender;
  final String? photoUrl;
  final DateTime createdAt;

  // Compatibility getters
  String? get imageUrl => photoUrl;
  String get typeDisplayName {
    switch (type) {
      case PetType.dog:
        return 'Dog';
      case PetType.cat:
        return 'Cat';
      case PetType.other:
        return 'Other';
    }
  }

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.breed,
    required this.age,
    required this.gender,
    this.photoUrl,
    required this.createdAt,
  });

  /// Convert Firestore document to PetModel
  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      type: _parseType(data['type']),
      breed: data['breed'],
      age: data['age'] ?? 0,
      gender: data['gender'] == 'female' ? PetGender.female : PetGender.male,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static PetType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'dog':
        return PetType.dog;
      case 'cat':
        return PetType.cat;
      default:
        return PetType.other;
    }
  }

  /// Convert PetModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'type': type.name,
      'breed': breed,
      'age': age,
      'gender': gender.name,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  PetModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    PetType? type,
    String? breed,
    int? age,
    PetGender? gender,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
