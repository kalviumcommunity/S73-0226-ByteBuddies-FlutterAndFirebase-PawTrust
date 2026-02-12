import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/home_screen.dart';

class PawTrustApp extends StatelessWidget {
  const PawTrustApp({super.key});

  static const Color primaryBlue = Color(0xFF2F80ED);
  static const Color trustGreen = Color(0xFF2F7D32);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawTrust',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFF9FAFB),

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: trustGreen,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper widget that handles auth state and navigation
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while initializing
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.authenticating) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is authenticated
        if (authProvider.isAuthenticated) {
          // Check if needs role selection
          if (authProvider.needsRoleSelection) {
            return const RoleSelectionScreen();
          }
          // Has role, go to home
          return const HomeScreen();
        }

        // Not authenticated
        return const LoginScreen();
      },
    );
  }
}
