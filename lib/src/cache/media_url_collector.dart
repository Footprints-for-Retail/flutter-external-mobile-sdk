import '../models/ad_content.dart';
import '../models/content_delivery_response.dart';

/// Collects every media URL in a content-delivery response.
///
/// Combines `displayAd` (includes sponsored posts), `videoAdHorizontal`,
/// `videoAdVertical`, and `leadAd`. Optionally filter by [bannerType] — this
/// is how the lazy pre-warmer narrows a warm to the URLs actually reachable
/// on the current screen.
class MediaUrlCollector {
  const MediaUrlCollector();

  Set<String> collectUrls(
    ContentDeliveryResponse response, {
    String? bannerType,
  }) {
    final data = response.data;
    if (data == null) return const <String>{};

    final buckets = <List<AdContent>>[
      data.displayAd,
      data.videoAdHorizontal,
      data.videoAdVertical,
      data.leadAd,
    ];

    final urls = <String>{};
    for (final bucket in buckets) {
      for (final ad in bucket) {
        if (bannerType != null && ad.bannerType != bannerType) continue;
        final url = ad.contentUrl?.trim();
        if (url != null && url.isNotEmpty) {
          urls.add(url);
        }
      }
    }
    return urls;
  }
}
