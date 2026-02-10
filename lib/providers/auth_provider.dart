import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication state enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsRoleSelection,
  error,
}

/// AuthProvider - Manages authentication state across the app
/// Uses ChangeNotifier for Provider state management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _justCompletedRoleSelection = false;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get justCompletedRoleSelection => _justCompletedRoleSelection;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Handle auth state changes from Firebase
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = null;
    } else {
      try {
        // Fetch user data from Firestore
        _user = await _authService.getUserData(firebaseUser.uid);
        if (_user != null) {
          // Check if onboarding is complete
          if (!_user!.onboardingComplete) {
            _status = AuthStatus.needsRoleSelection;
          } else {
            _status = AuthStatus.authenticated;
          }
          _errorMessage = null;
        } else {
          // User document not found - set error state with message
          _status = AuthStatus.error;
          _errorMessage = 'User profile not found. Please sign up again.';
        }
      } catch (e) {
        _status = AuthStatus.error;
        _errorMessage = 'Failed to load user data. Please try again.';
        debugPrint('Error in _onAuthStateChanged: $e');
      }
    }
    notifyListeners();
  }

  /// Sign up a new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (result.success) {
      _user = result.user;
      _status = AuthStatus.needsRoleSelection;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.error;
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Sign in an existing user
  Future<bool> signIn({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signIn(email: email, password: password);

    if (result.success) {
      _user = result.user;
      // Clear the role selection flag on successful login
      _justCompletedRoleSelection = false;
      // Check if onboarding is complete
      if (_user != null && !_user!.onboardingComplete) {
        _status = AuthStatus.needsRoleSelection;
      } else {
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.error;
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Update user role after selection
  Future<bool> updateRole(UserRole role) async {
    if (_user == null) return false;

    _status = AuthStatus.loading;
    notifyListeners();

    final success = await _authService.updateUserRole(_user!.uid, role);

    if (success) {
      _user = _user!.copyWith(role: role, onboardingComplete: true);
      // After role selection, user needs to login
      // Sign them out and redirect to login screen
      await _authService.signOut();
      _status = AuthStatus.unauthenticated;
      _justCompletedRoleSelection = true;
    } else {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to update role. Please try again.';
    }
    notifyListeners();
    return success;
  }

  /// Sign out with error handling
  Future<bool> signOut() async {
    final result = await _authService.signOut();

    if (result.success) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } else {
      _errorMessage = result.errorMessage;
      // Don't change status on logout failure - user is still technically logged in
    }
    notifyListeners();
    return result.success;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    _justCompletedRoleSelection = false;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
