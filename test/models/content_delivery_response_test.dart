import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/models/content_delivery_response.dart';

void main() {
  group('ContentDeliveryResponse', () {
    test('deserializes from fixture', () {
      final fixture = File('test/fixtures/content_delivery_response.json');
      final json = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
      final response = ContentDeliveryResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.mobileId, 'c1234567890abcdef');
      expect(response.data, isNotNull);
      expect(response.data!.displayAd, hasLength(1));
      expect(response.data!.videoAdHorizontal, isEmpty);
      expect(response.data!.leadAd, isEmpty);
    });

    test('fromJson/toJson round-trip', () {
      const response = ContentDeliveryResponse(
        success: true,
        mobileId: 'test-mid',
        data: ContentDeliveryData(),
      );

      final json = jsonDecode(jsonEncode(response.toJson())) as Map<String, dynamic>;
      final restored = ContentDeliveryResponse.fromJson(json);

      expect(restored.success, isTrue);
      expect(restored.mobileId, 'test-mid');
      expect(restored.data!.displayAd, isEmpty);
    });
  });
}
