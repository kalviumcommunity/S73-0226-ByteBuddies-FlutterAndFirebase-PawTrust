import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/request_model.dart';
import '../models/activity_log_model.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/walks_provider.dart';
import '../providers/request_provider.dart';
import '../widgets/paw_snackbar.dart';
import '../widgets/shimmer_loading.dart';

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
    HapticFeedback.selectionClick();
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
    final walksProvider = context.read<WalksProvider>();
    if (auth.user == null) return;

    HapticFeedback.lightImpact();
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

    if (success && widget.walkId != null) {
      final logMessage =
          '${type.name.toUpperCase()}: ${_noteController.text.trim().isNotEmpty ? _noteController.text.trim() : 'Activity logged'}';
      await walksProvider.addWalkUpdate(widget.walkId!, message: logMessage);
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      PawSnackBar.success(context, 'Activity logged');
      _noteController.clear();
      setState(() => _images.clear());
    } else {
      PawSnackBar.error(context, 'Failed to log activity');
    }
  }

  Future<void> _completeWalk() async {
    final requestProvider = context.read<RequestProvider>();
    final walksProvider = context.read<WalksProvider>();
    final navigator = Navigator.of(context);

    HapticFeedback.mediumImpact();

    final confirm = await PawDialog.confirm(
      context,
      title: 'Complete Walk?',
      message: 'Are you sure you want to mark this walk as complete?',
      confirmLabel: 'Complete',
    );

    if (confirm != true) return;

    setState(() => _isCompleting = true);

    bool success = await requestProvider.completeRequest(widget.request.id);

    if (widget.walkId != null) {
      final durationMinutes = _walkStartTime != null
          ? DateTime.now().difference(_walkStartTime!).inMinutes
          : 30;
      await walksProvider.completeWalk(widget.walkId!, durationMinutes);
    }

    setState(() => _isCompleting = false);

    if (!mounted) return;

    if (success) {
      PawSnackBar.success(context, 'Walk completed successfully!');
      navigator.pop();
    } else {
      PawSnackBar.error(
        context,
        requestProvider.errorMessage ?? 'Failed to complete walk',
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
    return Scaffold(
      backgroundColor: PawTrustApp.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Job: ${widget.request.petName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: PawTrustApp.trustGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Walk Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PawTrustApp.cardWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          color: PawTrustApp.trustGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.request.petName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: PawTrustApp.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Owner: ${widget.request.ownerName}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: PawTrustApp.textSecondary,
                    ),
                  ),
                  Text(
                    'Scheduled: ${_formatDate(widget.request.requestedDate)} ${widget.request.requestedTime ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: PawTrustApp.textSecondary,
                    ),
                  ),
                  if (widget.request.notes != null &&
                      widget.request.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Notes: ${widget.request.notes}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: PawTrustApp.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Activity Logging
            TextFormField(
              controller: _noteController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Notes / Log message',
                labelStyle: GoogleFonts.poppins(
                  color: PawTrustApp.textSecondary,
                ),
                filled: true,
                fillColor: PawTrustApp.cardWhite,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(
                    'Add Photo',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_images.length} photo(s) added',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: PawTrustApp.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLogButton(
                  label: 'Log Walk',
                  icon: Icons.directions_walk_rounded,
                  onTap: () => _submitLog(ActivityType.walk),
                ),
                _buildLogButton(
                  label: 'Log Feed',
                  icon: Icons.restaurant_rounded,
                  onTap: () => _submitLog(ActivityType.feed),
                ),
                _buildLogButton(
                  label: 'Log Medication',
                  icon: Icons.medication_rounded,
                  onTap: () => _submitLog(ActivityType.medication),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Complete Walk Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCompleting ? null : _completeWalk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PawTrustApp.trustGreen,
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
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isCompleting ? 'Completing...' : 'Complete Walk',
                  style: GoogleFonts.poppins(
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
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: ShimmerList(itemCount: 3),
                    );
                  }
                  final logs = snap.data as List;
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        'No logs yet',
                        style: GoogleFonts.poppins(
                          color: PawTrustApp.textSecondary,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (ctx, i) {
                      final l = logs[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: PawTrustApp.cardWhite,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PawTrustApp.primaryBlue.withAlpha(26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getLogIcon(l.type.toString().split('.').last),
                              color: PawTrustApp.primaryBlue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            l.type.toString().split('.').last.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (l.note != null)
                                Text(
                                  l.note,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              Text(
                                _formatDateTime(l.timestamp),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: PawTrustApp.textSecondary,
                                ),
                              ),
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

  Widget _buildLogButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: _isSubmitting ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: PawTrustApp.primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: _isSubmitting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'feed':
        return Icons.restaurant_rounded;
      case 'medication':
        return Icons.medication_rounded;
      default:
        return Icons.note_alt_rounded;
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
