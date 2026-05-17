import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/location_permission.dart';

void main() {
  group('LocationPermission', () {
    final validJson = {
      'loc_perm_id': 1,
      'user_loc_id': 5,
      'user_id': 10,
      'created_at': '2026-02-26T12:00:00.000',
      'updated_at': '2026-02-26T13:00:00.000',
    };

    test('fromJson maps all fields correctly', () {
      final perm = LocationPermission.fromJson(validJson);

      expect(perm.locPermId, 1);
      expect(perm.userLocId, 5);
      expect(perm.userId, 10);
      expect(perm.createdAt, DateTime.parse('2026-02-26T12:00:00.000'));
      expect(perm.updatedAt, DateTime.parse('2026-02-26T13:00:00.000'));
    });

    test('toJson produces correct backend keys', () {
      final output = LocationPermission.fromJson(validJson).toJson();

      expect(output['loc_perm_id'], 1);
      expect(output['user_loc_id'], 5);
      expect(output['user_id'], 10);
      expect(output['created_at'], '2026-02-26T12:00:00.000');
      expect(output['updated_at'], '2026-02-26T13:00:00.000');
    });

    test('round-trip fromJson(toJson()) preserves all data', () {
      final original = LocationPermission.fromJson(validJson);
      final roundTripped = LocationPermission.fromJson(original.toJson());

      expect(roundTripped.locPermId, original.locPermId);
      expect(roundTripped.userLocId, original.userLocId);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.updatedAt, original.updatedAt);
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('user_id');
      expect(
        () => LocationPermission.fromJson(incomplete),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson throws on invalid date format', () {
      final badDate = {...validJson, 'updated_at': 'not-a-date'};
      expect(
        () => LocationPermission.fromJson(badDate),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
