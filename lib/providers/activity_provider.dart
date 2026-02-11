import 'dart:io';
import 'package:flutter/material.dart';
import '../models/activity_log_model.dart';
import '../services/activity_service.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityService _service = ActivityService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Add log (uploads images then creates Firestore document)
  Future<bool> addLog({
    required String requestId,
    required String caregiverId,
    required ActivityType type,
    String? note,
    List<File>? images,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _service.addLog(
      requestId: requestId,
      caregiverId: caregiverId,
      type: type,
      note: note,
      images: images,
    );

    _isLoading = false;
    if (!success) _errorMessage = 'Failed to add activity log';
    notifyListeners();
    return success;
  }

  Stream<List<ActivityLog>> streamLogs(String requestId) {
    return _service.streamLogsForRequest(requestId);
  }
}
