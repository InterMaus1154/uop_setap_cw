import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_location.dart';

void main() {
  test('parses naive ISO sharing_expires_at as UTC', () {
    final json = {
      'user_loc_id': 1,
      'user_id': 2,
      'latitude': 0.0,
      'longitude': 0.0,
      'is_enabled': true,
      'created_at': '2026-05-18T10:00:00',
      'updated_at': '2026-05-18T10:00:00',
      // naive ISO (no timezone) — should be treated as UTC by fromJson
      'sharing_expires_at': '2026-05-18T12:00:00',
    };

    final loc = UserLocation.fromJson(json);
    expect(loc.sharingExpiresAt, isNotNull);
    expect(loc.sharingExpiresAt!.isUtc, isTrue);
    expect(loc.sharingExpiresAt!.toIso8601String(), '2026-05-18T12:00:00.000Z');
  });

  group('UserLocation', () {
    final validJson = {
      'user_loc_id': 1,
      'user_id': 10,
      'latitude': 50.798,
      'longitude': -1.098,
      'is_enabled': true,
      'created_at': '2026-02-26T12:00:00.000',
      'updated_at': '2026-02-26T13:00:00.000',
      'city': 'Portsmouth',
      'street': 'Winston Churchill Ave',
    };

    test('fromJson maps all fields correctly', () {
      final loc = UserLocation.fromJson(validJson);

      expect(loc.userLocId, 1);
      expect(loc.userId, 10);
      expect(loc.latitude, 50.798);
      expect(loc.longitude, -1.098);
      expect(loc.isEnabled, true);
      expect(loc.createdAt, DateTime.parse('2026-02-26T12:00:00.000Z'));
      expect(loc.updatedAt, DateTime.parse('2026-02-26T13:00:00.000Z'));
      expect(loc.city, 'Portsmouth');
      expect(loc.street, 'Winston Churchill Ave');
    });

    test('fromJson casts integer coordinates to double', () {
      final json = {...validJson, 'latitude': 51, 'longitude': -1};
      final loc = UserLocation.fromJson(json);

      expect(loc.latitude, 51.0);
      expect(loc.longitude, -1.0);
      expect(loc.latitude, isA<double>());
      expect(loc.longitude, isA<double>());
    });

    test('fromJson allows null city and street', () {
      final json = {...validJson, 'city': null, 'street': null};
      final loc = UserLocation.fromJson(json);

      expect(loc.city, isNull);
      expect(loc.street, isNull);
    });

    test('toJson produces correct backend keys', () {
      final output = UserLocation.fromJson(validJson).toJson();

      expect(output['user_loc_id'], 1);
      expect(output['user_id'], 10);
      expect(output['latitude'], 50.798);
      expect(output['longitude'], -1.098);
      expect(output['is_enabled'], true);
      expect(output['created_at'], '2026-02-26T12:00:00.000Z');
      expect(output['updated_at'], '2026-02-26T13:00:00.000Z');
    });

    test('round-trip preserves the fields toJson serialises', () {
      final original = UserLocation.fromJson(validJson);
      // toJson omits city/street — supply them so fromJson can rebuild.
      final roundTripped = UserLocation.fromJson({
        ...original.toJson(),
        'city': original.city,
        'street': original.street,
      });

      expect(roundTripped.userLocId, original.userLocId);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.latitude, original.latitude);
      expect(roundTripped.longitude, original.longitude);
      expect(roundTripped.isEnabled, original.isEnabled);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.updatedAt, original.updatedAt);
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('user_loc_id');
      expect(
        () => UserLocation.fromJson(incomplete),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson throws on invalid date format', () {
      final badDate = {...validJson, 'created_at': 'not-a-date'};
      expect(
        () => UserLocation.fromJson(badDate),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
