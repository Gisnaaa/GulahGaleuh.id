import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service_auth.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final ApiServiceAuth _api = ApiServiceAuth();

  AuthUser? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  AuthUser? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;

  /// Dipanggil sekali sebelum runApp: memulihkan sesi yang tersimpan.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final rawUser = prefs.getString(_userKey);
      if (token == null || rawUser == null) return;

      _token = token;
      _user = AuthUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);

      // Validasi ke server; kalau server menolak token, keluarkan user.
      try {
        final fresh = await _api.me(token);
        if (fresh == null) {
          await _clearSession();
        } else {
          _user = fresh;
        }
      } catch (_) {
        // Server tidak terjangkau: tetap pakai sesi lokal.
      }
    } catch (_) {
      await _clearSession();
    }
  }

  Future<bool> login(String username, String password) =>
      _authenticate(() => _api.login(username.trim(), password));

  Future<bool> register({
    required String name,
    required String username,
    required String password,
  }) => _authenticate(
    () => _api.register(
      name: name.trim(),
      username: username.trim(),
      password: password,
    ),
  );

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _authenticate(Future<AuthResult> Function() call) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await call();
      _token = result.token;
      _user = result.user;
      await _saveSession();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
  }

  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
