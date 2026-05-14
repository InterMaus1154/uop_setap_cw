import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user.dart';

void main() {
  group('User', () {
    final validJson = {
      'user_id': 10,
      'user_fname': 'Alex',
      'user_lname': 'Taylor',
      'user_email': 'alex@example.com',
      'user_displayname': 'AT',
      'user_use_displayname': true,
      'user_isactive': true,
      'expires_at': null,
    };

    test('fromJson maps all fields correctly', () {
      final user = User.fromJson(validJson);

      expect(user.userId, 10);
      expect(user.firstName, 'Alex');
      expect(user.lastName, 'Taylor');
      expect(user.email, 'alex@example.com');
      expect(user.displayName, 'AT');
      expect(user.useDisplayName, true);
      expect(user.isActive, true);
      expect(user.expiresAt, isNull);
    });

    test('fromJson allows null display name', () {
      final json = {...validJson, 'user_displayname': null};
      final user = User.fromJson(json);
      expect(user.displayName, isNull);
    });

    test('fromJson defaults isActive to true when missing', () {
      final json = Map<String, dynamic>.from(validJson)
        ..remove('user_isactive');
      final user = User.fromJson(json);
      expect(user.isActive, true);
    });

    test('fromJson parses expires_at when present', () {
      final json = {...validJson, 'expires_at': '2026-05-15T12:00:00.000'};
      final user = User.fromJson(json);
      expect(user.expiresAt, DateTime.parse('2026-05-15T12:00:00.000'));
    });

    test('isGuest is false when expiresAt is null', () {
      final user = User.fromJson(validJson);
      expect(user.isGuest, false);
    });

    test('isGuest is true when expiresAt is set', () {
      final json = {...validJson, 'expires_at': '2026-05-15T12:00:00.000'};
      final user = User.fromJson(json);
      expect(user.isGuest, true);
    });

    test('fullName joins first and last name', () {
      final user = User.fromJson(validJson);
      expect(user.fullName, 'Alex Taylor');
    });

    test('fullName trims when last name is empty', () {
      final json = {...validJson, 'user_lname': ''};
      final user = User.fromJson(json);
      expect(user.fullName, 'Alex');
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('user_email');
      expect(() => User.fromJson(incomplete), throwsA(isA<TypeError>()));
    });

    test('fromJson throws on invalid expires_at date', () {
      final badDate = {...validJson, 'expires_at': 'not-a-date'};
      expect(() => User.fromJson(badDate), throwsA(isA<FormatException>()));
    });
  });
}
