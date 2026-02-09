import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Result class for Auth operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  AuthResult({required this.success, this.errorMessage, this.user});

  factory AuthResult.success(UserModel user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, errorMessage: message);
  }
}

/// Authentication Service for PawTrust
/// Handles all Firebase Auth and Firestore user operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for users
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Collection reference for audit logs
  CollectionReference get _auditLogsCollection =>
      _firestore.collection('audit_logs');

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Log audit event to Firestore
  Future<void> _logAuditEvent({
    required String action,
    required String userId,
    required bool success,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _auditLogsCollection.add({
        'action': action,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'success': success,
        'errorMessage': errorMessage,
        'metadata': metadata,
      });
    } catch (e) {
      // Don't fail the main operation if audit logging fails
      debugPrint('Audit logging failed: $e');
    }
  }

  /// Sign up with email and password
  /// Creates user in Firebase Auth and stores profile in Firestore
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      if (credential.user == null) {
        return AuthResult.failure('Failed to create user account');
      }

      // 2. Create UserModel (role will be set later in RoleSelectionScreen)
      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        role: UserRole.owner, // Default role, will be updated
        createdAt: DateTime.now(),
        onboardingComplete: false, // Will be set true after role selection
      );

      // 3. Store user document in Firestore
      await _usersCollection
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      // 4. Log audit event
      await _logAuditEvent(
        action: 'signup',
        userId: credential.user!.uid,
        success: true,
        metadata: {'email': email.trim()},
      );

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to sign in');
      }

      // Fetch user data from Firestore
      final userModel = await getUserData(credential.user!.uid);
      if (userModel == null) {
        return AuthResult.failure('User profile not found');
      }

      // Log audit event
      await _logAuditEvent(
        action: 'login',
        userId: credential.user!.uid,
        success: true,
      );

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Sign out with error handling and audit logging
  /// Returns true if successful, false otherwise
  Future<({bool success, String? errorMessage})> signOut() async {
    final userId = _auth.currentUser?.uid ?? 'unknown';

    try {
      await _auth.signOut();

      // Log successful logout
      await _logAuditEvent(action: 'logout', userId: userId, success: true);

      return (success: true, errorMessage: null);
    } catch (e) {
      final errorMsg = 'Failed to sign out: $e';
      debugPrint(errorMsg);

      // Log failed logout attempt
      await _logAuditEvent(
        action: 'logout',
        userId: userId,
        success: false,
        errorMessage: errorMsg,
      );

      return (
        success: false,
        errorMessage: 'Unable to sign out. Please try again.',
      );
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get user data: $e');
      return null;
    }
  }

  /// Update user role in Firestore and mark onboarding complete
  Future<bool> updateUserRole(String uid, UserRole role) async {
    try {
      await _usersCollection.doc(uid).update({
        'role': role == UserRole.caregiver ? 'caregiver' : 'owner',
        'onboardingComplete': true,
      });

      // Log role selection
      await _logAuditEvent(
        action: 'role_selection',
        userId: uid,
        success: true,
        metadata: {'role': role == UserRole.caregiver ? 'caregiver' : 'owner'},
      );

      return true;
    } catch (e) {
      debugPrint('Failed to update user role: $e');
      return false;
    }
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
