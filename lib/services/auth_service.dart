import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'product_infra_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class RegistrationResult {
  final bool needsEmailConfirmation;
  final String email;

  const RegistrationResult({
    required this.needsEmailConfirmation,
    required this.email,
  });
}

class AuthService extends ChangeNotifier {
  AuthService({firebase.FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  final firebase.FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  StreamSubscription<firebase.User?>? _authSub;
  AppUser? _currentUser;

  firebase.FirebaseAuth get _firebaseAuth =>
      _auth ?? firebase.FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    final user = _firebaseAuth.currentUser;
    _currentUser = user != null && user.emailVerified
        ? await _toAppUser(user)
        : null;
    await ProductInfraService.identifyUser(_currentUser?.id);

    _authSub?.cancel();
    _authSub = _firebaseAuth.authStateChanges().listen((user) async {
      final next = user != null && user.emailVerified
          ? await _toAppUser(user)
          : null;
      if (next?.id == _currentUser?.id &&
          next?.displayName == _currentUser?.displayName &&
          next?.title == _currentUser?.title &&
          next?.clinic == _currentUser?.clinic) {
        return;
      }
      _currentUser = next;
      await ProductInfraService.identifyUser(next?.id);
      notifyListeners();
    });
  }

  Future<RegistrationResult> register({
    required String email,
    required String password,
    required String displayName,
    String? title,
    String? clinic,
  }) async {
    final emailNorm = email.toLowerCase().trim();
    final name = displayName.trim();
    if (emailNorm.isEmpty) throw const AuthException('Email is required.');
    if (!emailNorm.contains('@')) {
      throw const AuthException('Enter a valid email address.');
    }
    if (password.length < 8) {
      throw const AuthException('Password must be at least 8 characters.');
    }
    if (name.isEmpty) throw const AuthException('Name is required.');

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailNorm,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Could not create the account.');
      }
      await user.updateDisplayName(name);
      await _saveProfile(
        user.uid,
        email: emailNorm,
        displayName: name,
        title: title,
        clinic: clinic,
      );
      await user.sendEmailVerification();
      await _firebaseAuth.signOut();
      _currentUser = null;
      notifyListeners();
      return RegistrationResult(needsEmailConfirmation: true, email: emailNorm);
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Could not create the account. Please try again.',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final emailNorm = email.toLowerCase().trim();
    if (emailNorm.isEmpty || password.isEmpty) {
      throw const AuthException('Enter your email and password.');
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailNorm,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthException('Could not sign in.');
      await user.reload();
      final refreshed = _firebaseAuth.currentUser ?? user;
      if (!refreshed.emailVerified) {
        await refreshed.sendEmailVerification();
        await _firebaseAuth.signOut();
        throw const AuthException(
          'Verify your email before signing in. We sent a fresh verification link.',
        );
      }
      _currentUser = await _toAppUser(refreshed);
      await ProductInfraService.identifyUser(_currentUser?.id);
      await ProductInfraService.track('login_success');
      notifyListeners();
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Could not sign in. Please try again.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final emailNorm = email.toLowerCase().trim();
    if (emailNorm.isEmpty || !emailNorm.contains('@')) {
      throw const AuthException('Enter a valid email address.');
    }
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: emailNorm);
      await ProductInfraService.track('password_reset_requested');
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch (_) {
      throw const AuthException(
        'Could not send a reset email. Please try again.',
      );
    }
  }

  Future<void> resendVerificationEmail(String email, String password) async {
    final emailNorm = email.toLowerCase().trim();
    if (emailNorm.isEmpty || password.isEmpty) {
      throw const AuthException('Enter your email and password.');
    }
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailNorm,
        password: password,
      );
      await credential.user?.sendEmailVerification();
      await _firebaseAuth.signOut();
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await ProductInfraService.track('logout');
    } finally {
      _currentUser = null;
      await ProductInfraService.identifyUser(null);
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? title,
    String? clinic,
  }) async {
    final user = _firebaseAuth.currentUser;
    final current = _currentUser;
    if (user == null || current == null) return;
    final name = displayName.trim();
    if (name.isEmpty) throw const AuthException('Name is required.');

    try {
      await user.updateDisplayName(name);
      await _saveProfile(
        user.uid,
        email: user.email ?? current.email,
        displayName: name,
        title: title,
        clinic: clinic,
      );
      _currentUser = AppUser(
        id: current.id,
        email: current.email,
        displayName: name,
        title: _string(title),
        clinic: _string(clinic),
      );
      notifyListeners();
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch (_) {
      throw const AuthException('Could not update your profile.');
    }
  }

  Future<void> changePassword({
    required String current,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) return;
    if (newPassword.length < 8) {
      throw const AuthException('New password must be at least 8 characters.');
    }

    try {
      final credential = firebase.EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      await ProductInfraService.track('password_changed');
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch (_) {
      throw const AuthException('Could not change the password.');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<AppUser> _toAppUser(firebase.User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    final displayName =
        _string(data['displayName']) ??
        user.displayName?.trim() ??
        user.email?.split('@').first ??
        'Clinician';
    return AppUser(
      id: user.uid,
      email: user.email ?? _string(data['email']) ?? '',
      displayName: displayName,
      title: _string(data['title']),
      clinic: _string(data['clinic']),
    );
  }

  Future<void> _saveProfile(
    String uid, {
    required String email,
    required String displayName,
    String? title,
    String? clinic,
  }) {
    return _db.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName.trim(),
      'title': title?.trim() ?? '',
      'clinic': clinic?.trim() ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _messageFor(firebase.FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'An account with this email already exists.',
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Invalid email or password.',
      'weak-password' => 'Choose a stronger password.',
      'requires-recent-login' => 'Please sign in again before changing this.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      _ => e.message ?? 'Authentication failed. Please try again.',
    };
  }
}
