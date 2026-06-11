import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _api.login(email, password);
      _isLoading = false;
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      } else {
        _error = 'Login gagal. Periksa email dan password.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _api.register(name, email, password);
      _isLoading = false;
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      } else {
        _error = 'Registrasi gagal.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    _error = null;
    notifyListeners();
  }

  // Load user from token (called when app starts)
  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _api.getCurrentUser();
      _user = user;
    } catch (e) {
      print('Error loading user: $e');
      _user = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error (optional)
  void clearError() {
    _error = null;
    notifyListeners();
  }
}