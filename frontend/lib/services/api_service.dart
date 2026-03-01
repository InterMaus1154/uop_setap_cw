import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/pin.dart';
import '../models/pin_form_data.dart';
import '../models/friend_request.dart';
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
  Future<void> updateUserProfile({
    required String fname,
    required String lname,
    String? displayName,
    required bool useDisplayName,
  }) async {
    final headers = await _authHeaders();
    final body = json.encode({
      'user_fname': fname,
      'user_lname': lname,
      'user_display_name': displayName,
      'user_use_displayname': useDisplayName,
    });
    final response = await _httpClient
        .put(Uri.parse('$baseUrl/users/'), headers: headers, body: body)
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to update profile: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  static const String baseUrl = 'http://localhost:8000';
  static const Duration _timeout = Duration(seconds: 10);
  final SecureStorageService _storage;
  final http.Client _httpClient;

  ApiService({SecureStorageService? storage, http.Client? httpClient})
    : _storage = storage ?? SecureStorageService(),
      _httpClient = httpClient ?? http.Client();

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
      final response = await _httpClient
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
      final response = await _httpClient
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
      await _httpClient
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
      final response = await _httpClient
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
  Future<List<Pin>> getPins({
    List<int>? catIds,
    List<int>? catLevelIds,
    DateTime? pinExpireAt,
  }) async {
    String path = '/pins/';

    final params = <String>[];
    if (catIds != null && catIds.isNotEmpty) {
      params.addAll(catIds.map((id) => 'cat_id=$id'));
    }
    if (catLevelIds != null && catLevelIds.isNotEmpty) {
      params.addAll(catLevelIds.map((id) => 'cat_level_id=$id'));
    }
    if (pinExpireAt != null) {
      params.add(
        'pin_expire_at=${Uri.encodeQueryComponent(pinExpireAt.toIso8601String())}',
      );
    }

    if (params.isNotEmpty) {
      path += '?${params.join('&')}';
    }

    return _getList(path, Pin.fromJson);
  }

  // this displays pins on users profile of how many they made
  // undecided if they should decrease as pins expire or just continue like a tally
  Future<int> getMyPinCount() async {
    try {
      final headers = await _authHeaders();
      final response = await _httpClient
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
      final response = await _httpClient
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
      final response = await _httpClient
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
      final response = await _httpClient
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

  // Friends
  Future<List<User>> getFriends() => _getList('/friends/', User.fromJson);

  Future<List<User>> searchUsers(String email) =>
      _getList('/users/search/$email', User.fromJson);

  Future<List<FriendRequest>> getIncomingRequests() =>
      _getList('/friends/requests', FriendRequest.fromJson);

  Future<List<FriendRequest>> getSentRequests() =>
      _getList('/friends/sent', FriendRequest.fromJson);

  Future<FriendRequest> sendFriendRequest(int targetUserId) async {
    try {
      final headers = await _authHeaders();
      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl/friends/'),
            headers: headers,
            body: json.encode({'target_user_id': targetUserId}),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return FriendRequest.fromJson(json.decode(response.body));
      } else if (response.statusCode == 204) {
        throw ApiException('You are already friends.', statusCode: 204);
      } else if (response.statusCode == 403) {
        final detail =
            json.decode(response.body)['detail'] ?? 'Relationship is blocked';
        throw ApiException(detail, statusCode: 403);
      } else if (response.statusCode == 422) {
        final detail = json.decode(response.body)['detail'] ?? 'Request failed';
        throw ApiException(detail, statusCode: 422);
      } else {
        throw ApiException(
          'Failed to send friend request: ${response.statusCode}',
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

  Future<FriendRequest> updateFriendRequest(int relId, String response) async {
    try {
      final headers = await _authHeaders();
      final res = await _httpClient
          .patch(
            Uri.parse('$baseUrl/friends/$relId'),
            headers: headers,
            body: json.encode({'response': response}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return FriendRequest.fromJson(json.decode(res.body));
      } else if (res.statusCode == 403) {
        throw ApiException('Forbidden.', statusCode: 403);
      } else if (res.statusCode == 404) {
        throw ApiException('Relationship not found.', statusCode: 404);
      } else {
        throw ApiException(
          'Failed to update request: ${res.statusCode}',
          statusCode: res.statusCode,
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

  Future<void> deleteFriendRequest(int relId) async {
    try {
      final headers = await _authHeaders();
      final response = await _httpClient
          .delete(Uri.parse('$baseUrl/friends/$relId'), headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 403) {
        throw ApiException('Forbidden.', statusCode: 403);
      } else if (response.statusCode == 404) {
        throw ApiException('Relationship not found.', statusCode: 404);
      } else {
        throw ApiException(
          'Failed to delete request: ${response.statusCode}',
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
