import 'package:cloud_firestore/cloud_firestore.dart';

/// Request status enum
enum RequestStatus { pending, accepted, rejected, completed }

/// Request model for care/walk requests
class RequestModel {
  final String id;
  final String petOwnerId;
  final String caregiverId;
  final String petName;
  final String petType; // dog, cat, other
  final String ownerName;
  final String caregiverName;
  final DateTime requestedDate;
  final String? requestedTime;
  final RequestStatus status;
  final DateTime createdAt;
  final double? distance;
  final String? notes;

  RequestModel({
    required this.id,
    required this.petOwnerId,
    required this.caregiverId,
    required this.petName,
    required this.petType,
    required this.ownerName,
    required this.caregiverName,
    required this.requestedDate,
    this.requestedTime,
    required this.status,
    required this.createdAt,
    this.distance,
    this.notes,
  });

  /// Create RequestModel from Firestore document
  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      petOwnerId: data['petOwnerId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      petName: data['petName'] ?? '',
      petType: data['petType'] ?? 'dog',
      ownerName: data['ownerName'] ?? '',
      caregiverName: data['caregiverName'] ?? '',
      requestedDate: (data['requestedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requestedTime: data['requestedTime'],
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      distance: (data['distance'] as num?)?.toDouble(),
      notes: data['notes'],
    );
  }

  /// Convert RequestModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'petOwnerId': petOwnerId,
      'caregiverId': caregiverId,
      'petName': petName,
      'petType': petType,
      'ownerName': ownerName,
      'caregiverName': caregiverName,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'requestedTime': requestedTime,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'distance': distance,
      'notes': notes,
    };
  }

  /// Helper to parse status from string
  static RequestStatus _parseStatus(String? value) {
    switch (value) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'rejected':
        return RequestStatus.rejected;
      case 'completed':
        return RequestStatus.completed;
      default:
        return RequestStatus.pending;
    }
  }

  /// Helper to convert status to string
  static String _statusToString(RequestStatus status) {
    return status.toString().split('.').last;
  }

  /// Copy with method for immutability
  RequestModel copyWith({
    String? id,
    String? petOwnerId,
    String? caregiverId,
    String? petName,
    String? petType,
    String? ownerName,
    String? caregiverName,
    DateTime? requestedDate,
    String? requestedTime,
    RequestStatus? status,
    DateTime? createdAt,
    double? distance,
    String? notes,
  }) {
    return RequestModel(
      id: id ?? this.id,
      petOwnerId: petOwnerId ?? this.petOwnerId,
      caregiverId: caregiverId ?? this.caregiverId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      ownerName: ownerName ?? this.ownerName,
      caregiverName: caregiverName ?? this.caregiverName,
      requestedDate: requestedDate ?? this.requestedDate,
      requestedTime: requestedTime ?? this.requestedTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      distance: distance ?? this.distance,
      notes: notes ?? this.notes,
    );
  }
}
