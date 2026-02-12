import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, caregiver }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final String? photoUrl;
  final int completedWalks;
  final int trustScore;
  final DateTime createdAt;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.photoUrl,
    this.completedWalks = 0,
    this.trustScore = 0,
    required this.createdAt,
    this.isVerified = false,
  });

  /// Convert Firestore document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] == 'caregiver' ? UserRole.caregiver : UserRole.owner,
      photoUrl: data['photoUrl'],
      completedWalks: data['completedWalks'] ?? 0,
      trustScore: data['trustScore'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  /// Convert UserModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role == UserRole.caregiver ? 'caregiver' : 'owner',
      'photoUrl': photoUrl,
      'completedWalks': completedWalks,
      'trustScore': trustScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    UserRole? role,
    String? photoUrl,
    int? completedWalks,
    int? trustScore,
    DateTime? createdAt,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      completedWalks: completedWalks ?? this.completedWalks,
      trustScore: trustScore ?? this.trustScore,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
