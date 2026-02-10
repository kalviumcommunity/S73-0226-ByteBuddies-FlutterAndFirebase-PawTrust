import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String selectedRole = '';
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (selectedRole.isEmpty) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final role = selectedRole == 'caregiver'
        ? UserRole.caregiver
        : UserRole.owner;

    final success = await authProvider.updateRole(role);

    if (!mounted) return;

    setState(() => _isLoading = false);

    // AuthWrapper will handle navigation on success (to LoginScreen)
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(authProvider.errorMessage ?? 'Failed to save role'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.08),
                    trust.withOpacity(0.08),
                  ],
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your role',
                            style: theme.textTheme.displayLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This helps us personalize your experience',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 32,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress indicator
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.67,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.outline,
                          valueColor: AlwaysStoppedAnimation(trust),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Step 2 of 3',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 28),

                      // Owner Role Card
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

                      // Caregiver Role Card
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

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (selectedRole.isEmpty || _isLoading)
                              ? null
                              : _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: trust,
                            disabledBackgroundColor:
                                theme.disabledColor.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          theme.colorScheme.onSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continuing...',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: theme.colorScheme.onSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Continue',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'You can change this anytime in settings',
                          style: theme.textTheme.labelMedium,
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? trust : theme.colorScheme.outline,
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: trust.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? trust.withOpacity(0.1) : theme.colorScheme.outline.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? trust : theme.colorScheme.onSurfaceVariant,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: trust,
                size: 26,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
