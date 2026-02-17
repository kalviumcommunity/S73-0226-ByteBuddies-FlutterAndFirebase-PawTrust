import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String selectedRole = '';
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (selectedRole.isEmpty) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = selectedRole == 'owner' ? UserRole.owner : UserRole.caregiver;

    final success = await authProvider.completeRegistration(role);

    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to save role'),
          backgroundColor: Colors.red,
        ),
      );
      authProvider.clearError();
    }
    // Navigation is handled by AuthWrapper in app.dart
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trust = theme.colorScheme.secondary;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/auth_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(color: Colors.black.withAlpha(115)),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Choose your role',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'This helps us personalize your experience',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),

                const Spacer(),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _roleCard(
                        context,
                        title: 'Pet Owner',
                        description: 'Find trusted caregivers for your pets',
                        icon: Icons.pets,
                        isActive: selectedRole == 'owner',
                        onTap: () => setState(() {
                          selectedRole = 'owner';
                        }),
                      ),
                      const SizedBox(height: 16),
                      _roleCard(
                        context,
                        title: 'Caregiver',
                        description: 'Provide care and walks for pets',
                        icon: Icons.directions_walk,
                        isActive: selectedRole == 'caregiver',
                        onTap: () => setState(() {
                          selectedRole = 'caregiver';
                        }),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: selectedRole.isEmpty || _isLoading
                              ? null
                              : _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: trust,
                            disabledBackgroundColor: theme.disabledColor
                                .withAlpha(77),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final trust = theme.colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? trust : theme.dividerColor,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: trust.withAlpha(64),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? trust : theme.dividerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.black54,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
