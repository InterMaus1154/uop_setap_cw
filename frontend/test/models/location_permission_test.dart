import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/location_permission.dart';

import 'dart:convert';

import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/secure_storage_service.dart';

class FakeStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => null;
}

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
  test(
    'sends explicit null when includeSharingExpiresField=true and sharingExpiresAt is null',
    () async {
      late http.Request captured;

      final mockClient = MockClient((http.Request req) async {
        captured = req;
        final body = json.encode({
          'user_loc_id': 1,
          'user_id': 2,
          'latitude': 0.0,
          'longitude': 0.0,
          'is_enabled': true,
          'created_at': '2026-05-17T12:00:00Z',
          'updated_at': '2026-05-17T12:00:00Z',
          'sharing_expires_at': null,
        });
        return http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(storage: FakeStorage(), httpClient: mockClient);

      await api.updateUserLocation(
        includeSharingExpiresField: true,
        sharingExpiresAt: null,
      );

      expect(captured.method, equals('PATCH'));
      final Map<String, dynamic> sent =
          json.decode(captured.body) as Map<String, dynamic>;
      expect(sent.containsKey('sharing_expires_at'), isTrue);
      expect(sent['sharing_expires_at'], isNull);
    },
  );

  test('sends UTC ISO string when sharingExpiresAt is provided', () async {
    late http.Request captured;

    final mockClient = MockClient((http.Request req) async {
      captured = req;
      final body = json.encode({
        'user_loc_id': 1,
        'user_id': 2,
        'latitude': 0.0,
        'longitude': 0.0,
        'is_enabled': true,
        'created_at': '2026-05-17T12:00:00Z',
        'updated_at': '2026-05-17T12:00:00Z',
        'sharing_expires_at': '2026-05-17T12:00:00Z',
      });
      return http.Response(
        body,
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = ApiService(storage: FakeStorage(), httpClient: mockClient);

    final expiry = DateTime.utc(2026, 5, 17, 12, 0, 0);
    await api.updateUserLocation(
      includeSharingExpiresField: true,
      sharingExpiresAt: expiry,
    );

    expect(captured.method, equals('PATCH'));
    final Map<String, dynamic> sent =
        json.decode(captured.body) as Map<String, dynamic>;
    expect(sent.containsKey('sharing_expires_at'), isTrue);
    expect(
      sent['sharing_expires_at'],
      equals(expiry.toUtc().toIso8601String()),
    );
  });
}
