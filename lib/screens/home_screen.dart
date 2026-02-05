import 'package:flutter/material.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const Color primaryBlue = Color(0xFF2F80ED);
  static const Color trustGreen = Color(0xFF2F7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      body: Column(
        children: [
          // 🔵 HERO SECTION (ENERGY)
          Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue,
                  Color(0xFF4C9AFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.menu, color: Colors.white),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Welcome Back 👋',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your pet’s safety,\nour priority.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // ⚪ FLOATING CONTENT
          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _trustStatusCard(),

                  const SizedBox(height: 32),

                  // 🔘 PRIMARY ACTIONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _primaryAction(
                        icon: Icons.directions_walk,
                        label: 'Start Walk',
                      ),
                      _primaryAction(
                        icon: Icons.search,
                        label: 'Caregiver',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 📋 FEATURE LIST
                  _featureTile(
                    icon: Icons.verified,
                    title: 'Trust Score',
                    subtitle: 'All caregivers are identity verified',
                    highlight: true,
                  ),
                  _featureTile(
                    icon: Icons.timeline,
                    title: 'Live Activity',
                    subtitle: 'Track walks in real time',
                  ),
                  _featureTile(
                    icon: Icons.history,
                    title: 'Walk History',
                    subtitle: 'View past walks & summaries',
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),

      // 🔴 CENTER FAB (TRUST + ACTION)
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: trustGreen.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: trustGreen,
          onPressed: () {},
          child: const Icon(Icons.pets),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      // 🔻 PREMIUM FLOATING NAV
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
              _navItem(icon: Icons.home_outlined, index: 0),
              _navItem(icon: Icons.notifications_none, index: 1),

              const SizedBox(width: 40),

              _navItem(icon: Icons.pets_outlined, index: 2),
              _navItem(icon: Icons.settings_outlined, index: 3),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 NAV ITEM
  Widget _navItem({
    required IconData icon,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? trustGreen.withOpacity(0.12)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: isActive ? 26 : 24,
          color: isActive ? trustGreen : Colors.black54,
        ),
      ),
    );
  }

  // 🟢 TRUST STATUS CARD
  Widget _trustStatusCard() {
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
              color: trustGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              color: trustGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trusted Platform',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'All caregivers are verified for safety.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔘 PRIMARY ACTION
  Widget _primaryAction({
    required IconData icon,
    required String label,
  }) {
    return Column(
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
          child: Icon(
            icon,
            color: primaryBlue,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // 📋 FEATURE TILE
  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (highlight ? trustGreen : primaryBlue).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: highlight ? trustGreen : primaryBlue,
            ),
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
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
