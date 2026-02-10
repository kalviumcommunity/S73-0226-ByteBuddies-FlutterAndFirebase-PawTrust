import 'package:flutter/material.dart';
import 'dart:io';
import '../models/pet_model.dart';
import '../services/pet_service.dart';

/// Pet state enum
enum PetStatus {
  initial,
  loading,
  loaded,
  error,
}

/// PetProvider - Manages pet state across the app
/// Uses ChangeNotifier for Provider state management
class PetProvider extends ChangeNotifier {
  final PetService _petService = PetService();

  PetStatus _status = PetStatus.initial;
  List<PetModel> _pets = [];
  String? _errorMessage;

  // Getters
  PetStatus get status => _status;
  List<PetModel> get pets => _pets;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PetStatus.loading;
  bool get hasPets => _pets.isNotEmpty;
  int get petCount => _pets.length;

  /// Fetch pets for a specific owner
  Future<void> fetchPets(String ownerId) async {
    _status = PetStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _pets = await _petService.getPetsByOwnerId(ownerId);
      _status = PetStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = PetStatus.error;
      _errorMessage = 'Failed to load pets: $e';
      debugPrint('Error fetching pets: $e');
    }
    notifyListeners();
  }

  /// Add a new pet
  Future<bool> addPet({
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
    _status = PetStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _petService.addPet(
      name: name,
      type: type,
      breed: breed,
      age: age,
      gender: gender,
      ownerId: ownerId,
      imageFile: imageFile,
      medicalNotes: medicalNotes,
      weight: weight,
    );

    if (result.success && result.pet != null) {
      _pets.insert(0, result.pet!); // Add to beginning of list
      _status = PetStatus.loaded;
      notifyListeners();
      return true;
    } else {
      _status = PetStatus.error;
      _errorMessage = result.errorMessage ?? 'Failed to add pet';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing pet
  Future<bool> updatePet({
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
    _status = PetStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _petService.updatePet(
      petId: petId,
      name: name,
      type: type,
      breed: breed,
      age: age,
      gender: gender,
      imageFile: imageFile,
      existingImageUrl: existingImageUrl,
      medicalNotes: medicalNotes,
      weight: weight,
    );

    if (result.success && result.pet != null) {
      // Update pet in list
      final index = _pets.indexWhere((p) => p.id == petId);
      if (index != -1) {
        _pets[index] = result.pet!;
      }
      _status = PetStatus.loaded;
      notifyListeners();
      return true;
    } else {
      _status = PetStatus.error;
      _errorMessage = result.errorMessage ?? 'Failed to update pet';
      notifyListeners();
      return false;
    }
  }

  /// Delete a pet
  Future<bool> deletePet(String petId) async {
    _status = PetStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final success = await _petService.deletePet(petId);

    if (success) {
      _pets.removeWhere((p) => p.id == petId);
      _status = PetStatus.loaded;
      notifyListeners();
      return true;
    } else {
      _status = PetStatus.error;
      _errorMessage = 'Failed to delete pet';
      notifyListeners();
      return false;
    }
  }

  /// Get a specific pet by ID
  PetModel? getPetById(String petId) {
    try {
      return _pets.firstWhere((p) => p.id == petId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    if (_status == PetStatus.error) {
      _status = _pets.isEmpty ? PetStatus.initial : PetStatus.loaded;
    }
    notifyListeners();
  }

  /// Clear all pets (useful for logout)
  void clear() {
    _pets = [];
    _status = PetStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
