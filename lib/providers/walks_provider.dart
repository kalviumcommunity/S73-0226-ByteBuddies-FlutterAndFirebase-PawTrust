import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/walk_session_model.dart';
import '../services/firestore_service.dart';

class WalksProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<WalkSessionModel> _walks = [];
  List<WalkSessionModel> _activeWalks = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _walksSubscription;
  StreamSubscription? _activeWalksSubscription;

  List<WalkSessionModel> get walks => _walks;
  List<WalkSessionModel> get activeWalks => _activeWalks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveWalk => _activeWalks.isNotEmpty;

  WalkSessionModel? get currentActiveWalk =>
      _activeWalks.isNotEmpty ? _activeWalks.first : null;

  /// Initialize walks stream for a user
  void initializeWalks(String userId, bool isOwner) {
    _isLoading = true;
    notifyListeners();

    _walksSubscription?.cancel();
    _activeWalksSubscription?.cancel();

    // Subscribe to all walks
    final walksStream = isOwner
        ? _firestoreService.getWalksForOwner(userId)
        : _firestoreService.getWalksForCaregiver(userId);

    _walksSubscription = walksStream.listen(
      (walks) {
        _walks = walks;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    // Subscribe to active walks
    _activeWalksSubscription = _firestoreService
        .getActiveWalks(userId, isOwner)
        .listen(
          (walks) {
            _activeWalks = walks;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  /// Create a new walk session
  Future<String?> createWalkSession({
    required String petId,
    required String petName,
    required String ownerId,
    required String caregiverId,
    required String caregiverName,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final session = WalkSessionModel(
        id: '',
        petId: petId,
        petName: petName,
        ownerId: ownerId,
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        status: WalkStatus.scheduled,
        scheduledAt: scheduledAt,
        notes: notes,
      );

      final id = await _firestoreService.createWalkSession(session);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Start a walk
  Future<bool> startWalk(String walkId) async {
    try {
      await _firestoreService.startWalk(walkId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add update to walk
  Future<bool> addWalkUpdate(
    String walkId, {
    required String message,
    String? photoUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final update = WalkUpdate(
        message: message,
        photoUrl: photoUrl,
        location: latitude != null && longitude != null
            ? GeoPoint(latitude: latitude, longitude: longitude)
            : null,
        timestamp: DateTime.now(),
      );

      await _firestoreService.addWalkUpdate(walkId, update);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Complete a walk
  Future<bool> completeWalk(String walkId, int durationMinutes) async {
    try {
      await _firestoreService.completeWalk(walkId, durationMinutes);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancel a walk
  Future<bool> cancelWalk(String walkId) async {
    try {
      await _firestoreService.cancelWalk(walkId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get completed walks count
  int get completedWalksCount =>
      _walks.where((w) => w.status == WalkStatus.completed).length;

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _walksSubscription?.cancel();
    _activeWalksSubscription?.cancel();
    super.dispose();
  }
}
