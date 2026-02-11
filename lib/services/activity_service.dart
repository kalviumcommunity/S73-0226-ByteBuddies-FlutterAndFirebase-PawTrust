import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_log_model.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _logs => _firestore.collection('activity_logs');

  /// Add a new activity log. Uploads images if provided.
  Future<bool> addLog({
    required String requestId,
    required String caregiverId,
    required ActivityType type,
    String? note,
    List<File>? images,
  }) async {
    try {
      List<String> uploadedUrls = [];
      if (images != null && images.isNotEmpty) {
        for (final file in images) {
          final url = await _uploadImage(file, caregiverId);
          if (url != null) uploadedUrls.add(url);
        }
      }

      final data = {
        'requestId': requestId,
        'caregiverId': caregiverId,
        'type': ActivityLog.typeToString(type),
        'note': note,
        'imageUrls': uploadedUrls,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      };

      await _logs.add(data);
      return true;
    } catch (e) {
      debugPrint('Error adding activity log: $e');
      return false;
    }
  }

  Stream<List<ActivityLog>> streamLogsForRequest(String requestId) {
    return _logs
        .where('requestId', isEqualTo: requestId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ActivityLog.fromFirestore(d)).toList());
  }

  Future<String?> _uploadImage(File file, String caregiverId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('activity_logs').child(caregiverId).child(fileName);
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Failed to upload activity image: $e');
      return null;
    }
  }
}
