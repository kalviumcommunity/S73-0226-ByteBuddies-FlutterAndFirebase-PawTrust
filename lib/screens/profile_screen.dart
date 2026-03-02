import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/pets_provider.dart';
import '../models/user_model.dart';
import '../widgets/paw_snackbar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawTrustApp.surfaceLight,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userProfile = authProvider.userProfile;
          final user = authProvider.currentUser;

          return Column(
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [PawTrustApp.trustGreen, Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Profile',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            authProvider.refreshProfile();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  transform: Matrix4.translationValues(0, -24, 0),
                  decoration: const BoxDecoration(
                    color: PawTrustApp.surfaceLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ── Profile card ──
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: PawTrustApp.borderColor.withAlpha(100),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    PawTrustApp.trustGreen,
                                    Color(0xFF15803D),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: PawTrustApp.trustGreen.withAlpha(50),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: PawTrustApp.trustGreen
                                    .withAlpha(25),
                                backgroundImage: userProfile?.photoUrl != null
                                    ? NetworkImage(userProfile!.photoUrl!)
                                    : null,
                                child: userProfile?.photoUrl == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 44,
                                        color: PawTrustApp.trustGreen,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              userProfile?.fullName ??
                                  user?.displayName ??
                                  'User',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: PawTrustApp.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (userProfile?.role == UserRole.caregiver
                                            ? const Color(0xFF7C3AED)
                                            : PawTrustApp.primaryBlue)
                                        .withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                userProfile?.role == UserRole.caregiver
                                    ? 'Verified Caregiver'
                                    : 'Pet Owner',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: userProfile?.role == UserRole.caregiver
                                      ? const Color(0xFF7C3AED)
                                      : PawTrustApp.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: GoogleFonts.poppins(
                                color: PawTrustApp.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),

                            Consumer<PetsProvider>(
                              builder: (context, petsProvider, _) {
                                return Row(
                                  children: [
                                    _statItem(
                                      'Trust',
                                      '${userProfile?.trustScore ?? 0}%',
                                    ),
                                    const SizedBox(width: 12),
                                    _statItem(
                                      'Walks',
                                      '${userProfile?.completedWalks ?? 0}',
                                    ),
                                    const SizedBox(width: 12),
                                    _statItem(
                                      'Pets',
                                      '${petsProvider.pets.length}',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      Text(
                        'Account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PawTrustApp.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _settingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                      _settingsTile(
                        icon: Icons.verified_user_rounded,
                        title: 'Verification Status',
                        trailing: userProfile?.isVerified == true
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: PawTrustApp.trustGreen,
                                size: 22,
                              )
                            : null,
                      ),
                      _settingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final confirm = await PawDialog.confirm(
                              context,
                              title: 'Logout',
                              message: 'Are you sure you want to logout?',
                              confirmLabel: 'Logout',
                              isDangerous: true,
                            );

                            if (confirm == true) {
                              await authProvider.signOut();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: PawTrustApp.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PawTrustApp.borderColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: PawTrustApp.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: PawTrustApp.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PawTrustApp.borderColor.withAlpha(100)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PawTrustApp.primaryBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PawTrustApp.primaryBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: PawTrustApp.textPrimary,
                ),
              ),
            ),
            trailing ??
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
