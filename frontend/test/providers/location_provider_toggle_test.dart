import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/location_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_location.dart';

class FakeApiToggle extends ApiService {
  int updateCalls = 0;
  bool? lastIsEnabled;

  FakeApiToggle() : super();

  @override
  Future<UserLocation> updateUserLocation({
    double? latitude,
    double? longitude,
    bool? isEnabled,
    DateTime? sharingExpiresAt,
    bool includeSharingExpiresField = false,
  }) async {
    updateCalls += 1;
    lastIsEnabled = isEnabled;
    return UserLocation(
      userLocId: 1,
      userId: 2,
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      isEnabled: isEnabled ?? false,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      sharingExpiresAt: sharingExpiresAt,
    );
  }
}

void main() {
  test('toggleSharing turns off sharing when currently enabled', () async {
    final fake = FakeApiToggle();
    final provider = LocationProvider(apiService: fake);

    final now = DateTime.now().toUtc();
    final loc = UserLocation(
      userLocId: 1,
      userId: 2,
      latitude: 0,
      longitude: 0,
      isEnabled: true,
      createdAt: now,
      updatedAt: now,
    );

    fakeAsync((fa) {
      provider.setMyLocationForTest(loc);
      // call toggleSharing to turn off
      provider.toggleSharing();

      // no timers involved — toggleSharing should call updateUserLocation synchronously
      expect(fake.updateCalls, 1);
      expect(fake.lastIsEnabled, isFalse);
    });
  });
}
