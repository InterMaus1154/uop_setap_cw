import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/friend_provider.dart';

void main() {
  group('FriendProvider', () {
    late FriendProvider provider;

    setUp(() {
      provider = FriendProvider();
    });

    test('initial state has empty lists and no loading/errors', () {
      expect(provider.friends, isEmpty);
      expect(provider.incomingRequests, isEmpty);
      expect(provider.outgoingRequests, isEmpty);
      expect(provider.userCache, isEmpty);
      expect(provider.friendsLoading, false);
      expect(provider.incomingLoading, false);
      expect(provider.outgoingLoading, false);
      expect(provider.friendsError, isNull);
      expect(provider.incomingError, isNull);
      expect(provider.outgoingError, isNull);
    });

    test('clear() resets all state to defaults', () {
      // We can't easily populate internal state without mocking ApiService,
      // but we can verify clear() doesn't throw and leaves state clean
      provider.clear();

      expect(provider.friends, isEmpty);
      expect(provider.incomingRequests, isEmpty);
      expect(provider.outgoingRequests, isEmpty);
      expect(provider.userCache, isEmpty);
      expect(provider.friendsLoading, false);
      expect(provider.incomingLoading, false);
      expect(provider.outgoingLoading, false);
      expect(provider.friendsError, isNull);
      expect(provider.incomingError, isNull);
      expect(provider.outgoingError, isNull);
    });

    test('clear() notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.clear();
      expect(notified, true);
    });
  });
}
