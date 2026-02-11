import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { walk, feed, medication, custom }

class ActivityLog {
  final String id;
  final String requestId;
  final String caregiverId;
  final ActivityType type;
  final String? note;
  final List<String>? imageUrls;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.requestId,
    required this.caregiverId,
    required this.type,
    this.note,
    this.imageUrls,
    required this.timestamp,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLog(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      type: typeFromString(data['type'] ?? 'custom'),
      note: data['note'],
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'caregiverId': caregiverId,
      'type': typeToString(type),
      'note': note,
      'imageUrls': imageUrls,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static ActivityType typeFromString(String s) {
    switch (s) {
      case 'walk':
        return ActivityType.walk;
      case 'feed':
        return ActivityType.feed;
      case 'medication':
        return ActivityType.medication;
      default:
        return ActivityType.custom;
    }
  }

  static String typeToString(ActivityType t) {
    switch (t) {
      case ActivityType.walk:
        return 'walk';
      case ActivityType.feed:
        return 'feed';
      case ActivityType.medication:
        return 'medication';
      default:
        return 'custom';
    }
  }
}
