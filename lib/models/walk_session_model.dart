import 'package:cloud_firestore/cloud_firestore.dart';

enum WalkStatus { scheduled, inProgress, completed, cancelled }

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint({required this.latitude, required this.longitude});

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GeoPoint.fromMap(Map<String, dynamic> map) {
    return GeoPoint(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
    );
  }
}

class WalkUpdate {
  final String message;
  final String? photoUrl;
  final GeoPoint? location;
  final DateTime timestamp;

  WalkUpdate({
    required this.message,
    this.photoUrl,
    this.location,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'photoUrl': photoUrl,
      'location': location?.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory WalkUpdate.fromMap(Map<String, dynamic> map) {
    return WalkUpdate(
      message: map['message'] ?? '',
      photoUrl: map['photoUrl'],
      location: map['location'] != null
          ? GeoPoint.fromMap(map['location'])
          : null,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class WalkSessionModel {
  final String id;
  final String petId;
  final String petName;
  final String ownerId;
  final String caregiverId;
  final String caregiverName;
  final WalkStatus status;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<WalkUpdate> updates;
  final int durationMinutes;
  final String? notes;

  WalkSessionModel({
    required this.id,
    required this.petId,
    required this.petName,
    required this.ownerId,
    required this.caregiverId,
    required this.caregiverName,
    required this.status,
    required this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.updates = const [],
    this.durationMinutes = 0,
    this.notes,
  });

  /// Convert Firestore document to WalkSessionModel
  factory WalkSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<WalkUpdate> parseUpdates(List<dynamic>? updates) {
      if (updates == null) return [];
      return updates
          .map((u) => WalkUpdate.fromMap(u as Map<String, dynamic>))
          .toList();
    }

    return WalkSessionModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      petName: data['petName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      caregiverName: data['caregiverName'] ?? '',
      status: _parseStatus(data['status']),
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      updates: parseUpdates(data['updates']),
      durationMinutes: data['durationMinutes'] ?? 0,
      notes: data['notes'],
    );
  }

  static WalkStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'inprogress':
        return WalkStatus.inProgress;
      case 'completed':
        return WalkStatus.completed;
      case 'cancelled':
        return WalkStatus.cancelled;
      default:
        return WalkStatus.scheduled;
    }
  }

  /// Convert WalkSessionModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'petName': petName,
      'ownerId': ownerId,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'status': status.name,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'updates': updates.map((u) => u.toMap()).toList(),
      'durationMinutes': durationMinutes,
      'notes': notes,
    };
  }

  /// Create a copy with updated fields
  WalkSessionModel copyWith({
    String? id,
    String? petId,
    String? petName,
    String? ownerId,
    String? caregiverId,
    String? caregiverName,
    WalkStatus? status,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<WalkUpdate>? updates,
    int? durationMinutes,
    String? notes,
  }) {
    return WalkSessionModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      ownerId: ownerId ?? this.ownerId,
      caregiverId: caregiverId ?? this.caregiverId,
      caregiverName: caregiverName ?? this.caregiverName,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      updates: updates ?? this.updates,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
    );
  }
}
