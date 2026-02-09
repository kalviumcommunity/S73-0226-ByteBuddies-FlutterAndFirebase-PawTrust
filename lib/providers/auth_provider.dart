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

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Handle auth state changes from Firebase
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      // Fetch user data from Firestore
      _user = await _authService.getUserData(firebaseUser.uid);
      if (_user != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
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
      _status = AuthStatus.authenticated;
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
      _user = _user!.copyWith(role: role);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to update role. Please try again.';
    }
    notifyListeners();
    return success;
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
