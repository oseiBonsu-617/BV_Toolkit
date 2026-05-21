import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _usersKey = 'bv_users_db';
  static const _sessionKey = 'bv_session_user_id';

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    try {
      final userId = await _storage.read(key: _sessionKey);
      if (userId == null) return;
      final users = await _loadUsersDb();
      final raw = users[userId];
      if (raw != null) {
        _currentUser = AppUser.fromJson(Map<String, dynamic>.from(raw as Map));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _loadUsersDb() async {
    final raw = await _storage.read(key: _usersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveUsersDb(Map<String, dynamic> db) async {
    await _storage.write(key: _usersKey, value: jsonEncode(db));
  }

  String _hash(String password, String salt) {
    final bytes = utf8.encode('$password:$salt');
    return sha256.convert(bytes).toString();
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    String? title,
    String? clinic,
  }) async {
    final emailNorm = email.toLowerCase().trim();
    if (emailNorm.isEmpty) throw const AuthException('Email is required.');
    if (!emailNorm.contains('@')) throw const AuthException('Enter a valid email address.');
    if (password.length < 6) throw const AuthException('Password must be at least 6 characters.');
    if (displayName.trim().isEmpty) throw const AuthException('Name is required.');

    final db = await _loadUsersDb();
    final taken = db.values.any((u) => (u as Map)['email'] == emailNorm);
    if (taken) throw const AuthException('An account with this email already exists.');

    final id = const Uuid().v4();
    final salt = const Uuid().v4();

    db[id] = {
      'id': id,
      'email': emailNorm,
      'displayName': displayName.trim(),
      'title': title?.trim() ?? '',
      'clinic': clinic?.trim() ?? '',
      'salt': salt,
      'hash': _hash(password, salt),
    };

    await _saveUsersDb(db);
    await _storage.write(key: _sessionKey, value: id);

    _currentUser = AppUser(
      id: id,
      email: emailNorm,
      displayName: displayName.trim(),
      title: title?.trim(),
      clinic: clinic?.trim(),
    );
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    final emailNorm = email.toLowerCase().trim();
    final db = await _loadUsersDb();

    MapEntry<String, dynamic>? match;
    for (final e in db.entries) {
      if ((e.value as Map)['email'] == emailNorm) {
        match = e;
        break;
      }
    }
    if (match == null) throw const AuthException('No account found with this email.');

    final userData = Map<String, dynamic>.from(match.value as Map);
    final storedHash = userData['hash'] as String;
    final salt = userData['salt'] as String;

    if (_hash(password, salt) != storedHash) {
      throw const AuthException('Incorrect password.');
    }

    await _storage.write(key: _sessionKey, value: match.key);
    _currentUser = AppUser.fromJson(userData);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _storage.delete(key: _sessionKey);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String displayName,
    String? title,
    String? clinic,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    if (displayName.trim().isEmpty) throw const AuthException('Name is required.');

    final db = await _loadUsersDb();
    final raw = Map<String, dynamic>.from(db[user.id] as Map);
    raw['displayName'] = displayName.trim();
    raw['title'] = title?.trim() ?? '';
    raw['clinic'] = clinic?.trim() ?? '';
    db[user.id] = raw;
    await _saveUsersDb(db);

    _currentUser = user.copyWith(
      displayName: displayName.trim(),
      title: title?.trim(),
      clinic: clinic?.trim(),
    );
    notifyListeners();
  }

  Future<void> changePassword({
    required String current,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    if (newPassword.length < 6) throw const AuthException('New password must be at least 6 characters.');

    final db = await _loadUsersDb();
    final raw = Map<String, dynamic>.from(db[user.id] as Map);
    final salt = raw['salt'] as String;

    if (_hash(current, salt) != raw['hash']) {
      throw const AuthException('Current password is incorrect.');
    }

    final newSalt = const Uuid().v4();
    raw['salt'] = newSalt;
    raw['hash'] = _hash(newPassword, newSalt);
    db[user.id] = raw;
    await _saveUsersDb(db);
  }
}
