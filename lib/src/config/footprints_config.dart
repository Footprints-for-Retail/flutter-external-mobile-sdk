import '../content/rotation_selector.dart';
import 'log_level.dart';

/// SDK-wide configuration with sensible defaults.
class FootprintsConfig {
  final bool enableLocation;
  final bool enableOfflineQueue;
  final Duration contentCacheTtl;
  final int eventBatchSize;
  final Duration eventBatchInterval;
  final Duration connectTimeout;
  final Duration readTimeout;
  final int maxRetryAttempts;
  final LogLevel logLevel;

  /// Strategy used when multiple ads are available for the same placement
  /// (e.g., several campaigns targeting the same `bannerType`). Default:
  /// round-robin with a persistent cursor so each render shows the next ad.
  final RotationStrategy rotationStrategy;

  /// Maximum on-disk size of the SDK's unified media cache (images + videos).
  ///
  /// Default: 100 MB. The cache is a best-effort optimization keyed by CDN
  /// URL; if a single file would exceed this budget, the widget falls back
  /// to streaming directly from the URL.
  final int mediaCacheMaxBytes;

  /// Time after which a cached media file is considered stale and evicted.
  ///
  /// Default: 10 days. Note that content-driven invalidation (URLs disappearing
  /// from content-delivery responses) typically evicts stale creatives well
  /// before this TTL fires.
  final Duration mediaCacheTtl;

  /// When true (default), the SDK pre-warms the media cache for a screen's
  /// bannerType URLs in the background when an ad widget mounts.
  ///
  /// Set to `false` for low-bandwidth scenarios — each ad then downloads only
  /// when it scrolls into view.
  final bool mediaPrewarmEnabled;

  const FootprintsConfig({
    this.enableLocation = false,
    this.enableOfflineQueue = true,
    this.contentCacheTtl = const Duration(minutes: 5),
    this.eventBatchSize = 10,
    this.eventBatchInterval = const Duration(seconds: 15),
    this.connectTimeout = const Duration(seconds: 15),
    this.readTimeout = const Duration(seconds: 30),
    this.maxRetryAttempts = 3,
    this.logLevel = LogLevel.none,
    this.rotationStrategy = RotationStrategy.roundRobin,
    this.mediaCacheMaxBytes = 100 * 1024 * 1024,
    this.mediaCacheTtl = const Duration(days: 10),
    this.mediaPrewarmEnabled = true,
  });
}
