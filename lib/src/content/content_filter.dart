import '../models/ad_content.dart';
import '../models/content_delivery_response.dart';

/// Filters out expired ads from content delivery responses.
class ContentFilter {
  /// Return a new response with expired ads removed.
  ContentDeliveryResponse filterExpired(ContentDeliveryResponse response) {
    if (response.data == null) return response;

    final data = response.data!;
    return ContentDeliveryResponse(
      success: response.success,
      mobileId: response.mobileId,
      data: ContentDeliveryData(
        displayAd: _removeExpired(data.displayAd),
        videoAdHorizontal: _removeExpired(data.videoAdHorizontal),
        videoAdVertical: _removeExpired(data.videoAdVertical),
        leadAd: _removeExpired(data.leadAd),
        sponsoredProducts: _removeExpired(data.sponsoredProducts),
        recommendationProducts: _removeExpired(data.recommendationProducts),
        mobileNotifications: _removeExpired(data.mobileNotifications),
      ),
    );
  }

  List<AdContent> _removeExpired(List<AdContent> ads) {
    return ads.where((ad) => !ad.isExpired).toList();
  }
}
