import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/pin.dart';
import '../models/pin_form_data.dart';
import '../models/user.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static const Duration _timeout = Duration(seconds: 10);

  /// Generic GET list handler to reduce duplication
  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'))
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

  // Categories
  Future<List<Category>> getCategories() =>
      _getList('/categories/', Category.fromJson);

  Future<List<CategoryLevel>> getCategoryLevels() =>
      _getList('/categories/levels', CategoryLevel.fromJson);

  Future<List<SubCategory>> getSubCategories() =>
      _getList('/categories/sub-categories', SubCategory.fromJson);

  // Pins
  Future<List<Pin>> getPins() => _getList('/pins/', Pin.fromJson);

  // Pins
  Future<Pin> createPin(PinFormData formData, int userId) async {
    try {
      final body = formData.toJson();
      body['user_id'] = userId;

      final response = await http
          .post(
            Uri.parse('$baseUrl/pins/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return Pin.fromJson(json.decode(response.body));
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
}
