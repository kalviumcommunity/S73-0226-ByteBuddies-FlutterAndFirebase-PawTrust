import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity_log_model.dart';

class CaregiverJobScreen extends StatefulWidget {
  final RequestModel request;
  const CaregiverJobScreen({super.key, required this.request});

  @override
  State<CaregiverJobScreen> createState() => _CaregiverJobScreenState();
}

class _CaregiverJobScreenState extends State<CaregiverJobScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
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
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      images: _images.isEmpty ? null : _images,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity logged')));
      _noteController.clear();
      setState(() => _images.clear());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to log activity'), backgroundColor: Colors.red));
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Job: ${widget.request.petName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Owner: ${widget.request.ownerName}'),
            const SizedBox(height: 12),
            Text('Scheduled: ${_formatDate(widget.request.requestedDate)} ${widget.request.requestedTime ?? ''}'),
            const SizedBox(height: 20),

            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Notes / Log message'),
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
                  onPressed: _isSubmitting ? null : () => _submitLog(ActivityType.walk),
                  child: _isSubmitting ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : const Text('Log Walk'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitLog(ActivityType.feed),
                  child: const Text('Log Feed'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitLog(ActivityType.medication),
                  child: const Text('Log Medication'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder(
                stream: context.read<ActivityProvider>().streamLogs(widget.request.id),
                builder: (context, AsyncSnapshot<List> snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final logs = snap.data as List;
                  if (logs.isEmpty) return const Center(child: Text('No logs yet'));
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (ctx, i) {
                      final l = logs[i];
                      return Card(
                        child: ListTile(
                          title: Text(l.type.toString().split('.').last.toUpperCase()),
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
  String _formatDateTime(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}
