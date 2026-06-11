/// Parses dimensions from server bannerType strings.
///
/// Known formats:
/// - `mobileAppBanner600x400` → 600×400
/// - `mobileAppVideo1920x1080` → 1920×1080
/// - `webAdvertising300x250` → 300×250
class BannerTypeParser {
  static const _dimensionPattern = r'(\d{2,4})x(\d{2,4})$';
  static final _regex = RegExp(_dimensionPattern);

  /// Parse width and height from a bannerType string.
  /// Returns null if the format is not recognized.
  static ({double width, double height})? parse(String? bannerType) {
    if (bannerType == null) return null;
    final match = _regex.firstMatch(bannerType);
    if (match == null) return null;

    final width = double.tryParse(match.group(1)!);
    final height = double.tryParse(match.group(2)!);
    if (width == null || height == null || width == 0 || height == 0) {
      return null;
    }

    return (width: width, height: height);
  }

  /// Get aspect ratio from a bannerType string.
  /// Returns null if the format is not recognized.
  static double? aspectRatio(String? bannerType) {
    final dims = parse(bannerType);
    if (dims == null) return null;
    return dims.width / dims.height;
  }
}

/// Controls how the ad widget determines its size.
enum AdSizing {
  /// Use dimensions from the server's bannerType field.
  /// Falls back to [fillParent] if bannerType is not parseable.
  fromServer,

  /// Ignore bannerType and fill the parent container.
  fillParent,
}
