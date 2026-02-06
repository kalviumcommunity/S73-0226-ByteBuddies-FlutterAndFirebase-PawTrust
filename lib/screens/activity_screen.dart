import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trust = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: Column(
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  trust,
                  trust.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.timeline, color: Colors.white),
              ],
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _activeStatusCard(context),

                  const SizedBox(height: 32),

                  _sectionTitle('Recent Activity'),
                  const SizedBox(height: 12),

                  _emptyHistoryState(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeStatusCard(BuildContext context) {
    final trust = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: trust.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: trust,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Active Walk',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start a walk to see live activity updates.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistoryState(BuildContext context) {
    final trust = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: trust.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 36,
              color: trust,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your pet walks and care sessions will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
