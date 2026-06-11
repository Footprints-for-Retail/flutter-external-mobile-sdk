import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/models/ad_content.dart';

void main() {
  group('AdContent', () {
    test('fromJson/toJson round-trip', () {
      const ad = AdContent(
        adType: 'displayAd',
        adId: 'ad_001',
        title: 'Test Ad',
        campaignName: 'Test Campaign',
        contentType: 'image',
        contentUrl: 'https://example.com/image.jpg',
        bannerType: 'mobileAppBanner600x400',
        campaignId: 'camp_001',
        linkUrl: 'https://example.com/click',
        expirationDate: '2099-12-31T23:59:59.000Z',
      );

      final json = ad.toJson();
      final restored = AdContent.fromJson(json);

      expect(restored.adType, ad.adType);
      expect(restored.adId, ad.adId);
      expect(restored.title, ad.title);
      expect(restored.bannerType, ad.bannerType);
      expect(restored.linkUrl, ad.linkUrl);
    });

    test('isExpired returns false for future date', () {
      const ad = AdContent(
        expirationDate: '2099-12-31T23:59:59.000Z',
      );
      expect(ad.isExpired, isFalse);
    });

    test('isExpired returns true for past date', () {
      const ad = AdContent(
        expirationDate: '2020-01-01T00:00:00.000Z',
      );
      expect(ad.isExpired, isTrue);
    });

    test('isExpired returns false when no expiration date', () {
      const ad = AdContent();
      expect(ad.isExpired, isFalse);
    });

    test('deserializes from fixture', () {
      final fixture = File('test/fixtures/content_delivery_response.json');
      final json = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
      final ads = (json['data']['displayAd'] as List)
          .map((e) => AdContent.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(ads, hasLength(1));
      expect(ads.first.bannerType, 'mobileAppBanner600x400');
      expect(ads.first.campaignId, 'camp_001');
    });
  });
}
