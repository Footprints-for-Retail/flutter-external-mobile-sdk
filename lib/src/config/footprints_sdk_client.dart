import 'dart:async';

import 'footprints_config.dart';
import '../api/footprints_api_client.dart';
import '../auth/auth_manager.dart';
import 'package:geolocator/geolocator.dart';

import '../cache/footprints_media_cache_manager.dart';
import '../cache/media_prewarmer.dart';
import '../content/content_cache.dart';
import '../content/content_manager.dart';
import '../content/rotation_selector.dart';
import '../location/location_manager.dart';
import '../models/ad_content.dart';
import '../storage/database_manager.dart';
import '../tracking/event_queue.dart';
import '../tracking/event_tracker.dart';
import '../models/init_response.dart';
import '../models/content_delivery_response.dart';
import '../models/sdk_result.dart';
import '../models/sponsored_product.dart';
import '../models/recommendation_product.dart';

/// Main entry point for the Footprints AI SDK.
///
/// Usage:
/// ```dart
/// final sdk = FootprintsSdk(
///   baseUrl: 'https://api.footprints-ai.com',
///   appKey: 'your-app-key',
/// );
/// final result = await sdk.init();
/// ```
class FootprintsSdk {
  final String baseUrl;
  final String appKey;
  final FootprintsConfig config;

  late final FootprintsApiClient _apiClient;
  late final AuthManager _authManager;
  late final ContentManager _contentManager;
  late final EventTracker _eventTracker;
  late final LocationManager _locationManager;
  late final DatabaseManager _dbManager;
  late final RotationSelector _rotationSelector;
  late final MediaPrewarmer _mediaPrewarmer;

  bool _initialized = false;

  FootprintsSdk({
    required this.baseUrl,
    required this.appKey,
    this.config = const FootprintsConfig(),
    DatabaseManager? databaseManager,
  }) {
    // Configure the shared media cache manager (singleton) before anything
    // constructs a reference to it.
    FootprintsMediaCacheManager.configure(
      maxBytes: config.mediaCacheMaxBytes,
      ttl: config.mediaCacheTtl,
    );
    _dbManager = databaseManager ?? DatabaseManager.forProduction();
    _rotationSelector = RotationSelector(
      storage: _dbManager.rotationStorage,
      strategy: config.rotationStrategy,
    );
    _apiClient = FootprintsApiClient(
      baseUrl: baseUrl,
      appKey: appKey,
      config: config,
    );
    _authManager = AuthManager(apiClient: _apiClient);
    _contentManager = ContentManager(
      apiClient: _apiClient,
      authManager: _authManager,
      appKey: appKey,
      cacheTtl: config.contentCacheTtl,
      cache: ContentCache(storage: _dbManager.contentStorage),
      onFreshFetch: (urls) =>
          FootprintsMediaCacheManager.instance.evictUrlsNotIn(urls),
    );
    _mediaPrewarmer = MediaPrewarmer(
      cache: FootprintsMediaCacheManager.instance,
      contentManager: _contentManager,
      budgetBytes: config.mediaCacheMaxBytes,
      logLevel: config.logLevel,
    );
    _eventTracker = EventTracker(
      apiClient: _apiClient,
      authManager: _authManager,
      appKey: appKey,
      batchSize: config.eventBatchSize,
      batchInterval: config.eventBatchInterval,
      enableOfflineQueue: config.enableOfflineQueue,
      queue: EventQueue(storage: _dbManager.eventStorage),
    );
    _locationManager = LocationManager(
      apiClient: _apiClient,
      authManager: _authManager,
      appKey: appKey,
    );
  }

  /// Initialize SDK: register device, get mobileId.
  Future<SdkResult<InitResponse>> init({
    String? userEmail,
    String? userPhone,
    String? fcmToken,
    List<Map<String, dynamic>>? customVariables,
  }) async {
    final result = await _authManager.init(
      appKey: appKey,
      userEmail: userEmail,
      userPhone: userPhone,
      fcmToken: fcmToken,
      customVariables: customVariables,
    );
    if (result.isSuccess) {
      _initialized = true;
      await _eventTracker.start();
    }
    return result;
  }

  /// Fetch content delivery for a screen.
  Future<SdkResult<ContentDeliveryResponse>> getContentDelivery({
    String? screenIdentifier,
    Map<String, dynamic>? additionalData,
  }) async {
    _assertInitialized();
    return _contentManager.getContent(
      screenIdentifier: screenIdentifier,
      additionalData: additionalData,
    );
  }

  /// Pick one ad from a list of candidates using the configured rotation
  /// strategy. Used by widgets to rotate across multiple creatives matching
  /// the same placement. Returns null if [candidates] is empty.
  Future<AdContent?> pickAd(
    List<AdContent> candidates, {
    required String rotationKey,
  }) {
    return _rotationSelector.pick(candidates, rotationKey: rotationKey);
  }

  /// Track an ad impression.
  Future<SdkResult<void>> trackImpression({
    required String campaignId,
    required String adId,
    String? actionType,
    double? scrollPercent,
    Duration? screenOnTime,
  }) async {
    _assertInitialized();
    return _eventTracker.trackImpression(
      campaignId: campaignId,
      adId: adId,
      actionType: actionType,
      scrollPercent: scrollPercent,
      screenOnTime: screenOnTime,
    );
  }

  /// Get sponsored products (full data).
  Future<SdkResult<SponsoredProductsResponse>> getSponsoredProducts({
    Map<String, dynamic>? additionalData,
  }) async {
    _assertInitialized();
    final mid = await _authManager.getMobileId();
    return SdkResult.fromFuture(
      () => _apiClient.getSponsoredProductsJson(
        appKey: appKey,
        mid: mid!,
        additionalData: additionalData,
      ),
    );
  }

  /// Get sponsored product IDs only.
  Future<SdkResult<SponsoredProductsResponse>> getSponsoredProductIds({
    Map<String, dynamic>? additionalData,
  }) async {
    _assertInitialized();
    final mid = await _authManager.getMobileId();
    return SdkResult.fromFuture(
      () => _apiClient.getSponsoredProductIds(
        appKey: appKey,
        mid: mid!,
        additionalData: additionalData,
      ),
    );
  }

  /// Get recommendation products.
  Future<SdkResult<RecommendationProductsResponse>> getRecommendations({
    required String searchQuery,
    Map<String, dynamic>? additionalData,
  }) async {
    _assertInitialized();
    final mid = await _authManager.getMobileId();
    return SdkResult.fromFuture(
      () => _apiClient.getRecommendationProducts(
        appKey: appKey,
        mid: mid!,
        searchQuery: searchQuery,
        additionalData: additionalData,
      ),
    );
  }

  /// Search within recommendations.
  Future<SdkResult<RecommendationProductsResponse>> searchRecommendations({
    required String query,
    Map<String, dynamic>? additionalData,
  }) async {
    _assertInitialized();
    final mid = await _authManager.getMobileId();
    return SdkResult.fromFuture(
      () => _apiClient.searchRecommendationProducts(
        appKey: appKey,
        mid: mid!,
        searchQuery: query,
        additionalData: additionalData,
      ),
    );
  }

  /// Get current location, send to server, and optionally store locally.
  ///
  /// Matches Android SDK's `getCurrentLocation(storeInDB, callback)` pattern.
  /// Requires location permissions — will request if not already granted.
  Future<SdkResult<Position>> getCurrentLocation({
    bool storeInDB = false,
  }) async {
    _assertInitialized();
    return _locationManager.getCurrentLocation(storeInDB: storeInDB);
  }

  /// Check location permission status.
  Future<SdkResult<bool>> checkLocationPermission() async {
    return _locationManager.checkPermission();
  }

  /// Update device geo-location manually (without using GPS).
  Future<SdkResult<void>> updateGeo({
    required double lat,
    required double lon,
    double? accuracy,
  }) async {
    _assertInitialized();
    return _locationManager.updateLocation(
      lat: lat,
      lon: lon,
      accuracy: accuracy,
    );
  }

  /// Pre-warm the media cache for a screen's ads. Called by ad widgets on
  /// mount (controlled by `FootprintsConfig.mediaPrewarmEnabled`).
  ///
  /// Reads the cached content-delivery response for [screenIdentifier] and
  /// enqueues background downloads for URLs matching [bannerType]. Safe to
  /// call repeatedly; no-op if pre-warm is disabled or no cached response
  /// is available yet.
  Future<void> prewarmMediaForBannerType(
    String? bannerType, {
    String? screenIdentifier,
  }) async {
    if (!config.mediaPrewarmEnabled) return;
    await _mediaPrewarmer.prewarmForBannerType(
      bannerType,
      screenIdentifier: screenIdentifier,
    );
  }

  /// Size in bytes of the SDK's on-disk unified media cache.
  Future<int> mediaCacheSize() =>
      FootprintsMediaCacheManager.instance.totalSize();

  /// Clears the SDK's media cache. Next ad render will re-download from CDN.
  Future<void> clearMediaCache() =>
      FootprintsMediaCacheManager.instance.clearAll();

  /// Dispose SDK resources.
  Future<void> dispose() async {
    await _eventTracker.stop();
    await _dbManager.close();
  }

  void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'FootprintsSdk.init() must be called before using other methods.',
      );
    }
  }
}
