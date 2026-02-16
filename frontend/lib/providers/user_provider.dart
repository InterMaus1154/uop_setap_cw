import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Login by calling the backend auth endpoint
  Future<void> login(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email);
      _currentUser = response.user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout: call backend, clear token, clear user
  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
