import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing the user role in the app
enum UserRole { owner, caregiver }

/// User model for PawTrust
/// Stores user profile data including their role (Owner or Caregiver)
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;
  final String? profileImageUrl;
  final bool onboardingComplete;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.profileImageUrl,
    this.onboardingComplete = false,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] == 'caregiver' ? UserRole.caregiver : UserRole.owner,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: data['profileImageUrl'],
      onboardingComplete: data['onboardingComplete'] ?? false,
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role == UserRole.caregiver ? 'caregiver' : 'owner',
      'createdAt': Timestamp.fromDate(createdAt),
      'profileImageUrl': profileImageUrl,
      'onboardingComplete': onboardingComplete,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
    String? profileImageUrl,
    bool? onboardingComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, fullName: $fullName, role: $role, onboardingComplete: $onboardingComplete)';
  }
}
