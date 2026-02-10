import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/request_card.dart';
import '../widgets/status_badge.dart';

class RoleBasedDashboard extends StatefulWidget {
  const RoleBasedDashboard({super.key});

  @override
  State<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<RoleBasedDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabCount = 3;

  // Dummy data
  late List<RequestModel> _caregiverRequests;
  late List<RequestModel> _ownerRequests;
  late List<RequestModel> _activeJobs;
  late List<RequestModel> _completedJobs;

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  void _initializeDummyData() {
    // Dummy caregiver requests
    _caregiverRequests = [
      RequestModel(
        id: '1',
        petOwnerId: 'owner1',
        caregiverId: 'caregiver1',
        petName: 'Max',
        petType: 'dog',
        ownerName: 'Sarah Johnson',
        caregiverName: 'You',
        requestedDate: DateTime.now().add(const Duration(hours: 2)),
        requestedTime: '14:00',
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        distance: 1.2,
        notes: '30-minute walk',
      ),
      RequestModel(
        id: '2',
        petOwnerId: 'owner2',
        caregiverId: 'caregiver1',
        petName: 'Bella',
        petType: 'dog',
        ownerName: 'John Smith',
        caregiverName: 'You',
        requestedDate: DateTime.now().add(const Duration(hours: 5)),
        requestedTime: '17:00',
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        distance: 2.5,
        notes: '1-hour walk',
      ),
    ];

    // Dummy owner requests
    _ownerRequests = [
      RequestModel(
        id: '3',
        petOwnerId: 'owner1',
        caregiverId: 'caregiver2',
        petName: 'Max',
        petType: 'dog',
        ownerName: 'You',
        caregiverName: 'Alex Chen',
        requestedDate: DateTime.now(),
        requestedTime: '15:00',
        status: RequestStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        distance: 1.5,
      ),
      RequestModel(
        id: '4',
        petOwnerId: 'owner1',
        caregiverId: 'caregiver3',
        petName: 'Max',
        petType: 'dog',
        ownerName: 'You',
        caregiverName: 'Lisa Park',
        requestedDate: DateTime.now().add(const Duration(days: 1)),
        requestedTime: '10:00',
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        distance: 2.0,
      ),
    ];

    // Dummy active jobs
    _activeJobs = [
      RequestModel(
        id: '5',
        petOwnerId: 'owner3',
        caregiverId: 'caregiver1',
        petName: 'Charlie',
        petType: 'dog',
        ownerName: 'Michelle Davis',
        caregiverName: 'You',
        requestedDate: DateTime.now(),
        requestedTime: '14:00',
        status: RequestStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    // Dummy completed jobs
    _completedJobs = [
      RequestModel(
        id: '6',
        petOwnerId: 'owner1',
        caregiverId: 'caregiver1',
        petName: 'Max',
        petType: 'dog',
        ownerName: 'Sarah Johnson',
        caregiverName: 'You',
        requestedDate: DateTime.now().subtract(const Duration(days: 2)),
        status: RequestStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
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

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text('Loading...', style: Theme.of(context).textTheme.bodyLarge),
        ),
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
    if (_caregiverRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_rounded,
        title: 'No Requests',
        subtitle: 'You\'ll see incoming care requests here',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _caregiverRequests
          .map((request) => CaregiverRequestCard(
            request: request,
            onAccept: () => _handleAcceptRequest(request),
            onReject: () => _handleRejectRequest(request),
          ))
          .toList(),
    );
  }

  Widget _buildActiveJobsTab() {
    if (_activeJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_outline_rounded,
        title: 'No Active Jobs',
        subtitle: 'Accept requests to see active jobs here',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _activeJobs
          .map((job) => _buildActiveJobCard(job))
          .toList(),
    );
  }

  Widget _buildCompletedJobsTab() {
    if (_completedJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'No History',
        subtitle: 'Your completed jobs will appear here',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _completedJobs
          .map((job) => _buildCompletedJobCard(job))
          .toList(),
    );
  }

  // OWNER TABS
  Widget _buildMyRequestsTab() {
    if (_ownerRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.request_quote_rounded,
        title: 'No Requests',
        subtitle: 'Send requests to caregivers to get started',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _ownerRequests
          .map((request) => OwnerRequestCard(
            request: request,
            onCancel: () => _handleCancelRequest(request),
          ))
          .toList(),
    );
  }

  Widget _buildActiveWalkTab() {
    final activeWalk = _ownerRequests
        .where((r) => r.status == RequestStatus.accepted)
        .firstOrNull;

    if (activeWalk == null) {
      return _buildEmptyState(
        icon: Icons.directions_walk_rounded,
        title: 'No Active Walk',
        subtitle: 'Once a caregiver accepts, you\'ll see them here',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [_buildActiveWalkCard(activeWalk)],
    );
  }

  Widget _buildOwnerHistoryTab() {
    final history = _ownerRequests
        .where((r) => r.status == RequestStatus.completed)
        .toList();

    if (history.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'No History',
        subtitle: 'Your walk history will appear here',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: history
          .map((walk) => _buildOwnerHistoryCard(walk))
          .toList(),
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
                child: Icon(
                  Icons.pets_rounded,
                  color: green,
                  size: 26,
                ),
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
              onPressed: () {},
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
            child: Icon(
              Icons.verified_rounded,
              color: green,
              size: 24,
            ),
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
            '\$25',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  child: Icon(
                    Icons.person_rounded,
                    color: primary,
                    size: 22,
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: Icon(
              Icons.pets_rounded,
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
            child: Icon(
              icon,
              size: 40,
              color: theme.colorScheme.secondary,
            ),
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
  void _handleAcceptRequest(RequestModel request) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request accepted! 🎉'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleRejectRequest(RequestModel request) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request rejected'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleCancelRequest(RequestModel request) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
