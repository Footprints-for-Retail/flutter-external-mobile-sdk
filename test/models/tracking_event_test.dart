import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/models/tracking_event.dart';

void main() {
  group('TrackingEvent', () {
    test('reach event round-trip', () {
      const event = TrackingEvent(
        appkey: 'test-key',
        mid: 'c12345',
        requestType: 'reach',
      );

      final json = event.toJson();
      final restored = TrackingEvent.fromJson(json);

      expect(restored.appkey, 'test-key');
      expect(restored.mid, 'c12345');
      expect(restored.requestType, 'reach');
      expect(restored.additionalData, isNull);
    });

    test('impression event with additional data', () {
      const event = TrackingEvent(
        appkey: 'test-key',
        mid: 'c12345',
        requestType: 'impression',
        actionType: 'engagement',
        additionalData: {
          'campaignId': 'camp_001',
          'adId': 'ad_001',
          'scrollViewPercentage': 75.0,
        },
      );

      final json = event.toJson();
      expect(json['additionalData']['campaignId'], 'camp_001');
      expect(json['additionalData']['adId'], 'ad_001');
      expect(json['actionType'], 'engagement');
    });
  });
}
