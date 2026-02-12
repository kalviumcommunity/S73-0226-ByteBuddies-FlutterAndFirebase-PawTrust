import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pet_model.dart';
import '../services/firestore_service.dart';

class PetsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

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

  /// Add a new pet
  Future<bool> addPet({
    required String ownerId,
    required String name,
    required PetType type,
    String? breed,
    required int age,
    required PetGender gender,
    String? photoUrl,
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

      await _firestoreService.addPet(pet);
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
  Future<bool> updatePet(String petId, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updatePet(petId, data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a pet
  Future<bool> deletePet(String petId) async {
    try {
      await _firestoreService.deletePet(petId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
