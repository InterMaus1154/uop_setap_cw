import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

  Future<List<User>> getUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users/'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
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
}
