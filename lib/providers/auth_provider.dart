import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _userProfile;
  String? _errorMessage;
  bool _needsRoleSelection = false;

  AuthStatus get status => _status;
  UserModel? get userProfile => _userProfile;
  UserModel? get user => _userProfile; // Alias for compatibility
  String? get errorMessage => _errorMessage;
  bool get needsRoleSelection => _needsRoleSelection;
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _status = AuthStatus.unauthenticated;
        _userProfile = null;
        _needsRoleSelection = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      _userProfile = await _authService.getUserProfile(uid);
      if (_userProfile != null) {
        _status = AuthStatus.authenticated;
        _needsRoleSelection = false;
      } else {
        // User exists in Auth but not in Firestore yet
        _needsRoleSelection = true;
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final credential = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (credential.user != null) {
        _needsRoleSelection = true;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final credential = await _authService.signIn(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserProfile(credential.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Complete registration with role selection
  Future<bool> completeRegistration(UserRole role) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      await _authService.createUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName ?? '',
        role: role,
      );

      await _loadUserProfile(user.uid);
      _needsRoleSelection = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _userProfile = null;
    _needsRoleSelection = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserProfile(user.uid);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? fullName, String? photoUrl}) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        _errorMessage = 'User not authenticated';
        notifyListeners();
        return false;
      }

      // Update Firebase Auth display name
      if (fullName != null && fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
      }

      // Update Firestore user profile
      await _authService.updateUserProfile(
        uid: user.uid,
        fullName: fullName,
        photoUrl: photoUrl,
      );

      // Reload profile
      await _loadUserProfile(user.uid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
