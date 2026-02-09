import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';

/// AuthWrapper - Handles automatic routing based on auth state
/// This widget listens to authentication changes and redirects accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Show loading spinner while checking auth state
    if (authProvider.status == AuthStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Route based on auth status
    switch (authProvider.status) {
      case AuthStatus.authenticated:
        return const HomeScreen();

      case AuthStatus.needsRoleSelection:
        return const RoleSelectionScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const LoginScreen();
    }
  }
}
