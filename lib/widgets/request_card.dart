import 'package:flutter/material.dart';
import '../models/request_model.dart';
import 'status_badge.dart';

class CaregiverRequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isLoading;

  const CaregiverRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = theme.colorScheme.tertiary;
    final dateStr = _formatDate(request.requestedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with pet and owner info
          Row(
            children: [
              // Pet avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPetIcon(request.petType),
                  color: green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.petName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.petType.capitalize()} • From ${request.ownerName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),

          // Date and distance info
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.black45,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ),
              if (request.distance != null) ...[
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  '${request.distance!.toStringAsFixed(1)} km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF2728C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPetIcon(String petType) {
    switch (petType.toLowerCase()) {
      case 'cat':
        return Icons.pets_rounded;
      case 'dog':
      default:
        return Icons.pets_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

class OwnerRequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onCancel;
  final bool isLoading;

  const OwnerRequestCard({
    super.key,
    required this.request,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dateStr = _formatDate(request.requestedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with caregiver name and status
          Row(
            children: [
              // Caregiver avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.caregiverName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.petName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: request.status, isCompact: true),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),

          // Date info
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.black45,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          // Show action button only if pending
          if (request.status == RequestStatus.pending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF2728C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Cancel Request'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
