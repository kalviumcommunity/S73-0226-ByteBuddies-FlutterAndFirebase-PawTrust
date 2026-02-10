import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/pet_model.dart';

/// Result class for Pet operations
class PetResult {
  final bool success;
  final String? errorMessage;
  final PetModel? pet;

  PetResult({required this.success, this.errorMessage, this.pet});

  factory PetResult.success(PetModel pet) {
    return PetResult(success: true, pet: pet);
  }

  factory PetResult.failure(String message) {
    return PetResult(success: false, errorMessage: message);
  }
}

/// Pet Service for PawTrust
/// Handles all Firestore pet operations and image uploads
class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Collection reference for pets
  CollectionReference get _petsCollection => _firestore.collection('pets');

  /// Add a new pet to Firestore
  /// Returns PetResult with success status and pet data or error message
  Future<PetResult> addPet({
    required String name,
    required PetType type,
    String? breed,
    required int age,
    required PetGender gender,
    required String ownerId,
    File? imageFile,
    String? medicalNotes,
    double? weight,
  }) async {
    try {
      // Validate required fields
      if (name.trim().isEmpty) {
        return PetResult.failure('Pet name is required');
      }
      if (age < 0 || age > 50) {
        return PetResult.failure('Please enter a valid age (0-50 years)');
      }
      if (ownerId.trim().isEmpty) {
        return PetResult.failure('Owner ID is required');
      }

      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        final uploadResult = await _uploadPetImage(imageFile, ownerId);
        if (uploadResult.success) {
          imageUrl = uploadResult.url;
        } else {
          // Continue without image if upload fails
          debugPrint('Image upload failed: ${uploadResult.errorMessage}');
        }
      }

      // Create pet model
      final petModel = PetModel(
        id: '', // Will be set by Firestore
        name: name.trim(),
        type: type,
        breed: breed?.trim(),
        age: age,
        gender: gender,
        ownerId: ownerId,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        medicalNotes: medicalNotes?.trim(),
        weight: weight,
      );

      // Add to Firestore
      final docRef = await _petsCollection.add(petModel.toFirestore());

      // Fetch the created pet with ID
      final createdPet = petModel.copyWith(id: docRef.id);

      debugPrint('Pet added successfully: ${createdPet.id}');
      return PetResult.success(createdPet);
    } catch (e) {
      debugPrint('Error adding pet: $e');
      return PetResult.failure('Failed to add pet: $e');
    }
  }

  /// Get all pets for a specific owner
  Future<List<PetModel>> getPetsByOwnerId(String ownerId) async {
    try {
      final querySnapshot = await _petsCollection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      return [];
    }
  }

  /// Get a single pet by ID
  Future<PetModel?> getPetById(String petId) async {
    try {
      final doc = await _petsCollection.doc(petId).get();
      if (doc.exists) {
        return PetModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching pet: $e');
      return null;
    }
  }

  /// Update an existing pet
  Future<PetResult> updatePet({
    required String petId,
    String? name,
    PetType? type,
    String? breed,
    int? age,
    PetGender? gender,
    File? imageFile,
    String? existingImageUrl,
    String? medicalNotes,
    double? weight,
  }) async {
    try {
      // Validate pet exists
      final existingPet = await getPetById(petId);
      if (existingPet == null) {
        return PetResult.failure('Pet not found');
      }

      // Validate fields if provided
      if (name != null && name.trim().isEmpty) {
        return PetResult.failure('Pet name cannot be empty');
      }
      if (age != null && (age < 0 || age > 50)) {
        return PetResult.failure('Please enter a valid age (0-50 years)');
      }

      String? imageUrl = existingImageUrl;

      // Upload new image if provided
      if (imageFile != null) {
        // Delete old image if exists
        if (existingPet.imageUrl != null) {
          await _deletePetImage(existingPet.imageUrl!);
        }

        final uploadResult =
            await _uploadPetImage(imageFile, existingPet.ownerId);
        if (uploadResult.success) {
          imageUrl = uploadResult.url;
        }
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updateData['name'] = name.trim();
      if (type != null) {
        updateData['type'] = PetModel(
          id: '',
          name: '',
          type: type,
          age: 0,
          gender: PetGender.male,
          ownerId: '',
          createdAt: DateTime.now(),
        ).toFirestore()['type'];
      }
      if (breed != null) updateData['breed'] = breed.trim();
      if (age != null) updateData['age'] = age;
      if (gender != null) {
        updateData['gender'] = gender == PetGender.male ? 'male' : 'female';
      }
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (medicalNotes != null) updateData['medicalNotes'] = medicalNotes.trim();
      if (weight != null) updateData['weight'] = weight;

      // Update in Firestore
      await _petsCollection.doc(petId).update(updateData);

      // Fetch updated pet
      final updatedPet = await getPetById(petId);
      if (updatedPet != null) {
        debugPrint('Pet updated successfully: $petId');
        return PetResult.success(updatedPet);
      }

      return PetResult.failure('Failed to fetch updated pet');
    } catch (e) {
      debugPrint('Error updating pet: $e');
      return PetResult.failure('Failed to update pet: $e');
    }
  }

  /// Delete a pet
  Future<bool> deletePet(String petId) async {
    try {
      // Get pet to check for image
      final pet = await getPetById(petId);
      if (pet == null) {
        debugPrint('Pet not found: $petId');
        return false;
      }

      // Delete image if exists
      if (pet.imageUrl != null) {
        await _deletePetImage(pet.imageUrl!);
      }

      // Delete from Firestore
      await _petsCollection.doc(petId).delete();

      debugPrint('Pet deleted successfully: $petId');
      return true;
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      return false;
    }
  }

  /// Stream of pets for a specific owner (real-time updates)
  Stream<List<PetModel>> streamPetsByOwnerId(String ownerId) {
    return _petsCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PetModel.fromFirestore(doc)).toList());
  }

  /// Get total pet count for an owner
  Future<int> getPetCount(String ownerId) async {
    try {
      final querySnapshot =
          await _petsCollection.where('ownerId', isEqualTo: ownerId).get();
      return querySnapshot.size;
    } catch (e) {
      debugPrint('Error getting pet count: $e');
      return 0;
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  /// Upload pet image to Firebase Storage
  Future<({bool success, String? url, String? errorMessage})> _uploadPetImage(
      File imageFile, String ownerId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          _storage.ref().child('pets').child(ownerId).child(fileName);

      // Upload file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('Image uploaded successfully: $downloadUrl');
      return (success: true, url: downloadUrl, errorMessage: null);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return (
        success: false,
        url: null,
        errorMessage: 'Failed to upload image: $e'
      );
    }
  }

  /// Delete pet image from Firebase Storage
  Future<void> _deletePetImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('Image deleted successfully: $imageUrl');
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Don't throw error, just log it
    }
  }
}
