import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Caregiver Service for handling caregiver operations
/// Fetches caregiver information from Firestore
class CaregiverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for users
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get all available caregivers
  Future<List<UserModel>> getAllCaregivers() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'caregiver')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching caregivers: $e');
      return [];
    }
  }

  /// Get a specific caregiver by ID
  Future<UserModel?> getCaregiverById(String caregiverId) async {
    try {
      final doc = await _usersCollection.doc(caregiverId).get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        // Verify it's a caregiver
        if (user.role == UserRole.caregiver) {
          return user;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching caregiver: $e');
      return null;
    }
  }

  /// Stream of all caregivers (real-time updates)
  Stream<List<UserModel>> streamAllCaregivers() {
    return _usersCollection
        .where('role', isEqualTo: 'caregiver')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  /// Get caregiver count
  Future<int> getCaregiverCount() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'caregiver')
          .get();
      return querySnapshot.size;
    } catch (e) {
      debugPrint('Error getting caregiver count: $e');
      return 0;
    }
  }
}
