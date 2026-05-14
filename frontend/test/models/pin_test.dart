import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/pin.dart';

void main() {
  group('Pin', () {
    final validJson = {
      'pin_id': 1,
      'cat_id': 2,
      'sub_cat_id': 3,
      'user_id': 10,
      'pin_title': 'Lost wallet',
      'pin_description': 'Near the library',
      'pin_picture_url': 'uploads/pins/abc.jpg',
      'pin_latitude': 50.798,
      'pin_longitude': -1.098,
      'pin_isactive': true,
      'pin_expire_at': '2030-01-01T12:00:00.000',
      'created_at': '2026-02-26T12:00:00.000',
      'pin_color': '#FF0000',
      'pin_author_name': 'Alex',
      'pin_likes': 5,
      'pin_dislikes': 2,
      'user_reaction': 1,
      'pin_street': 'Winston Churchill Ave',
      'pin_city': 'Portsmouth',
    };

    test('fromJson maps all fields correctly', () {
      final pin = Pin.fromJson(validJson);

      expect(pin.pinId, 1);
      expect(pin.catId, 2);
      expect(pin.subCatId, 3);
      expect(pin.userId, 10);
      expect(pin.pinTitle, 'Lost wallet');
      expect(pin.pinDescription, 'Near the library');
      expect(pin.pinPictureUrl, 'uploads/pins/abc.jpg');
      expect(pin.pinLatitude, 50.798);
      expect(pin.pinLongitude, -1.098);
      expect(pin.pinIsActive, true);
      expect(pin.pinExpireAt, DateTime.parse('2030-01-01T12:00:00.000'));
      expect(pin.createdAt, DateTime.parse('2026-02-26T12:00:00.000'));
      expect(pin.pinColorHex, '#FF0000');
      expect(pin.pinAuthorName, 'Alex');
      expect(pin.pinLikes, 5);
      expect(pin.pinDislikes, 2);
      expect(pin.userReaction, 1);
      expect(pin.pinStreet, 'Winston Churchill Ave');
      expect(pin.pinCity, 'Portsmouth');
    });

    test('fromJson casts integer coordinates to double', () {
      // Backend may send whole-number coords as ints — must not crash.
      final json = {...validJson, 'pin_latitude': 51, 'pin_longitude': -1};
      final pin = Pin.fromJson(json);

      expect(pin.pinLatitude, 51.0);
      expect(pin.pinLongitude, -1.0);
      expect(pin.pinLatitude, isA<double>());
      expect(pin.pinLongitude, isA<double>());
    });

    test('fromJson defaults likes and dislikes to 0 when missing', () {
      final json = Map<String, dynamic>.from(validJson)
        ..remove('pin_likes')
        ..remove('pin_dislikes');
      final pin = Pin.fromJson(json);

      expect(pin.pinLikes, 0);
      expect(pin.pinDislikes, 0);
    });

    test('fromJson allows null optional fields', () {
      final json = {
        ...validJson,
        'sub_cat_id': null,
        'pin_description': null,
        'pin_picture_url': null,
        'pin_color': null,
        'pin_author_name': null,
        'user_reaction': null,
        'pin_street': null,
        'pin_city': null,
      };
      final pin = Pin.fromJson(json);

      expect(pin.subCatId, isNull);
      expect(pin.pinDescription, isNull);
      expect(pin.pinPictureUrl, isNull);
      expect(pin.pinColorHex, isNull);
      expect(pin.pinAuthorName, isNull);
      expect(pin.userReaction, isNull);
      expect(pin.pinStreet, isNull);
      expect(pin.pinCity, isNull);
    });

    test('toJson produces correct backend keys', () {
      final pin = Pin.fromJson(validJson);
      final output = pin.toJson();

      expect(output['pin_id'], 1);
      expect(output['cat_id'], 2);
      expect(output['sub_cat_id'], 3);
      expect(output['user_id'], 10);
      expect(output['pin_title'], 'Lost wallet');
      expect(output['pin_description'], 'Near the library');
      expect(output['pin_picture_url'], 'uploads/pins/abc.jpg');
      expect(output['pin_latitude'], 50.798);
      expect(output['pin_longitude'], -1.098);
      expect(output['pin_isactive'], true);
      expect(output['pin_expire_at'], '2030-01-01T12:00:00.000');
      expect(output['created_at'], '2026-02-26T12:00:00.000');
    });

    test('round-trip preserves the fields toJson serialises', () {
      final original = Pin.fromJson(validJson);
      final roundTripped = Pin.fromJson({
        ...original.toJson(),
        // toJson omits these, supply them so fromJson can rebuild
        'pin_likes': original.pinLikes,
        'pin_dislikes': original.pinDislikes,
      });

      expect(roundTripped.pinId, original.pinId);
      expect(roundTripped.catId, original.catId);
      expect(roundTripped.subCatId, original.subCatId);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.pinTitle, original.pinTitle);
      expect(roundTripped.pinDescription, original.pinDescription);
      expect(roundTripped.pinPictureUrl, original.pinPictureUrl);
      expect(roundTripped.pinLatitude, original.pinLatitude);
      expect(roundTripped.pinLongitude, original.pinLongitude);
      expect(roundTripped.pinIsActive, original.pinIsActive);
      expect(roundTripped.pinExpireAt, original.pinExpireAt);
      expect(roundTripped.createdAt, original.createdAt);
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)..remove('pin_id');
      expect(() => Pin.fromJson(incomplete), throwsA(isA<TypeError>()));
    });

    test('fromJson throws on invalid date format', () {
      final badDate = {...validJson, 'pin_expire_at': 'not-a-date'};
      expect(() => Pin.fromJson(badDate), throwsA(isA<FormatException>()));
    });

    group('pinColor getter', () {
      Pin pinWithColor(String? hex) =>
          Pin.fromJson({...validJson, 'pin_color': hex});

      test('parses a hex string with leading #', () {
        expect(pinWithColor('#FF0000').pinColor, const Color(0xFFFF0000));
      });

      test('parses a hex string without leading #', () {
        expect(pinWithColor('00FF00').pinColor, const Color(0xFF00FF00));
      });

      test('falls back to blue when hex is null', () {
        expect(pinWithColor(null).pinColor, Colors.blue);
      });

      test('falls back to blue when hex is empty', () {
        expect(pinWithColor('').pinColor, Colors.blue);
      });

      test('falls back to blue when hex is malformed', () {
        expect(pinWithColor('not-hex').pinColor, Colors.blue);
      });
    });

    group('isExpired getter', () {
      test('is true for a past expiry date', () {
        final pin = Pin.fromJson({
          ...validJson,
          'pin_expire_at': '2000-01-01T00:00:00.000',
        });
        expect(pin.isExpired, true);
      });

      test('is false for a future expiry date', () {
        final pin = Pin.fromJson({
          ...validJson,
          'pin_expire_at': '2100-01-01T00:00:00.000',
        });
        expect(pin.isExpired, false);
      });
    });
  });

  group('PinReaction', () {
    final validJson = {
      'reaction_id': 1,
      'pin_id': 5,
      'user_id': 10,
      'reaction_value': -1,
      'created_at': '2026-02-26T12:00:00.000',
    };

    test('fromJson maps all fields correctly', () {
      final reaction = PinReaction.fromJson(validJson);

      expect(reaction.reactionId, 1);
      expect(reaction.pinId, 5);
      expect(reaction.userId, 10);
      expect(reaction.reactionValue, -1);
      expect(reaction.createdAt, DateTime.parse('2026-02-26T12:00:00.000'));
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('reaction_value');
      expect(() => PinReaction.fromJson(incomplete), throwsA(isA<TypeError>()));
    });
  });
}
