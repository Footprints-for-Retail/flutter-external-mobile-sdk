import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/footprints_api_client.dart';
import '../models/init_request.dart';
import '../models/init_response.dart';
import '../models/sdk_result.dart';
import 'device_info_collector.dart';

/// Manages device registration and mobileId lifecycle.
class AuthManager {
  final FootprintsApiClient _apiClient;
  final FlutterSecureStorage _storage;
  final DeviceInfoCollector _deviceInfoCollector;

  String? _mobileId;

  AuthManager({
    required FootprintsApiClient apiClient,
    FlutterSecureStorage? storage,
    DeviceInfoCollector? deviceInfoCollector,
  })  : _apiClient = apiClient,
        _storage = storage ?? const FlutterSecureStorage(),
        _deviceInfoCollector = deviceInfoCollector ?? DeviceInfoCollector();

  /// Initialize: collect device info, register with server, persist mobileId.
  Future<SdkResult<InitResponse>> init({
    required String appKey,
    String? userEmail,
    String? userPhone,
    String? fcmToken,
    List<Map<String, dynamic>>? customVariables,
  }) async {
    try {
      final technicalInfo = await _deviceInfoCollector.collect();

      final request = InitRequest(
        appkey: appKey,
        technicalInfo: technicalInfo,
        userEmail: userEmail,
        userPhone: userPhone,
        pushNotificationToken: fcmToken,
        additionalData: customVariables,
      );

      final response = await _apiClient.initDevice(request);

      if (response.success && response.mobileId != null) {
        _mobileId = response.mobileId;
        await _storage.write(
          key: _storageKeyMobileId,
          value: _mobileId,
        );
      }

      return SdkResult.success(response);
    } catch (e) {
      return SdkResult.failure(e.toString());
    }
  }

  /// Get mobileId from memory cache or secure storage.
  Future<String?> getMobileId() async {
    _mobileId ??= await _storage.read(key: _storageKeyMobileId);
    return _mobileId;
  }

  /// Clear stored credentials.
  Future<void> clear() async {
    _mobileId = null;
    await _storage.delete(key: _storageKeyMobileId);
  }

  static const _storageKeyMobileId = 'footprints_mobile_id';
}
