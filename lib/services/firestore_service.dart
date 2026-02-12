import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';
import '../models/walk_session_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== PET OPERATIONS ====================

  /// Add a new pet
  Future<String> addPet(PetModel pet) async {
    final docRef = await _firestore.collection('pets').add(pet.toFirestore());
    return docRef.id;
  }

  /// Get all pets for a user
  Stream<List<PetModel>> getPetsForUser(String userId) {
    return _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final pets = snapshot.docs
              .map((doc) => PetModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid needing composite index
          pets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return pets;
        });
  }

  /// Get a single pet by ID
  Future<PetModel?> getPet(String petId) async {
    final doc = await _firestore.collection('pets').doc(petId).get();
    if (doc.exists) {
      return PetModel.fromFirestore(doc);
    }
    return null;
  }

  /// Update a pet
  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    await _firestore.collection('pets').doc(petId).update(data);
  }

  /// Delete a pet
  Future<void> deletePet(String petId) async {
    await _firestore.collection('pets').doc(petId).delete();
  }

  // ==================== WALK SESSION OPERATIONS ====================

  /// Create a new walk session
  Future<String> createWalkSession(WalkSessionModel session) async {
    final docRef = await _firestore
        .collection('walks')
        .add(session.toFirestore());
    return docRef.id;
  }

  /// Get walk sessions for an owner (to monitor their pets)
  Stream<List<WalkSessionModel>> getWalksForOwner(String ownerId) {
    return _firestore
        .collection('walks')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final walks = snapshot.docs
              .map((doc) => WalkSessionModel.fromFirestore(doc))
              .toList();
          walks.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          return walks;
        });
  }

  /// Get walk sessions for a caregiver
  Stream<List<WalkSessionModel>> getWalksForCaregiver(String caregiverId) {
    return _firestore
        .collection('walks')
        .where('caregiverId', isEqualTo: caregiverId)
        .snapshots()
        .map((snapshot) {
          final walks = snapshot.docs
              .map((doc) => WalkSessionModel.fromFirestore(doc))
              .toList();
          walks.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          return walks;
        });
  }

  /// Get active walks (in progress)
  Stream<List<WalkSessionModel>> getActiveWalks(String userId, bool isOwner) {
    final field = isOwner ? 'ownerId' : 'caregiverId';
    return _firestore
        .collection('walks')
        .where(field, isEqualTo: userId)
        .where('status', isEqualTo: 'inProgress')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WalkSessionModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Start a walk session
  Future<void> startWalk(String walkId) async {
    await _firestore.collection('walks').doc(walkId).update({
      'status': 'inProgress',
      'startedAt': Timestamp.now(),
    });
  }

  /// Add update to a walk session
  Future<void> addWalkUpdate(String walkId, WalkUpdate update) async {
    await _firestore.collection('walks').doc(walkId).update({
      'updates': FieldValue.arrayUnion([update.toMap()]),
    });
  }

  /// Complete a walk session
  Future<void> completeWalk(String walkId, int durationMinutes) async {
    await _firestore.collection('walks').doc(walkId).update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'durationMinutes': durationMinutes,
    });

    // Update caregiver's completed walks count
    final walkDoc = await _firestore.collection('walks').doc(walkId).get();
    if (walkDoc.exists) {
      final caregiverId = walkDoc.data()?['caregiverId'];
      if (caregiverId != null) {
        await _firestore.collection('users').doc(caregiverId).update({
          'completedWalks': FieldValue.increment(1),
        });
      }
    }
  }

  /// Cancel a walk session
  Future<void> cancelWalk(String walkId) async {
    await _firestore.collection('walks').doc(walkId).update({
      'status': 'cancelled',
    });
  }

  // ==================== CAREGIVER OPERATIONS ====================

  /// Get all verified caregivers
  Stream<List<UserModel>> getCaregivers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'caregiver')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  /// Get caregiver by ID
  Future<UserModel?> getCaregiver(String caregiverId) async {
    final doc = await _firestore.collection('users').doc(caregiverId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // ==================== TRUST INDICATORS ====================

  /// Calculate trust score based on completed walks
  int calculateTrustScore(int completedWalks) {
    if (completedWalks >= 50) return 100;
    if (completedWalks >= 25) return 90;
    if (completedWalks >= 10) return 75;
    if (completedWalks >= 5) return 50;
    if (completedWalks >= 1) return 25;
    return 0;
  }
}
