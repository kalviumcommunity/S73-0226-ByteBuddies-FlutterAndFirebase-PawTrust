import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/request_model.dart';

/// Request Service for handling care requests
/// Manages all Firestore operations for requests
class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for requests
  CollectionReference get _requestsCollection => _firestore.collection('requests');

  /// Create a new care request from owner to caregiver
  Future<String?> createRequest({
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
    try {
      final docRef = await _requestsCollection.add({
        'petOwnerId': petOwnerId,
        'caregiverId': caregiverId,
        'ownerName': ownerName,
        'caregiverName': caregiverName,
        'petName': petName,
        'petType': petType,
        'requestedDate': Timestamp.fromDate(requestedDate),
        'requestedTime': requestedTime,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'distance': distance,
        'notes': notes,
      });

      debugPrint('Request created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating request: $e');
      return null;
    }
  }

  /// Get all requests for a specific caregiver (pending requests)
  Future<List<RequestModel>> getCaregiverPendingRequests(String caregiverId) async {
    try {
      final querySnapshot = await _requestsCollection
          .where('caregiverId', isEqualTo: caregiverId)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching caregiver pending requests: $e');
      return [];
    }
  }

  /// Get all accepted/active requests for a specific caregiver
  Future<List<RequestModel>> getCaregiverActiveRequests(String caregiverId) async {
    try {
      final querySnapshot = await _requestsCollection
          .where('caregiverId', isEqualTo: caregiverId)
          .where('status', isEqualTo: 'accepted')
          .orderBy('requestedDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching caregiver active requests: $e');
      return [];
    }
  }

  /// Get all completed requests for a specific caregiver
  Future<List<RequestModel>> getCaregiverCompletedRequests(String caregiverId) async {
    try {
      final querySnapshot = await _requestsCollection
          .where('caregiverId', isEqualTo: caregiverId)
          .where('status', isEqualTo: 'completed')
          .orderBy('requestedDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching caregiver completed requests: $e');
      return [];
    }
  }

  /// Get all requests for a specific owner
  Future<List<RequestModel>> getOwnerRequests(String ownerId) async {
    try {
      final querySnapshot = await _requestsCollection
          .where('petOwnerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching owner requests: $e');
      return [];
    }
  }

  /// Get pending requests for a specific owner
  Future<List<RequestModel>> getOwnerPendingRequests(String ownerId) async {
    try {
      final querySnapshot = await _requestsCollection
          .where('petOwnerId', isEqualTo: ownerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching owner pending requests: $e');
      return [];
    }
  }

  /// Get active/accepted requests for a specific owner
  Future<List<RequestModel>> getOwnerActiveRequests(String ownerId) async {
    try {
      final querySnapshot = await _requestsCollection
          .where('petOwnerId', isEqualTo: ownerId)
          .where('status', isEqualTo: 'accepted')
          .orderBy('requestedDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching owner active requests: $e');
      return [];
    }
  }

  /// Accept a request (caregiver action)
  Future<bool> acceptRequest(String requestId) async {
    try {
      await _requestsCollection.doc(requestId).update({
        'status': 'accepted',
      });
      debugPrint('Request accepted: $requestId');
      return true;
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }

  /// Reject a request (caregiver action)
  Future<bool> rejectRequest(String requestId) async {
    try {
      await _requestsCollection.doc(requestId).update({
        'status': 'rejected',
      });
      debugPrint('Request rejected: $requestId');
      return true;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }

  /// Complete a request (caregiver action)
  Future<bool> completeRequest(String requestId) async {
    try {
      await _requestsCollection.doc(requestId).update({
        'status': 'completed',
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('Request completed: $requestId');
      return true;
    } catch (e) {
      debugPrint('Error completing request: $e');
      return false;
    }
  }

  /// Cancel a request (owner action)
  Future<bool> cancelRequest(String requestId) async {
    try {
      await _requestsCollection.doc(requestId).delete();
      debugPrint('Request cancelled: $requestId');
      return true;
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      return false;
    }
  }

  /// Get a single request by ID
  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _requestsCollection.doc(requestId).get();
      if (doc.exists) {
        return RequestModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching request: $e');
      return null;
    }
  }

  /// Stream of pending requests for a caregiver (real-time updates)
  Stream<List<RequestModel>> streamCaregiverPendingRequests(String caregiverId) {
    return _requestsCollection
        .where('caregiverId', isEqualTo: caregiverId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RequestModel.fromFirestore(doc)).toList());
  }

  /// Stream of active requests for a caregiver
  Stream<List<RequestModel>> streamCaregiverActiveRequests(String caregiverId) {
    return _requestsCollection
        .where('caregiverId', isEqualTo: caregiverId)
        .where('status', isEqualTo: 'accepted')
        .orderBy('requestedDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RequestModel.fromFirestore(doc)).toList());
  }

  /// Stream of all requests for owner
  Stream<List<RequestModel>> streamOwnerRequests(String ownerId) {
    return _requestsCollection
        .where('petOwnerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RequestModel.fromFirestore(doc)).toList());
  }
}
