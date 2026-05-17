import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/location_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_location.dart';

class FakeApiThrow extends ApiService {
  FakeApiThrow() : super();

  @override
  Future<UserLocation> updateUserLocation({
    double? latitude,
    double? longitude,
    bool? isEnabled,
    DateTime? sharingExpiresAt,
    bool includeSharingExpiresField = false,
  }) async {
    throw ApiException('boom', statusCode: 500);
  }
}

void main() {
  test('expiry failure still clears local sharing state', () {
    final fake = FakeApiThrow();
    final provider = LocationProvider(apiService: fake);

    final now = DateTime.now().toUtc();
    final expiry = now.add(Duration(seconds: 2));
    final loc = UserLocation(
      userLocId: 1,
      userId: 2,
      latitude: 0,
      longitude: 0,
      isEnabled: true,
      createdAt: now,
      updatedAt: now,
      sharingExpiresAt: expiry,
    );

    fakeAsync((fa) {
      provider.setMyLocationForTest(loc);
      provider.startExpiryTimerForTest();

      fa.elapse(Duration(seconds: 3));

      // provider should have updated local state to disabled even though API failed
      final my = provider.myLocation;
      expect(my, isNotNull);
      expect(my!.isEnabled, isFalse);
      expect(my.sharingExpiresAt, isNull);
    });
  });
}
