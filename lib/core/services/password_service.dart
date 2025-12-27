import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordService {
  static final PasswordService instance = PasswordService._();
  PasswordService._();

  static const String _passwordKey = 'unscroll_password_hash';
  static const String _passwordEnabledKey = 'unscroll_password_enabled';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Hash the password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if password protection is enabled
  bool isPasswordEnabled() {
    return _prefs?.getBool(_passwordEnabledKey) ?? false;
  }

  /// Check if password is set
  bool isPasswordSet() {
    return _prefs?.getString(_passwordKey) != null;
  }

  /// Set a new password
  Future<bool> setPassword(String password) async {
    if (password.length < 4) return false;
    
    final hash = _hashPassword(password);
    await _prefs?.setString(_passwordKey, hash);
    await _prefs?.setBool(_passwordEnabledKey, true);
    return true;
  }

  /// Verify password
  bool verifyPassword(String password) {
    final storedHash = _prefs?.getString(_passwordKey);
    if (storedHash == null) return false;
    
    final inputHash = _hashPassword(password);
    return storedHash == inputHash;
  }

  /// Enable/disable password protection
  Future<void> setPasswordEnabled(bool enabled) async {
    await _prefs?.setBool(_passwordEnabledKey, enabled);
  }

  /// Remove password
  Future<void> removePassword() async {
    await _prefs?.remove(_passwordKey);
    await _prefs?.setBool(_passwordEnabledKey, false);
  }

  /// Change password (requires old password verification)
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!verifyPassword(oldPassword)) return false;
    return await setPassword(newPassword);
  }
}