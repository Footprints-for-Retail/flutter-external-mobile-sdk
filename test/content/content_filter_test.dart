import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/content/content_filter.dart';
import 'package:footprints_sdk/src/models/ad_content.dart';
import 'package:footprints_sdk/src/models/content_delivery_response.dart';

void main() {
  group('ContentFilter', () {
    late ContentFilter filter;

    setUp(() {
      filter = ContentFilter();
    });

    test('removes expired ads', () {
      const response = ContentDeliveryResponse(
        success: true,
        data: ContentDeliveryData(
          displayAd: [
            AdContent(
              adId: 'active',
              expirationDate: '2099-12-31T23:59:59.000Z',
            ),
            AdContent(
              adId: 'expired',
              expirationDate: '2020-01-01T00:00:00.000Z',
            ),
          ],
        ),
      );

      final filtered = filter.filterExpired(response);
      expect(filtered.data!.displayAd, hasLength(1));
      expect(filtered.data!.displayAd.first.adId, 'active');
    });

    test('keeps ads with no expiration date', () {
      const response = ContentDeliveryResponse(
        success: true,
        data: ContentDeliveryData(
          displayAd: [
            AdContent(adId: 'no_expiry'),
          ],
        ),
      );

      final filtered = filter.filterExpired(response);
      expect(filtered.data!.displayAd, hasLength(1));
    });
  });
}
