import 'package:geolocator/geolocator.dart';

import '../api/footprints_api_client.dart';
import '../auth/auth_manager.dart';
import '../models/sdk_result.dart';
import 'location_storage.dart';

/// Manages location updates and geo API calls.
///
/// Matches Android SDK behavior:
/// - Uses FusedLocationProvider (via geolocator package) with high accuracy
/// - Checks and requests permissions before fetching
/// - Optionally stores location in local SQLite DB
/// - Sends location to server via PUT /mobileapi/geo
///
/// Location features are opt-in via [FootprintsConfig.enableLocation].
class LocationManager {
  final FootprintsApiClient _apiClient;
  final AuthManager _authManager;
  final String _appKey;
  final LocationStorage _storage;

  LocationManager({
    required FootprintsApiClient apiClient,
    required AuthManager authManager,
    required String appKey,
    LocationStorage? storage,
  })  : _apiClient = apiClient,
        _authManager = authManager,
        _appKey = appKey,
        _storage = storage ?? LocationStorage();

  /// Check if location services are enabled and permissions are granted.
  Future<SdkResult<bool>> checkPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const SdkResult.failure(
          'Location services are disabled',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const SdkResult.failure(
            'Location permission denied',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const SdkResult.failure(
          'Location permission permanently denied',
        );
      }

      return const SdkResult.success(true);
    } catch (e) {
      return SdkResult.failure(e.toString());
    }
  }

  /// Get current location, send to server, and optionally store in DB.
  ///
  /// Matches Android SDK's `getCurrentLocation(storeInDB, callback)` pattern.
  Future<SdkResult<Position>> getCurrentLocation({
    bool storeInDB = false,
  }) async {
    try {
      // Check permissions
      final permResult = await checkPermission();
      if (!permResult.isSuccess) {
        return SdkResult.failure(permResult.error ?? 'Permission denied');
      }

      // Get position (high accuracy, matches Android PRIORITY_HIGH_ACCURACY).
      // geolocator 13+ supplies accuracy via LocationSettings rather than the
      // deprecated `desiredAccuracy` parameter.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Send to server (fire-and-forget, matches Android SDK)
      _sendToServer(position);

      // Store in local DB if requested (matches Android storeInDB param)
      if (storeInDB) {
        await _storage.insert(position);
      }

      return SdkResult.success(position);
    } catch (e) {
      return SdkResult.failure(e.toString());
    }
  }

  /// Send location to server without waiting for response.
  /// Matches Android SDK's fire-and-forget pattern.
  void _sendToServer(Position position) {
    _authManager.getMobileId().then((mid) {
      if (mid == null) return;
      _apiClient.updateGeo(
        appKey: _appKey,
        mid: mid,
        lat: position.latitude,
        lon: position.longitude,
        accuracy: position.accuracy,
      );
    });
  }

  /// Send a manual location update to the server.
  Future<SdkResult<void>> updateLocation({
    required double lat,
    required double lon,
    double? accuracy,
  }) async {
    try {
      final mid = await _authManager.getMobileId();
      if (mid == null) {
        return const SdkResult.failure('SDK not initialized');
      }

      await _apiClient.updateGeo(
        appKey: _appKey,
        mid: mid,
        lat: lat,
        lon: lon,
        accuracy: accuracy,
      );
      return const SdkResult.success(null);
    } catch (e) {
      return SdkResult.failure(e.toString());
    }
  }

  /// Get stored locations from local DB.
  Future<List<Map<String, dynamic>>> getStoredLocations() {
    return _storage.getAll();
  }

  /// Clear stored locations.
  Future<void> clearStoredLocations() {
    return _storage.deleteAll();
  }
}
