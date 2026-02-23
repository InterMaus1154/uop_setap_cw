import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/pin.dart';
import '../models/pin_form_data.dart';
import '../models/user.dart';
import 'secure_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Response from login endpoint containing user data and auth token
class LoginResponse {
  final User user;
  final String token;

  LoginResponse({required this.user, required this.token});
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static const Duration _timeout = Duration(seconds: 10);
  final SecureStorageService _storage = SecureStorageService();

  /// Get auth headers with Bearer token if available
  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Generic GET list handler to reduce duplication
  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((j) => fromJson(j)).toList();
      } else {
        throw ApiException(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to server. Is the backend running?',
      );
    } on FormatException {
      throw ApiException('Invalid response from server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // Users
  Future<List<User>> getUsers() => _getList('/users/', User.fromJson);

  // Auth
  Future<LoginResponse> login(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] as String;
        await _storage.saveToken(token);
        return LoginResponse(user: User.fromJson(data), token: token);
      } else if (response.statusCode == 401) {
        throw ApiException('Invalid email address.', statusCode: 401);
      } else if (response.statusCode == 403) {
        throw ApiException('Your account has been disabled.', statusCode: 403);
      } else {
        throw ApiException(
          'Login failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to server. Is the backend running?',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http
          .post(Uri.parse('$baseUrl/auth/logout'), headers: headers)
          .timeout(_timeout);
    } catch (_) {
      // Even if logout API fails, clear local token
    } finally {
      await _storage.deleteToken();
    }
  }

  // Categories
  Future<List<Category>> getCategories() =>
      _getList('/categories/', Category.fromJson);

  Future<List<CategoryLevel>> getCategoryLevels() =>
      _getList('/categories/levels', CategoryLevel.fromJson);

  Future<List<SubCategory>> getSubCategories() =>
      _getList('/categories/sub-categories', SubCategory.fromJson);

  // Users (single)
  Future<User> getUserById(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users/$userId'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('User not found.', statusCode: 404);
      } else {
        throw ApiException(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to server. Is the backend running?',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // Pins
  Future<List<Pin>> getPins() => _getList('/pins/', Pin.fromJson);
  // this displays pins on users profile of how many they made
  // undecided if they should decrease as pins expire or just continue like a tally
  Future<int> getMyPinCount() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/users/me/pin-count'), headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['pin_count'] as int;
      } else {
        throw ApiException(
          'Failed to load pin count: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<Pin> createPin(PinFormData formData) async {
    try {
      final body = formData.toJson();

      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/pins/'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return Pin.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw ApiException(
          'Not authenticated. Please log in again.',
          statusCode: 401,
        );
      } else {
        throw ApiException(
          'Failed to create pin: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to server. Is the backend running?',
      );
    } on FormatException {
      throw ApiException('Invalid response from server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // Pin reactions
  Future<void> reactToPin(int pinId, int value) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/pins/$pinId/react'),
            headers: headers,
            body: json.encode({'value': value}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to react to pin: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to server. Is the backend running?',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<void> deletePinReaction(int pinId) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/pins/$pinId/react'), headers: headers)
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to remove reaction: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        'Could not connect to server. Is the backend running?',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }
}
