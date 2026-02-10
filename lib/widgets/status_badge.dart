import 'package:flutter/material.dart';
import '../models/request_model.dart';

class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  Color _getStatusColor() {
    switch (status) {
      case RequestStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case RequestStatus.accepted:
        return const Color(0xFF10B981); // Green
      case RequestStatus.rejected:
        return const Color(0xFEF2728C); // Red
      case RequestStatus.completed:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.completed:
        return 'Completed';
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case RequestStatus.pending:
        return Icons.schedule_rounded;
      case RequestStatus.accepted:
        return Icons.check_circle_rounded;
      case RequestStatus.rejected:
        return Icons.cancel_rounded;
      case RequestStatus.completed:
        return Icons.verified_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor();
    final label = _getStatusLabel();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
