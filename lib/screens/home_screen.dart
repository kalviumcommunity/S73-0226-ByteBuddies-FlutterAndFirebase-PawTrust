import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pets_provider.dart';
import '../models/user_model.dart';
import 'activity_screen.dart';
import 'pets_screen.dart';
import 'profile_screen.dart';
import 'caregiver_list_screen.dart';
import 'add_pet_screen.dart';

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
    _screens = const [
      _HomeDashboard(),
      ActivityScreen(),
      PetsScreen(),
      ProfileScreen(),
    ];

    // Initialize pets provider after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petsProvider = Provider.of<PetsProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId != null) {
      petsProvider.initializePets(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trust = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // TAB CONTENT
      body: IndexedStack(index: _currentIndex, children: _screens),

      // FAB - ADD PET
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: trust.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: trust,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPetScreen()),
            );
          },
          child: const Icon(Icons.pets),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BOTTOM NAV
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, 0),
              _navItem(Icons.notifications_none, 1),
              const SizedBox(width: 40),
              _navItem(Icons.pets_outlined, 2),
              _navItem(Icons.settings_outlined, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final trust = Theme.of(context).colorScheme.secondary;
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? trust.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: isActive ? 26 : 24,
          color: isActive ? trust : Colors.black54,
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            HOME DASHBOARD TAB                               */
/* -------------------------------------------------------------------------- */

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final trust = theme.colorScheme.secondary;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.userProfile;
        final displayName =
            user?.fullName ?? authProvider.currentUser?.displayName ?? 'User';
        final isCaregiver = user?.role == UserRole.caregiver;

        return Column(
          children: [
            // HERO SECTION
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back, ${displayName.split(' ').first} 👋',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCaregiver
                        ? 'Ready to help\npets today?'
                        : 'Your pet\'s safety,\nour priority.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT SECTION
            Expanded(
              child: Container(
                transform: Matrix4.translationValues(0, -30, 0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(24),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _trustStatusCard(trust, user),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _primaryAction(
                          icon: Icons.directions_walk,
                          label: isCaregiver ? 'My Walks' : 'Start Walk',
                          color: primary,
                          onTap: () {
                            // Navigate to activity/walks
                          },
                        ),
                        _primaryAction(
                          icon: Icons.search,
                          label: 'Caregiver',
                          color: primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CaregiverListScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    _featureTile(
                      icon: Icons.verified,
                      title: 'Trust Score',
                      subtitle: 'All caregivers are identity verified',
                      color: trust,
                    ),
                    _featureTile(
                      icon: Icons.timeline,
                      title: 'Live Activity',
                      subtitle: 'Track walks in real time',
                      color: primary,
                    ),
                    _featureTile(
                      icon: Icons.history,
                      title: 'Walk History',
                      subtitle: 'View past walks & summaries',
                      color: primary,
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _trustStatusCard(Color trust, UserModel? user) {
    final trustScore = user?.trustScore ?? 0;
    final isVerified = user?.isVerified ?? false;

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
            child: Icon(Icons.verified, color: trust, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Verified Account' : 'Trusted Platform',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trustScore > 0
                      ? 'Trust Score: $trustScore'
                      : 'All caregivers are verified for safety.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
