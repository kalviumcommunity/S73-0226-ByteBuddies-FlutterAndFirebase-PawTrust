import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../providers/walks_provider.dart';
import '../widgets/request_card.dart';
import '../widgets/status_badge.dart';
import 'caregiver_job_screen.dart';

class RoleBasedDashboard extends StatefulWidget {
  const RoleBasedDashboard({super.key});

  @override
  State<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<RoleBasedDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _tabCount = 3;
  bool _didInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryLoadRequests();
    });
  }

  void _tryLoadRequests() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null && !_didInitialLoad) {
      _didInitialLoad = true;
      _loadRequests();
    }
  }

  Future<void> _loadRequests() async {
    final authProvider = context.read<AuthProvider>();
    final requestProvider = context.read<RequestProvider>();

    if (authProvider.user != null) {
      final isCaregiver = authProvider.user!.role == UserRole.caregiver;

      if (isCaregiver) {
        await Future.wait([
          requestProvider.fetchCaregiverPendingRequests(authProvider.user!.uid),
          requestProvider.fetchCaregiverActiveRequests(authProvider.user!.uid),
          requestProvider.fetchCaregiverCompletedRequests(
            authProvider.user!.uid,
          ),
        ]);
      } else {
        await requestProvider.fetchOwnerRequests(authProvider.user!.uid);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Trigger load when user becomes available (handles async profile loading)
    if (user != null && !_didInitialLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryLoadRequests();
      });
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine if caregiver or owner
    final isCaregiver = user.role == UserRole.caregiver;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          _buildHeader(context, user, isCaregiver),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.secondary,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              tabs: isCaregiver
                  ? [
                      const Tab(text: 'Requests'),
                      const Tab(text: 'Active Jobs'),
                      const Tab(text: 'History'),
                    ]
                  : [
                      const Tab(text: 'My Requests'),
                      const Tab(text: 'Active Walk'),
                      const Tab(text: 'History'),
                    ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: isCaregiver
                  ? [
                      _buildCaregiverRequestsTab(),
                      _buildActiveJobsTab(),
                      _buildCompletedJobsTab(),
                    ]
                  : [
                      _buildMyRequestsTab(),
                      _buildActiveWalkTab(),
                      _buildOwnerHistoryTab(),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, bool isCaregiver) {
    final theme = Theme.of(context);
    final headerColor = isCaregiver
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerColor, headerColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCaregiver ? 'Care Requests' : 'Your Walks',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCaregiver ? 'Manage your jobs' : 'Manage your pets',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCaregiver ? Icons.assignment_rounded : Icons.pets_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CAREGIVER TABS
  Widget _buildCaregiverRequestsTab() {
    final requestProvider = context.watch<RequestProvider>();
    final pendingRequests = requestProvider.pendingRequests;

    if (requestProvider.isLoading && pendingRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pendingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: _buildEmptyState(
                icon: Icons.inbox_rounded,
                title: 'No Requests',
                subtitle: 'You\'ll see incoming care requests here',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: pendingRequests
            .map(
              (request) => CaregiverRequestCard(
                request: request,
                onAccept: () => _handleAcceptRequest(request),
                onReject: () => _handleRejectRequest(request),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActiveJobsTab() {
    final requestProvider = context.watch<RequestProvider>();
    final activeJobs = requestProvider.activeRequests;

    if (requestProvider.isLoading && activeJobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activeJobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: _buildEmptyState(
                icon: Icons.work_outline_rounded,
                title: 'No Active Jobs',
                subtitle: 'Accept requests to see active jobs here',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: activeJobs.map((job) => _buildActiveJobCard(job)).toList(),
      ),
    );
  }

  Widget _buildCompletedJobsTab() {
    final requestProvider = context.watch<RequestProvider>();
    final completedJobs = requestProvider.completedRequests;

    if (requestProvider.isLoading && completedJobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (completedJobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: _buildEmptyState(
                icon: Icons.history_rounded,
                title: 'No Completed Jobs',
                subtitle: 'Your completed jobs will appear here',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: completedJobs
            .map((job) => _buildCompletedJobCard(job))
            .toList(),
      ),
    );
  }

  // OWNER TABS
  Widget _buildMyRequestsTab() {
    final requestProvider = context.watch<RequestProvider>();
    final ownerPending = requestProvider.ownerPendingRequests;

    if (requestProvider.isLoading && ownerPending.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ownerPending.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: _buildEmptyState(
                icon: Icons.assignment_rounded,
                title: 'No Requests',
                subtitle: 'Send requests to caregivers to get started',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: ownerPending
            .map(
              (request) => OwnerRequestCard(
                request: request,
                onCancel: () => _handleCancelRequest(request),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActiveWalkTab() {
    final requestProvider = context.watch<RequestProvider>();
    final activeWalk = requestProvider.ownerActiveRequests.firstOrNull;

    if (requestProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activeWalk == null) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: _buildEmptyState(
                icon: Icons.directions_walk_rounded,
                title: 'No Active Walk',
                subtitle: 'Once a caregiver accepts, you\'ll see them here',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [_buildActiveWalkCard(activeWalk)],
      ),
    );
  }

  Widget _buildOwnerHistoryTab() {
    final requestProvider = context.watch<RequestProvider>();
    final history = requestProvider.ownerCompletedRequests;

    if (requestProvider.isLoading && history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (history.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: _buildEmptyState(
                icon: Icons.history_rounded,
                title: 'No History',
                subtitle: 'Your walk history will appear here',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: history.map((walk) => _buildOwnerHistoryCard(walk)).toList(),
      ),
    );
  }

  // CARD BUILDERS
  Widget _buildActiveJobCard(RequestModel job) {
    final theme = Theme.of(context);
    final green = theme.colorScheme.tertiary;

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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pets_rounded, color: green, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.petName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Owner: ${job.ownerName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: job.status, isCompact: true),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () async {
                final walksProvider = Provider.of<WalksProvider>(
                  context,
                  listen: false,
                );
                // Create walk session from request data
                final walkId = await walksProvider.createWalkSession(
                  petId: job.id, // use request id as reference
                  petName: job.petName,
                  ownerId: job.petOwnerId,
                  caregiverId: job.caregiverId,
                  caregiverName: job.caregiverName,
                  scheduledAt: job.requestedDate,
                  notes: job.notes,
                );
                if (walkId != null) {
                  await walksProvider.startWalk(walkId);
                }
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CaregiverJobScreen(request: job, walkId: walkId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text('Start Walk'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobCard(RequestModel job) {
    final theme = Theme.of(context);
    final green = theme.colorScheme.tertiary;

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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, color: green, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.petName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.ownerName} • ${_formatDate(job.requestedDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\u2713 Completed',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWalkCard(RequestModel walk) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Walk',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Caregiver info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, color: primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        walk.caregiverName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${walk.petName} (${walk.petType})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trusted',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Pet info
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                'Live tracking active',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerHistoryCard(RequestModel walk) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pets_rounded, color: primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  walk.caregiverName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${walk.petName} • ${_formatDate(walk.requestedDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 4),
                Text(
                  'Completed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Handler methods (to be connected to backend later)
  Future<void> _handleAcceptRequest(RequestModel request) async {
    final requestProvider = context.read<RequestProvider>();
    final success = await requestProvider.acceptRequest(request.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Request accepted! 🎉' : 'Failed to accept request',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleRejectRequest(RequestModel request) async {
    final requestProvider = context.read<RequestProvider>();
    final success = await requestProvider.rejectRequest(request.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Request rejected' : 'Failed to reject request',
        ),
        backgroundColor: success ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleCancelRequest(RequestModel request) async {
    final requestProvider = context.read<RequestProvider>();
    final success = await requestProvider.cancelRequest(request.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Request cancelled' : 'Failed to cancel request',
        ),
        backgroundColor: success ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
