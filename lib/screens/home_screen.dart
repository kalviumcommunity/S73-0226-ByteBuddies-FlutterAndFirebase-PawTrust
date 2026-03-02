import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/pets_provider.dart';
import '../providers/walks_provider.dart';
import '../models/user_model.dart';
import 'activity_screen.dart';
import 'pets_screen.dart';
import 'profile_screen.dart';
import 'caregiver_list_screen.dart';
import 'add_pet_screen.dart';
import 'role_based_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeDashboard(
        onTabChanged: (index) => setState(() => _currentIndex = index),
      ),
      const ActivityScreen(),
      const PetsScreen(),
      const ProfileScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petsProvider = Provider.of<PetsProvider>(context, listen: false);
    final walksProvider = Provider.of<WalksProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId != null) {
      petsProvider.initializePets(userId);
      final isOwner = authProvider.userProfile?.role == UserRole.owner;
      walksProvider.initializeWalks(userId, isOwner);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawTrustApp.surfaceLight,
      body: IndexedStack(index: _currentIndex, children: _screens),

      // ── FAB ──
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: PawTrustApp.trustGreen.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const AddPetScreen(),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: const Icon(Icons.pets_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom nav ──
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, Icons.home_outlined, 0, 'Home'),
              _navItem(
                Icons.notifications_rounded,
                Icons.notifications_none_rounded,
                1,
                'Activity',
              ),
              const SizedBox(width: 48),
              _navItem(Icons.pets_rounded, Icons.pets_outlined, 2, 'Pets'),
              _navItem(
                Icons.person_rounded,
                Icons.person_outline_rounded,
                3,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
    String label,
  ) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? PawTrustApp.primaryBlue.withAlpha(20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: isActive ? 24 : 22,
              color: isActive
                  ? PawTrustApp.primaryBlue
                  : PawTrustApp.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? PawTrustApp.primaryBlue
                    : PawTrustApp.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            HOME DASHBOARD TAB                               */
/* -------------------------------------------------------------------------- */

class _HomeDashboard extends StatefulWidget {
  final ValueChanged<int> onTabChanged;
  const _HomeDashboard({required this.onTabChanged});

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double begin, double end) => CurvedAnimation(
    parent: _staggerCtrl,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.userProfile;
        final displayName =
            user?.fullName ?? authProvider.currentUser?.displayName ?? 'User';
        final isCaregiver = user?.role == UserRole.caregiver;

        return Column(
          children: [
            // ── Hero gradient header ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [PawTrustApp.primaryBlue, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: -40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(10),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _stagger(0.0, 0.4),
                            child: Text(
                              'Welcome Back, ${displayName.split(' ').first} 👋',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _stagger(0.1, 0.5),
                            child: Text(
                              isCaregiver
                                  ? 'Ready to help\npets today?'
                                  : "Your pet's safety,\nour priority.",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content area ──
            Expanded(
              child: Container(
                transform: Matrix4.translationValues(0, -28, 0),
                decoration: const BoxDecoration(
                  color: PawTrustApp.surfaceLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // ── Trust status card ──
                    FadeTransition(
                      opacity: _stagger(0.2, 0.6),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(_stagger(0.2, 0.6)),
                        child: _trustStatusCard(user),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Quick actions row ──
                    FadeTransition(
                      opacity: _stagger(0.3, 0.7),
                      child: Row(
                        children: [
                          Expanded(
                            child: _quickAction(
                              icon: Icons.directions_walk_rounded,
                              label: isCaregiver ? 'My Walks' : 'Start Walk',
                              gradient: const [
                                PawTrustApp.primaryBlue,
                                Color(0xFF3B82F6),
                              ],
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RoleBasedDashboard(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _quickAction(
                              icon: Icons.search_rounded,
                              label: 'Find Caregiver',
                              gradient: const [
                                Color(0xFF7C3AED),
                                Color(0xFF8B5CF6),
                              ],
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CaregiverListScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Feature tiles ──
                    FadeTransition(
                      opacity: _stagger(0.4, 0.8),
                      child: _featureTile(
                        icon: Icons.verified_rounded,
                        title: 'Trust Score',
                        subtitle: 'All caregivers are identity verified',
                        color: PawTrustApp.trustGreen,
                        onTap: () => widget.onTabChanged(3),
                      ),
                    ),
                    FadeTransition(
                      opacity: _stagger(0.5, 0.9),
                      child: _featureTile(
                        icon: Icons.timeline_rounded,
                        title: 'Live Activity',
                        subtitle: 'Track walks in real time',
                        color: PawTrustApp.primaryBlue,
                        onTap: () => widget.onTabChanged(1),
                      ),
                    ),
                    FadeTransition(
                      opacity: _stagger(0.6, 1.0),
                      child: _featureTile(
                        icon: Icons.history_rounded,
                        title: 'Walk History',
                        subtitle: 'View past walks & summaries',
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RoleBasedDashboard(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _trustStatusCard(UserModel? user) {
    final trustScore = user?.trustScore ?? 0;
    final isVerified = user?.isVerified ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PawTrustApp.borderColor.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PawTrustApp.trustGreen.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
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
                  isVerified ? 'Verified Account' : 'Trusted Platform',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: PawTrustApp.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  trustScore > 0
                      ? 'Trust Score: $trustScore'
                      : 'All caregivers are verified for safety.',
                  style: GoogleFonts.poppins(
                    color: PawTrustApp.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withAlpha(50),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PawTrustApp.borderColor.withAlpha(100)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: PawTrustApp.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: PawTrustApp.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: PawTrustApp.textSecondary.withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }
}
