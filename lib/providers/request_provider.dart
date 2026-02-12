import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/request_service.dart';

/// Request Provider - Manages request state across the app
/// Uses ChangeNotifier for Provider state management
class RequestProvider extends ChangeNotifier {
  final RequestService _requestService = RequestService();

  // Caregiver state
  List<RequestModel> _pendingRequests = [];
  List<RequestModel> _activeRequests = [];
  List<RequestModel> _completedRequests = [];

  // Owner state
  List<RequestModel> _ownerPendingRequests = [];
  List<RequestModel> _ownerActiveRequests = [];
  List<RequestModel> _ownerCompletedRequests = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters for Caregiver
  List<RequestModel> get pendingRequests => _pendingRequests;
  List<RequestModel> get activeRequests => _activeRequests;
  List<RequestModel> get completedRequests => _completedRequests;

  // Getters for Owner
  List<RequestModel> get ownerPendingRequests => _ownerPendingRequests;
  List<RequestModel> get ownerActiveRequests => _ownerActiveRequests;
  List<RequestModel> get ownerCompletedRequests => _ownerCompletedRequests;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ========== CAREGIVER OPERATIONS ==========

  /// Fetch pending requests for caregiver
  Future<void> fetchCaregiverPendingRequests(String caregiverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingRequests =
          await _requestService.getCaregiverPendingRequests(caregiverId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load pending requests: $e';
      debugPrint('Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch active requests for caregiver
  Future<void> fetchCaregiverActiveRequests(String caregiverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeRequests =
          await _requestService.getCaregiverActiveRequests(caregiverId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load active requests: $e';
      debugPrint('Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch completed requests for caregiver
  Future<void> fetchCaregiverCompletedRequests(String caregiverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _completedRequests =
          await _requestService.getCaregiverCompletedRequests(caregiverId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load completed requests: $e';
      debugPrint('Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Accept a caregiver request
  Future<bool> acceptRequest(String requestId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _requestService.acceptRequest(requestId);

    if (success) {
      // Move request from pending to active
      final request = _pendingRequests.firstWhere(
        (r) => r.id == requestId,
        orElse: () => RequestModel(
          id: '',
          petOwnerId: '',
          caregiverId: '',
          petName: '',
          petType: '',
          ownerName: '',
          caregiverName: '',
          requestedDate: DateTime.now(),
          status: RequestStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      if (request.id.isNotEmpty) {
        _pendingRequests.removeWhere((r) => r.id == requestId);
        _activeRequests.insert(0, request.copyWith(status: RequestStatus.accepted));
      }
      _errorMessage = null;
    } else {
      _errorMessage = 'Failed to accept request';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Reject a caregiver request
  Future<bool> rejectRequest(String requestId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _requestService.rejectRequest(requestId);

    if (success) {
      _pendingRequests.removeWhere((r) => r.id == requestId);
      _errorMessage = null;
    } else {
      _errorMessage = 'Failed to reject request';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Complete a request
  Future<bool> completeRequest(String requestId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _requestService.completeRequest(requestId);

    if (success) {
      final request = _activeRequests.firstWhere(
        (r) => r.id == requestId,
        orElse: () => RequestModel(
          id: '',
          petOwnerId: '',
          caregiverId: '',
          petName: '',
          petType: '',
          ownerName: '',
          caregiverName: '',
          requestedDate: DateTime.now(),
          status: RequestStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      if (request.id.isNotEmpty) {
        _activeRequests.removeWhere((r) => r.id == requestId);
        _completedRequests
            .insert(0, request.copyWith(status: RequestStatus.completed));
      }
      _errorMessage = null;
    } else {
      _errorMessage = 'Failed to complete request';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // ========== OWNER OPERATIONS ==========

  /// Create a new request from owner to caregiver
  Future<bool> createRequest({
    required String petOwnerId,
    required String caregiverId,
    required String ownerName,
    required String caregiverName,
    required String petName,
    required String petType,
    required DateTime requestedDate,
    String? requestedTime,
    String? notes,
    double? distance,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final requestId = await _requestService.createRequest(
      petOwnerId: petOwnerId,
      caregiverId: caregiverId,
      ownerName: ownerName,
      caregiverName: caregiverName,
      petName: petName,
      petType: petType,
      requestedDate: requestedDate,
      requestedTime: requestedTime,
      notes: notes,
      distance: distance,
    );

    _isLoading = false;

    if (requestId != null) {
      // Fetch updated owner requests
      await fetchOwnerRequests(petOwnerId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Failed to create request';
      notifyListeners();
      return false;
    }
  }

  /// Fetch all requests for owner
  Future<void> fetchOwnerRequests(String ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allRequests = await _requestService.getOwnerRequests(ownerId);
      _ownerPendingRequests =
          allRequests.where((r) => r.status == RequestStatus.pending).toList();
      _ownerActiveRequests =
          allRequests.where((r) => r.status == RequestStatus.accepted).toList();
      _ownerCompletedRequests =
          allRequests.where((r) => r.status == RequestStatus.completed).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load requests: $e';
      debugPrint('Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Cancel a request (owner action)
  Future<bool> cancelRequest(String requestId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _requestService.cancelRequest(requestId);

    if (success) {
      _ownerPendingRequests.removeWhere((r) => r.id == requestId);
      _errorMessage = null;
    } else {
      _errorMessage = 'Failed to cancel request';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (useful for logout)
  void clear() {
    _pendingRequests = [];
    _activeRequests = [];
    _completedRequests = [];
    _ownerPendingRequests = [];
    _ownerActiveRequests = [];
    _ownerCompletedRequests = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
