import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../models/activity_log_model.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/walks_provider.dart';
import '../providers/request_provider.dart';

class CaregiverJobScreen extends StatefulWidget {
  final RequestModel request;
  final String? walkId;

  const CaregiverJobScreen({super.key, required this.request, this.walkId});

  @override
  State<CaregiverJobScreen> createState() => _CaregiverJobScreenState();
}

class _CaregiverJobScreenState extends State<CaregiverJobScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  bool _isSubmitting = false;
  bool _isCompleting = false;
  DateTime? _walkStartTime;

  @override
  void initState() {
    super.initState();
    _walkStartTime = DateTime.now();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (file != null) {
      setState(() => _images.add(File(file.path)));
    }
  }

  Future<void> _submitLog(ActivityType type) async {
    final auth = context.read<AuthProvider>();
    final activity = context.read<ActivityProvider>();
    if (auth.user == null) return;

    setState(() => _isSubmitting = true);
    final success = await activity.addLog(
      requestId: widget.request.id,
      caregiverId: auth.user!.uid,
      type: type,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      images: _images.isEmpty ? null : _images,
    );

    // Also add to walk session updates if walkId exists
    if (success && widget.walkId != null) {
      final walksProvider = context.read<WalksProvider>();
      final logMessage =
          '${type.name.toUpperCase()}: ${_noteController.text.trim().isNotEmpty ? _noteController.text.trim() : 'Activity logged'}';
      await walksProvider.addWalkUpdate(widget.walkId!, message: logMessage);
    }

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Activity logged')));
      _noteController.clear();
      setState(() => _images.clear());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log activity'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeWalk() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Walk?'),
        content: const Text(
          'Are you sure you want to mark this walk as complete?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCompleting = true);

    final requestProvider = context.read<RequestProvider>();
    bool success = await requestProvider.completeRequest(widget.request.id);

    // Complete walk session if exists
    if (widget.walkId != null) {
      final walksProvider = context.read<WalksProvider>();
      final durationMinutes = _walkStartTime != null
          ? DateTime.now().difference(_walkStartTime!).inMinutes
          : 30;
      await walksProvider.completeWalk(widget.walkId!, durationMinutes);
    }

    setState(() => _isCompleting = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Walk completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requestProvider.errorMessage ?? 'Failed to complete walk',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Job: ${widget.request.petName}'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Walk Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pets, color: green),
                      const SizedBox(width: 8),
                      Text(
                        widget.request.petName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Owner: ${widget.request.ownerName}'),
                  Text(
                    'Scheduled: ${_formatDate(widget.request.requestedDate)} ${widget.request.requestedTime ?? ''}',
                  ),
                  if (widget.request.notes != null &&
                      widget.request.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Notes: ${widget.request.notes}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Activity Logging
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Notes / Log message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Add Photo'),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('${_images.length} photo(s) added')),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitLog(ActivityType.walk),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Log Walk'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitLog(ActivityType.feed),
                  child: const Text('Log Feed'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitLog(ActivityType.medication),
                  child: const Text('Log Medication'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Complete Walk Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isCompleting ? null : _completeWalk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isCompleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isCompleting ? 'Completing...' : 'Complete Walk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Activity Logs
            Expanded(
              child: StreamBuilder(
                stream: context.read<ActivityProvider>().streamLogs(
                  widget.request.id,
                ),
                builder: (context, AsyncSnapshot<List> snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final logs = snap.data as List;
                  if (logs.isEmpty) {
                    return const Center(child: Text('No logs yet'));
                  }
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (ctx, i) {
                      final l = logs[i];
                      return Card(
                        child: ListTile(
                          title: Text(
                            l.type.toString().split('.').last.toUpperCase(),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (l.note != null) Text(l.note),
                              Text(_formatDateTime(l.timestamp)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
