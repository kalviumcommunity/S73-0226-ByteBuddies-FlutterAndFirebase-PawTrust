import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/pet_model.dart';
import '../services/firestore_service.dart';

class PetsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _petsSubscription;

  List<PetModel> get pets => _pets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPets => _pets.isNotEmpty;

  /// Initialize pets stream for a user
  void initializePets(String userId) {
    _isLoading = true;
    notifyListeners();

    _petsSubscription?.cancel();
    _petsSubscription = _firestoreService
        .getPetsForUser(userId)
        .listen(
          (pets) {
            _pets = pets;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Upload pet image to Firebase Storage and return the download URL
  Future<String?> _uploadPetImage(String petId, Uint8List imageBytes) async {
    try {
      final ref = _storage.ref().child('pet_images/$petId.jpg');
      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading pet image: $e');
      return null;
    }
  }

  /// Add a new pet
  Future<bool> addPet({
    required String ownerId,
    required String name,
    required PetType type,
    String? breed,
    required int age,
    required PetGender gender,
    String? photoUrl,
    Uint8List? imageBytes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final pet = PetModel(
        id: '', // Will be assigned by Firestore
        ownerId: ownerId,
        name: name,
        type: type,
        breed: breed,
        age: age,
        gender: gender,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestoreService.addPet(pet);

      // Upload image if provided
      if (imageBytes != null) {
        final url = await _uploadPetImage(docRef, imageBytes);
        if (url != null) {
          await _firestoreService.updatePet(docRef, {'photoUrl': url});
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update a pet
  Future<bool> updatePet({
    required String petId,
    String? name,
    PetType? type,
    String? breed,
    int? age,
    PetGender? gender,
    String? photoUrl,
    Uint8List? imageBytes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Upload image first if provided
      if (imageBytes != null) {
        final url = await _uploadPetImage(petId, imageBytes);
        if (url != null) photoUrl = url;
      }

      final Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (type != null) updates['type'] = type.name;
      if (breed != null) updates['breed'] = breed;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender.name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _firestoreService.updatePet(petId, updates);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a pet
  Future<bool> deletePet(String petId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deletePet(petId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _petsSubscription?.cancel();
    super.dispose();
  }
}
