import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_location.dart';
import '../models/location_permission.dart' as model;
import '../services/api_service.dart';

/// Manages the user's location sharing state and friend locations.
///
/// Handles:
/// - The user's own location record (create, toggle on/off)
/// - Polling friend locations every 20 seconds for the map
/// - Per-friend location permission management (grant/revoke)
///
/// Uses the same constructor injection pattern as FriendProvider.
class LocationProvider extends ChangeNotifier {
  final ApiService _apiService;

  // --- State ---

  /// The current user's location record, null if they haven't enabled sharing yet
  UserLocation? _myLocation;

  /// Locations of friends who are sharing with the current user
  List<UserLocation> _friendLocations = [];

  /// List of friends the current user is sharing their location with
  List<model.LocationPermission> _permissions = [];

  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;
  Timer? _sharingExpiryTimer;

  // --- Getters ---

  UserLocation? get myLocation => _myLocation;
  List<UserLocation> get friendLocations => _friendLocations;
  List<model.LocationPermission> get permissions => _permissions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Whether the user is currently sharing their location
  bool get isSharingEnabled => _myLocation?.isEnabled ?? false;

  // --- Constructor ---

  LocationProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // --- Lifecycle ---

  /// Fetch the user's own location, friend locations, and permissions.
  /// Call this when the map screen loads.
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to get the user's own location record
      // A 404 just means they haven't enabled sharing yet — that's fine
      try {
        _myLocation = await _apiService.getUserLocation();
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          _myLocation = null;
        } else {
          rethrow;
        }
      }

      // Fetch friend locations and permissions in parallel
      // Permissions returns 404 if the user has no location record — treat as empty
      _friendLocations = await _apiService.getFriendsLocations();
      try {
        _permissions = await _apiService.getLocationPermissions();
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          _permissions = [];
        } else {
          rethrow;
        }
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start polling every 20 seconds.
  /// Each tick fetches friend locations and, if sharing is enabled,
  /// pushes the user's current GPS coordinates to the backend.
  void startPolling() {
    // Don't create duplicate timers
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _refreshFriendLocations();
      _pushOwnLocationIfSharing();
    });
  }

  /// Stop polling. The map screen calls this in dispose.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // --- Actions ---

  /// Toggle the user's location sharing on or off.
  /// If no location record exists yet, creates one using the device's GPS.
  /// When re-enabling, refreshes GPS coordinates so the position is current.
  Future<void> toggleSharing({
    DateTime? expiry,
    bool clearExpiry = false,
  }) async {
    try {
      if (_myLocation == null) {
        // First time enabling — get device GPS and create a record
        await _createLocationFromGPS();
        if (_myLocation == null) return;

        // If caller provided an expiry, send it explicitly.
        if (expiry != null) {
          _myLocation = await _apiService.updateUserLocation(
            isEnabled: true,
            sharingExpiresAt: expiry,
            includeSharingExpiresField: true,
          );
        } else {
          // Ensure sharing is enabled server-side and explicitly clear any previous expiry
          _myLocation = await _apiService.updateUserLocation(
            isEnabled: true,
            sharingExpiresAt: null,
            includeSharingExpiresField: true,
          );
        }
        _scheduleSharingExpiryTimer();
      } else if (_myLocation!.isEnabled) {
        // Currently on → turn off (no GPS needed)
        _myLocation = await _apiService.updateUserLocation(isEnabled: false);
        _cancelSharingExpiryTimer();
      } else {
        // Currently off → turn on with fresh GPS coordinates
        final position = await getCurrentPosition();
        if (position == null) return; // GPS failed, error already set

        _myLocation = await _apiService.updateUserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          isEnabled: true,
          sharingExpiresAt: expiry,
          includeSharingExpiresField: (expiry != null) || clearExpiry,
        );
        _scheduleSharingExpiryTimer();
      }
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Get the device's current GPS position.
  /// Returns null if location services are unavailable or permission denied.
  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Location services are disabled. Please enable them.';
      notifyListeners();
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permission denied.';
        notifyListeners();
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _error = 'Location permission permanently denied. Enable in settings.';
      notifyListeners();
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Get the device's GPS position and create a location record on the backend.
  Future<void> _createLocationFromGPS() async {
    final position = await getCurrentPosition();
    if (position == null) return; // GPS failed, error already set

    _myLocation = await _apiService.createOrUpdateUserLocation(
      position.latitude,
      position.longitude,
    );
  }

  /// Share your location with a specific friend.
  /// Creates a location record first if one doesn't exist yet.
  Future<void> grantPermission(int friendId) async {
    try {
      // Make sure we have a location record before granting permission
      if (_myLocation == null) {
        await _createLocationFromGPS();
        if (_myLocation == null) return; // GPS failed, error already set
      }

      final perm = await _apiService.createLocationPermission(friendId);
      _permissions.add(perm);
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Stop sharing your location with a specific friend.
  Future<void> revokePermission(int friendId) async {
    try {
      await _apiService.deleteLocationPermission(friendId);
      _permissions.removeWhere((p) => p.userId == friendId);
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Manually refresh friend locations (also called by the polling timer).
  /// On failure, keeps the previous data so the map doesn't go blank.
  Future<void> _refreshFriendLocations() async {
    try {
      _friendLocations = await _apiService.getFriendsLocations();
      notifyListeners();
    } on ApiException {
      // Silently keep previous data — don't spam the user with errors
    }
  }

  /// Push the user's current GPS coordinates to the backend.
  /// Only runs when sharing is enabled so we don't waste battery/network.
  Future<void> _pushOwnLocationIfSharing() async {
    if (!isSharingEnabled) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      _myLocation = await _apiService.updateUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      // If the server returned an expiry, ensure the client timer is scheduled
      _scheduleSharingExpiryTimer();
    } on ApiException {
      // Silently ignore — next tick will retry
    } catch (_) {
      // GPS can fail (e.g. services disabled mid-session) — don't crash
    }
  }

  /// Reload the permissions list from the backend.
  /// Returns empty list if user has no location record yet (404).
  Future<void> refreshPermissions() async {
    try {
      _permissions = await _apiService.getLocationPermissions();
      _error = null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _permissions = [];
        _error = null;
      } else {
        _error = e.message;
      }
    } finally {
      notifyListeners();
    }
  }

  // --- Cleanup ---

  /// Clear all state on logout. Same pattern as FriendProvider.clear().
  void clear() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _cancelSharingExpiryTimer();
    _myLocation = null;
    _friendLocations = [];
    _permissions = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cancelSharingExpiryTimer();
    super.dispose();
  }

  void _cancelSharingExpiryTimer() {
    _sharingExpiryTimer?.cancel();
    _sharingExpiryTimer = null;
  }

  void _scheduleSharingExpiryTimer() {
    _cancelSharingExpiryTimer();
    final expiry = _myLocation?.sharingExpiresAt;
    if (expiry == null) return;

    final nowUtc = DateTime.now().toUtc();
    final expUtc = expiry.toUtc();
    final diff = expUtc.difference(nowUtc);
    if (diff.inMilliseconds <= 0) {
      // Already expired — handle immediately
      _handleSharingExpired();
      return;
    }

    _sharingExpiryTimer = Timer(diff, () {
      _handleSharingExpired();
    });
  }

  Future<void> _handleSharingExpired() async {
    try {
      // Attempt to turn off sharing on the server so friends stop seeing this user
      _myLocation = await _apiService.updateUserLocation(isEnabled: false);
    } on ApiException {
      // On failure, still update local state conservatively
      if (_myLocation != null) {
        _myLocation = UserLocation(
          userLocId: _myLocation!.userLocId,
          userId: _myLocation!.userId,
          latitude: _myLocation!.latitude,
          longitude: _myLocation!.longitude,
          isEnabled: false,
          createdAt: _myLocation!.createdAt,
          updatedAt: DateTime.now(),
          city: _myLocation!.city,
          street: _myLocation!.street,
          sharingExpiresAt: null,
        );
      }
    } finally {
      _cancelSharingExpiryTimer();
      notifyListeners();
    }
  }
}
