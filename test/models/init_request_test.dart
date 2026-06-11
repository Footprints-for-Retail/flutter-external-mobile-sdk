import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/models/init_request.dart';
import 'package:footprints_sdk/src/models/technical_info.dart';

void main() {
  group('InitRequest', () {
    test('fromJson/toJson round-trip', () {
      const request = InitRequest(
        appkey: 'test-app-key',
        technicalInfo: TechnicalInfo(
          screenSize: '1080x2400',
          deviceType: 'Smartphone',
          deviceOs: 'Android 14',
          deviceUuid: 'test-uuid-001',
          androidAdvertisingId: 'gaid-001',
        ),
        userEmail: 'test@example.com',
        pushNotificationToken: 'fcm-token-001',
      );

      final json =
          jsonDecode(jsonEncode(request.toJson())) as Map<String, dynamic>;
      final restored = InitRequest.fromJson(json);

      expect(restored.appkey, request.appkey);
      expect(restored.technicalInfo.screenSize, '1080x2400');
      expect(restored.technicalInfo.deviceType, 'Smartphone');
      expect(restored.technicalInfo.deviceOs, 'Android 14');
      expect(restored.userEmail, 'test@example.com');
      expect(restored.pushNotificationToken, 'fcm-token-001');
    });

    test('omits null fields', () {
      const request = InitRequest(
        appkey: 'test-key',
        technicalInfo: TechnicalInfo(
          screenSize: '1080x2400',
          deviceType: 'Smartphone',
          deviceOs: 'Android 14',
        ),
      );

      final json = request.toJson();
      expect(json.containsKey('pushNotificationToken'), isFalse);
      expect(json.containsKey('additionalData'), isFalse);
      expect(json.containsKey('userEmail'), isFalse);
      expect(json.containsKey('userPhone'), isFalse);
      expect(json.containsKey('mid'), isFalse);
    });

    test('includes userEmail and userPhone when provided', () {
      const request = InitRequest(
        appkey: 'test-key',
        technicalInfo: TechnicalInfo(
          screenSize: '1080x2400',
          deviceType: 'Smartphone',
          deviceOs: 'Android 14',
        ),
        userEmail: 'user@shop.com',
        userPhone: '+40712345678',
      );

      final json = request.toJson();
      expect(json['userEmail'], 'user@shop.com');
      expect(json['userPhone'], '+40712345678');
    });

    test('additionalData uses attributeName/attributeValue format', () {
      const request = InitRequest(
        appkey: 'test-key',
        technicalInfo: TechnicalInfo(
          screenSize: '1080x2400',
          deviceType: 'Smartphone',
          deviceOs: 'Android 14',
        ),
        additionalData: [
          {'attributeName': 'loyaltyTier', 'attributeValue': 'gold'},
          {'attributeName': 'storeId', 'attributeValue': '42'},
        ],
      );

      final json = request.toJson();
      expect(json['additionalData'], hasLength(2));
      expect(json['additionalData'][0]['attributeName'], 'loyaltyTier');
      expect(json['additionalData'][0]['attributeValue'], 'gold');
    });
  });
}
