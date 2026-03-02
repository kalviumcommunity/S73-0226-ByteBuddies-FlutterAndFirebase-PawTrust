import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../widgets/shimmer_loading.dart';
import 'role_based_dashboard.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  bool _didLoad = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadData();
        if (mounted) _animCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final requests = context.read<RequestProvider>();
    final user = auth.user;
    if (user == null) return;

    final isCaregiver = user.role == UserRole.caregiver;
    if (isCaregiver) {
      await Future.wait([
        requests.fetchCaregiverActiveRequests(user.uid),
        requests.fetchCaregiverCompletedRequests(user.uid),
      ]);
    } else {
      await requests.fetchOwnerRequests(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawTrustApp.surfaceLight,
      body: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [PawTrustApp.trustGreen, Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: Text(
                      'Activity',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.white.withAlpha(31),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _loadData();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Consumer2<AuthProvider, RequestProvider>(
                builder: (context, auth, requests, _) {
                  final user = auth.user;
                  if (user == null) {
                    return Center(
                      child: Text(
                        'Please log in',
                        style: GoogleFonts.poppins(
                          color: PawTrustApp.textSecondary,
                        ),
                      ),
                    );
                  }

                  final isCaregiver = user.role == UserRole.caregiver;
                  final activeList = isCaregiver
                      ? requests.activeRequests
                      : requests.ownerActiveRequests;
                  final completedList = isCaregiver
                      ? requests.completedRequests
                      : requests.ownerCompletedRequests;

                  if (requests.isLoading &&
                      activeList.isEmpty &&
                      completedList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: ShimmerList(itemCount: 4),
                    );
                  }

                  return RefreshIndicator(
                    color: PawTrustApp.trustGreen,
                    onRefresh: _loadData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildActiveWalkCard(activeList),
                        const SizedBox(height: 24),

                        // Quick action
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, a, __) => FadeTransition(
                                    opacity: a,
                                    child: const RoleBasedDashboard(),
                                  ),
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              isCaregiver
                                  ? Icons.assignment_rounded
                                  : Icons.directions_walk_rounded,
                            ),
                            label: Text(
                              isCaregiver
                                  ? 'View All Requests'
                                  : 'Manage Walks',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          'Recent Activity',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: PawTrustApp.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (completedList.isEmpty)
                          _buildEmptyHistoryState()
                        else
                          ...completedList
                              .take(10)
                              .map((r) => _buildHistoryCard(r)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active Walk Card ──
  Widget _buildActiveWalkCard(List<RequestModel> activeList) {
    if (activeList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: PawTrustApp.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: PawTrustApp.trustGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Active Walk',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: PawTrustApp.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Book a caregiver to start a walk session.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: PawTrustApp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: activeList.map((request) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PawTrustApp.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PawTrustApp.trustGreen.withAlpha(51),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: PawTrustApp.trustGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active: ${request.petName}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: PawTrustApp.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'With ${request.caregiverName}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: PawTrustApp.textSecondary,
                      ),
                    ),
                    if (request.requestedTime != null)
                      Text(
                        'Scheduled: ${request.requestedTime}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: PawTrustApp.trustGreen,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.poppins(
                    color: PawTrustApp.trustGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── History Card ──
  Widget _buildHistoryCard(RequestModel request) {
    final isCompleted = request.status == RequestStatus.completed;
    final statusColor = isCompleted
        ? PawTrustApp.trustGreen
        : const Color(0xFFF59E0B);
    final statusLabel = isCompleted ? 'Completed' : request.status.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PawTrustApp.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.petName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: PawTrustApp.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.caregiverName} • ${_formatDate(request.requestedDate)}',
                  style: GoogleFonts.poppins(
                    color: PawTrustApp.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.poppins(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty History ──
  Widget _buildEmptyHistoryState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: PawTrustApp.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 36,
              color: PawTrustApp.trustGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PawTrustApp.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your pet walks and care sessions will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: PawTrustApp.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
