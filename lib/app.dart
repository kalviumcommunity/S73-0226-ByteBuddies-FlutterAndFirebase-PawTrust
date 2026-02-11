import 'package:flutter/material.dart';
import 'screens/auth_wrapper.dart';

class PawTrustApp extends StatelessWidget {
  const PawTrustApp({super.key});

  // Modern SaaS Color Palette
  static const Color primaryBlue = Color(0xFF5B7DEF);      // Modern blue
  static const Color primaryBlueDark = Color(0xFF4A63C4);  // Darker blue for contrast
  static const Color accentPurple = Color(0xFF7C5DFA);     // Vibrant purple
  static const Color successGreen = Color(0xFF10B981);     // Modern green
  static const Color warningOrange = Color(0xFFF59E0B);    // Warm orange
  static const Color errorRed = Color(0xFFEF4444);         // Clean red
  static const Color surfaceLight = Color(0xFFF8FAFC);     // Almost white
  static const Color surfaceDark = Color(0xFF1E293B);      // Dark slate
  static const Color textPrimary = Color(0xFF0F172A);      // Almost black
  static const Color textSecondary = Color(0xFF64748B);    // Slate gray
  static const Color dividerColor = Color(0xFFE2E8F0);     // Light divider

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawTrust',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Color Scheme
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: primaryBlue,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFEEF2FF),
          onPrimaryContainer: primaryBlue,
          secondary: accentPurple,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFF3E8FF),
          onSecondaryContainer: accentPurple,
          tertiary: successGreen,
          onTertiary: Colors.white,
          error: errorRed,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: textPrimary,
          outline: dividerColor,
          outlineVariant: Color(0xFFCBD5E1),
        ),

        // Background
        scaffoldBackgroundColor: surfaceLight,
        canvasColor: surfaceLight,

        // Typography
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSecondary,
            height: 1.5,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),

        // Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dividerColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dividerColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed, width: 2),
          ),
          hintStyle: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          labelStyle: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIconColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return primaryBlue;
            }
            return textSecondary;
          }),
          suffixIconColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return primaryBlue;
            }
            return textSecondary;
          }),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryBlue,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            side: const BorderSide(color: dividerColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Card
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: dividerColor),
          ),
          margin: EdgeInsets.zero,
        ),

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
          surfaceTintColor: Colors.transparent,
        ),

        // Other Components
        dividerTheme: DividerThemeData(
          color: dividerColor,
          thickness: 1,
          space: 16,
        ),

        disabledColor: Color(0xFFCBD5E1),
        hoverColor: Color(0xFFF1F5F9),
        focusColor: Color(0xFFEEF2FF),
        highlightColor: Color(0xFFEEF2FF),
        splashColor: Color(0xFFEEF2FF),
      ),

      initialRoute: '/',
      routes: {'/': (context) => const AuthWrapper()},
    );
  }
}
