import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/cache/media_url_collector.dart';
import 'package:footprints_sdk/src/models/ad_content.dart';
import 'package:footprints_sdk/src/models/content_delivery_response.dart';

void main() {
  group('MediaUrlCollector', () {
    const collector = MediaUrlCollector();

    AdContent ad(String url, {String? bannerType}) => AdContent(
          adId: url.hashCode.toString(),
          contentUrl: url,
          bannerType: bannerType,
        );

    test('collects URLs across displayAd, video (both), and leadAd', () {
      final response = ContentDeliveryResponse(
        success: true,
        data: ContentDeliveryData(
          displayAd: [ad('https://cdn/image-1.jpg', bannerType: 'default')],
          videoAdHorizontal: [
            ad('https://cdn/video-h.mp4', bannerType: 'mobileAppVideo1920x1080'),
          ],
          videoAdVertical: [
            ad('https://cdn/video-v.mp4', bannerType: 'mobileAppVideo1080x1920'),
          ],
          leadAd: [ad('https://cdn/lead.jpg', bannerType: 'default')],
        ),
      );

      final urls = collector.collectUrls(response);

      expect(urls, {
        'https://cdn/image-1.jpg',
        'https://cdn/video-h.mp4',
        'https://cdn/video-v.mp4',
        'https://cdn/lead.jpg',
      });
    });

    test('filters by bannerType when provided', () {
      final response = ContentDeliveryResponse(
        success: true,
        data: ContentDeliveryData(
          displayAd: [
            ad('https://cdn/a.jpg', bannerType: 'mobileAppBanner300x250'),
            ad('https://cdn/b.jpg', bannerType: 'default'),
          ],
          videoAdHorizontal: [
            ad('https://cdn/v-big.mp4', bannerType: 'mobileAppVideo1920x1080'),
            ad('https://cdn/v-small.mp4', bannerType: 'mobileAppVideo1080x1080'),
          ],
        ),
      );

      final big = collector.collectUrls(
        response,
        bannerType: 'mobileAppVideo1920x1080',
      );
      expect(big, {'https://cdn/v-big.mp4'});

      final banner = collector.collectUrls(
        response,
        bannerType: 'mobileAppBanner300x250',
      );
      expect(banner, {'https://cdn/a.jpg'});
    });

    test('ignores null/empty/whitespace URLs', () {
      final response = ContentDeliveryResponse(
        success: true,
        data: ContentDeliveryData(
          displayAd: [
            const AdContent(adId: 'none', contentUrl: null),
            const AdContent(adId: 'empty', contentUrl: ''),
            const AdContent(adId: 'ws', contentUrl: '   '),
            ad('https://cdn/real.jpg'),
          ],
        ),
      );

      final urls = collector.collectUrls(response);
      expect(urls, {'https://cdn/real.jpg'});
    });

    test('returns empty set when response has no data', () {
      const response = ContentDeliveryResponse(success: true);
      expect(collector.collectUrls(response), isEmpty);
    });
  });
}
