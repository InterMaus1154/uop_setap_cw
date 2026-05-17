import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/location_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_location.dart';
// Using a small fake ApiService subclass here avoids Mockito codegen
// complexities and lets us assert updateUserLocation was called.

// Create a Mockito mock for ApiService
class FakeApi extends ApiService {
  int updateCalls = 0;

  FakeApi() : super();

  @override
  Future<UserLocation> updateUserLocation({
    double? latitude,
    double? longitude,
    bool? isEnabled,
    DateTime? sharingExpiresAt,
    bool includeSharingExpiresField = false,
  }) async {
    updateCalls += 1;
    return UserLocation(
      userLocId: 1,
      userId: 2,
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      isEnabled: isEnabled ?? false,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      sharingExpiresAt: null,
    );
  }
}

void main() {
  test('schedules expiry timer and disables sharing on expiry', () {
    final fakeApi = FakeApi();
    final provider = LocationProvider(apiService: fakeApi);

    // seed provider with a location expiring in 2 seconds
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
      // no external stubbing required; FakeApi counts calls and returns a value

      provider.setMyLocationForTest(
        loc,
      ); // you may need to add a test helper setter
      provider.startExpiryTimerForTest(); // or call internal scheduler method

      // advance past expiry
      fa.elapse(Duration(seconds: 3));

      // verify updateUserLocation was invoked once
      expect(fakeApi.updateCalls, 1);
    });
  });
}
