import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/friend_request.dart';

void main() {
  group('FriendRequest', () {
    final validJson = {
      'user_rel_id': 1,
      'user_id': 10,
      'target_user_id': 20,
      'user_rel_status': 'pending',
      'created_at': '2026-02-26T12:00:00.000',
      'updated_at': '2026-02-26T13:00:00.000',
    };

    test('fromJson maps all fields correctly', () {
      final fr = FriendRequest.fromJson(validJson);

      expect(fr.userRelId, 1);
      expect(fr.userId, 10);
      expect(fr.targetUserId, 20);
      expect(fr.status, 'pending');
      expect(fr.createdAt, DateTime.parse('2026-02-26T12:00:00.000'));
      expect(fr.updatedAt, DateTime.parse('2026-02-26T13:00:00.000'));
    });

    test('toJson produces correct backend keys', () {
      final fr = FriendRequest.fromJson(validJson);
      final output = fr.toJson();

      expect(output['user_rel_id'], 1);
      expect(output['user_id'], 10);
      expect(output['target_user_id'], 20);
      expect(output['user_rel_status'], 'pending');
      expect(output.containsKey('created_at'), true);
      expect(output.containsKey('updated_at'), true);
    });

    test('round-trip fromJson(toJson()) preserves all data', () {
      final original = FriendRequest.fromJson(validJson);
      final roundTripped = FriendRequest.fromJson(original.toJson());

      expect(roundTripped.userRelId, original.userRelId);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.targetUserId, original.targetUserId);
      expect(roundTripped.status, original.status);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.updatedAt, original.updatedAt);
    });

    test('fromJson works with all valid statuses', () {
      for (final status in ['pending', 'accepted', 'rejected', 'blocked']) {
        final json = {...validJson, 'user_rel_status': status};
        final fr = FriendRequest.fromJson(json);
        expect(fr.status, status);
      }
    });

    test('fromJson throws on missing required field', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('user_rel_id');
      expect(
        () => FriendRequest.fromJson(incomplete),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson throws on invalid date format', () {
      final badDate = {...validJson, 'created_at': 'not-a-date'};
      expect(
        () => FriendRequest.fromJson(badDate),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
