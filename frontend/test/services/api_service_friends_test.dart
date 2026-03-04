import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/secure_storage_service.dart';

@GenerateNiceMocks([MockSpec<http.Client>(), MockSpec<SecureStorageService>()])
import 'api_service_friends_test.mocks.dart';

// Helper to build a fake User JSON
Map<String, dynamic> fakeUserJson({int id = 1}) => {
  'user_id': id,
  'user_fname': 'Test',
  'user_lname': 'User',
  'user_email': 'test$id@example.com',
  'user_displayname': null,
  'user_use_displayname': false,
};

// Helper to build a fake FriendRequest JSON
Map<String, dynamic> fakeFriendRequestJson({int relId = 1}) => {
  'user_rel_id': relId,
  'user_id': 10,
  'target_user_id': 20,
  'user_rel_status': 'pending',
  'created_at': '2026-02-26T12:00:00.000',
  'updated_at': '2026-02-26T13:00:00.000',
};

void main() {
  late MockClient mockClient;
  late MockSecureStorageService mockStorage;
  late ApiService apiService;

  setUp(() {
    mockClient = MockClient();
    mockStorage = MockSecureStorageService();
    when(mockStorage.getToken()).thenAnswer((_) async => 'test-token');
    apiService = ApiService(httpClient: mockClient, storage: mockStorage);
  });

  group('getFriends', () {
    test('returns list of users on 200', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(
          json.encode([fakeUserJson(id: 1), fakeUserJson(id: 2)]),
          200,
        ),
      );

      final friends = await apiService.getFriends();
      expect(friends.length, 2);
      expect(friends[0].userId, 1);
      expect(friends[1].userId, 2);
    });

    test('throws ApiException on server error', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(() => apiService.getFriends(), throwsA(isA<ApiException>()));
    });
  });

  group('searchUsers', () {
    test('returns matching users on 200', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(json.encode([fakeUserJson(id: 5)]), 200),
      );

      final results = await apiService.searchUsers('test');
      expect(results.length, 1);
      expect(results[0].userId, 5);
    });

    test('returns empty list when no matches', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response(json.encode([]), 200));

      final results = await apiService.searchUsers('nonexistent');
      expect(results, isEmpty);
    });
  });

  group('getIncomingRequests', () {
    test('returns list of FriendRequests on 200', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async =>
            http.Response(json.encode([fakeFriendRequestJson(relId: 1)]), 200),
      );

      final requests = await apiService.getIncomingRequests();
      expect(requests.length, 1);
      expect(requests[0].userRelId, 1);
      expect(requests[0].status, 'pending');
    });
  });

  group('getSentRequests', () {
    test('returns list of FriendRequests on 200', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async =>
            http.Response(json.encode([fakeFriendRequestJson(relId: 3)]), 200),
      );

      final requests = await apiService.getSentRequests();
      expect(requests.length, 1);
      expect(requests[0].userRelId, 3);
    });
  });

  group('sendFriendRequest', () {
    test('returns FriendRequest on 201', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(json.encode(fakeFriendRequestJson(relId: 5)), 201),
      );

      final result = await apiService.sendFriendRequest(20);
      expect(result.userRelId, 5);
      expect(result.status, 'pending');
    });

    test('throws ApiException with 204 (already friends)', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('', 204));

      expect(
        () => apiService.sendFriendRequest(20),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 204),
        ),
      );
    });

    test('throws ApiException with 403 (blocked)', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          json.encode({'detail': 'Relationship is blocked'}),
          403,
        ),
      );

      expect(
        () => apiService.sendFriendRequest(20),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('throws ApiException with 422 (already exists)', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          json.encode({'detail': 'Relationship already exists'}),
          422,
        ),
      );

      expect(
        () => apiService.sendFriendRequest(20),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });
  });

  group('updateFriendRequest', () {
    test('returns updated FriendRequest on 200', () async {
      final updatedJson = {
        ...fakeFriendRequestJson(relId: 1),
        'user_rel_status': 'accepted',
      };
      when(
        mockClient.patch(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(updatedJson), 200));

      final result = await apiService.updateFriendRequest(1, 'accepted');
      expect(result.status, 'accepted');
    });

    test('throws ApiException on 403', () async {
      when(
        mockClient.patch(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Forbidden', 403));

      expect(
        () => apiService.updateFriendRequest(1, 'accepted'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('throws ApiException on 404', () async {
      when(
        mockClient.patch(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Not found', 404));

      expect(
        () => apiService.updateFriendRequest(99, 'accepted'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('deleteFriendRequest', () {
    test('completes successfully on 204', () async {
      when(
        mockClient.delete(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('', 204));

      await expectLater(apiService.deleteFriendRequest(1), completes);
    });

    test('throws ApiException on 403', () async {
      when(
        mockClient.delete(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Forbidden', 403));

      expect(
        () => apiService.deleteFriendRequest(1),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('throws ApiException on 404', () async {
      when(
        mockClient.delete(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Not found', 404));

      expect(
        () => apiService.deleteFriendRequest(99),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });
}
