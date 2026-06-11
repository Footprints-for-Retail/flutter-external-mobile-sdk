import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';

import '../models/technical_info.dart';

/// Collects device technical information for init registration.
class DeviceInfoCollector {
  final DeviceInfoPlugin _deviceInfo;

  DeviceInfoCollector({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Collect all available device information.
  Future<TechnicalInfo> collect() async {
    if (Platform.isAndroid) {
      return _collectAndroid();
    } else if (Platform.isIOS) {
      return _collectIos();
    }
    return _collectFallback();
  }

  Future<TechnicalInfo> _collectAndroid() async {
    final info = await _deviceInfo.androidInfo;

    // Get screen size from PlatformDispatcher (device_info_plus doesn't expose display metrics)
    final display = PlatformDispatcher.instance.views.first.display;
    final screenSize = '${display.size.width.toInt()}x${display.size.height.toInt()}';

    return TechnicalInfo(
      screenSize: screenSize,
      deviceType: info.isPhysicalDevice ? 'Smartphone' : 'Emulator',
      deviceOs: 'Android ${info.version.release}',
      deviceId: info.id,
      deviceUuid: info.id,
    );
  }

  Future<TechnicalInfo> _collectIos() async {
    final info = await _deviceInfo.iosInfo;

    final display = PlatformDispatcher.instance.views.first.display;
    final screenSize = '${display.size.width.toInt()}x${display.size.height.toInt()}';

    return TechnicalInfo(
      screenSize: screenSize,
      deviceType: info.model.contains('iPad') ? 'Tablet' : 'Smartphone',
      deviceOs: 'iOS ${info.systemVersion}',
      deviceUuid: info.identifierForVendor,
    );
  }

  TechnicalInfo _collectFallback() {
    return const TechnicalInfo(
      screenSize: 'unknown',
      deviceType: 'unknown',
      deviceOs: 'unknown',
    );
  }
}
