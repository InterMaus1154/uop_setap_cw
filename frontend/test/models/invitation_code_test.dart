import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/invitation_code.dart';

void main() {
  group('InvitationCode', () {
    final validJson = {
      'id': 1,
      'creator_id': 10,
      'code': 'ABC123XYZ789',
      'guest_user_id': 20,
      'created_at': '2026-02-26T12:00:00.000',
      'expires_at': '2030-01-01T12:00:00.000',
      'is_used': true,
    };

    test('fromJson maps all fields correctly', () {
      final invite = InvitationCode.fromJson(validJson);

      expect(invite.id, 1);
      expect(invite.creatorId, 10);
      expect(invite.code, 'ABC123XYZ789');
      expect(invite.guestUserId, 20);
      expect(invite.createdAt, DateTime.parse('2026-02-26T12:00:00.000'));
      expect(invite.expiresAt, DateTime.parse('2030-01-01T12:00:00.000'));
      expect(invite.isUsed, true);
    });

    test('fromJson allows null guest_user_id', () {
      final json = {...validJson, 'guest_user_id': null};
      final invite = InvitationCode.fromJson(json);
      expect(invite.guestUserId, isNull);
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)..remove('code');
      expect(
        () => InvitationCode.fromJson(incomplete),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson throws on invalid date format', () {
      final badDate = {...validJson, 'expires_at': 'not-a-date'};
      expect(
        () => InvitationCode.fromJson(badDate),
        throwsA(isA<FormatException>()),
      );
    });

    /// Builds an invitation code expiring [fromNow] relative to the test run.
    InvitationCode codeExpiringIn(Duration fromNow, {required bool isUsed}) {
      return InvitationCode.fromJson({
        ...validJson,
        'is_used': isUsed,
        'expires_at': DateTime.now().add(fromNow).toIso8601String(),
      });
    }

    group('isActive getter', () {
      test('is false when the code has been used', () {
        final invite = codeExpiringIn(const Duration(days: 1), isUsed: true);
        expect(invite.isActive, false);
      });

      test('is false when the code has expired', () {
        final invite = codeExpiringIn(const Duration(days: -1), isUsed: false);
        expect(invite.isActive, false);
      });

      test('is true when unused and not yet expired', () {
        final invite = codeExpiringIn(const Duration(days: 1), isUsed: false);
        expect(invite.isActive, true);
      });
    });

    group('expirationText getter', () {
      test('reports "Expired" for a past expiry', () {
        final invite = codeExpiringIn(const Duration(hours: -1), isUsed: false);
        expect(invite.expirationText, 'Expired');
      });

      test('reports remaining minutes when under an hour', () {
        final invite =
            codeExpiringIn(const Duration(minutes: 30), isUsed: false);
        expect(invite.expirationText, contains('minutes'));
      });

      test('reports remaining hours when under a day', () {
        final invite = codeExpiringIn(const Duration(hours: 5), isUsed: false);
        expect(invite.expirationText, contains('hours'));
      });

      test('reports remaining days when over a day away', () {
        final invite = codeExpiringIn(const Duration(days: 3), isUsed: false);
        expect(invite.expirationText, contains('days'));
      });
    });
  });
}
