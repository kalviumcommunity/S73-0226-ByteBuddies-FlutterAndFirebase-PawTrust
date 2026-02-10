import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';

import 'activity_screen.dart';
import 'pets_screen.dart';
import 'profile_screen.dart';
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
      const RoleBasedDashboard(),
      const ActivityScreen(),
      const PetsScreen(),
      const ProfileScreen(),
    ];
    
    // Fetch pets on home screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final petProvider = context.read<PetProvider>();
      if (authProvider.user != null) {
        petProvider.fetchPets(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trust = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // 🔹 TAB CONTENT
      body: IndexedStack(index: _currentIndex, children: _screens),

      // 🟢 FAB → ADD PET
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

      // 🔻 BOTTOM NAV
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
              _navItem(Icons.home_rounded, 0),
              _navItem(Icons.notifications_rounded, 1),
              const SizedBox(width: 40),
              _navItem(Icons.pets_rounded, 2),
              _navItem(Icons.person_rounded, 3),
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
/*                         Old _HomeDashboard removed                         */
/*            Use RoleBasedDashboard for role-aware home content             */
/* -------------------------------------------------------------------------- */
