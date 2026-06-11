import 'dart:async';

import '../api/footprints_api_client.dart';
import '../auth/auth_manager.dart';
import '../cache/media_url_collector.dart';
import '../models/content_delivery_response.dart';
import '../models/sdk_result.dart';
import 'content_cache.dart';
import 'content_filter.dart';

/// Orchestrates content delivery with single-fetch-many-consumers pattern.
///
/// Solves the Android SDK's duplicate-fetch problem: one fetch per TTL,
/// distributed to all widget consumers.
class ContentManager {
  final FootprintsApiClient _apiClient;
  final AuthManager _authManager;
  final String _appKey;
  final ContentCache _cache;
  final ContentFilter _filter;
  final Duration _cacheTtl;
  final MediaUrlCollector _urlCollector;

  /// In-flight request deduplication.
  Completer<SdkResult<ContentDeliveryResponse>>? _inflightRequest;

  /// Optional hook invoked after every fresh (non-cache-hit) successful
  /// fetch with the full URL set from that response. Wired by
  /// [FootprintsSdk] to run the media-cache invalidation sweep.
  final Future<void> Function(Set<String> urls)? onFreshFetch;

  ContentManager({
    required FootprintsApiClient apiClient,
    required AuthManager authManager,
    required String appKey,
    Duration cacheTtl = const Duration(minutes: 5),
    ContentCache? cache,
    ContentFilter? filter,
    MediaUrlCollector? urlCollector,
    this.onFreshFetch,
  })  : _apiClient = apiClient,
        _authManager = authManager,
        _appKey = appKey,
        _cacheTtl = cacheTtl,
        _cache = cache ?? ContentCache(),
        _filter = filter ?? ContentFilter(),
        _urlCollector = urlCollector ?? const MediaUrlCollector();

  /// Get content delivery, using cache if available within TTL.
  Future<SdkResult<ContentDeliveryResponse>> getContent({
    String? screenIdentifier,
    Map<String, dynamic>? additionalData,
  }) async {
    // additionalData from caller is a single map; we wrap it into the array format
    // Check cache first
    final cached = await _cache.get(screenIdentifier);
    if (cached != null) {
      final filtered = _filter.filterExpired(cached);
      return SdkResult.success(filtered);
    }

    // Deduplicate in-flight requests
    if (_inflightRequest != null) {
      return _inflightRequest!.future;
    }

    _inflightRequest = Completer<SdkResult<ContentDeliveryResponse>>();

    try {
      final mid = await _authManager.getMobileId();
      if (mid == null) {
        const result = SdkResult<ContentDeliveryResponse>.failure(
          'SDK not initialized — mobileId is null',
        );
        _inflightRequest!.complete(result);
        return result;
      }

      // Server expects additionalData as an array, not an object
      final mergedAdditionalData = <Map<String, dynamic>>[
        if (screenIdentifier != null) {'screenIdentifier': screenIdentifier},
        if (additionalData != null) additionalData,
      ];

      final response = await _apiClient.getContentDelivery(
        appKey: _appKey,
        mid: mid,
        additionalData:
            mergedAdditionalData.isNotEmpty ? mergedAdditionalData : null,
      );

      await _cache.put(screenIdentifier, response, ttl: _cacheTtl);

      // Fire the fresh-fetch hook (media-cache invalidation sweep) without
      // blocking the response — widgets should render immediately.
      final hook = onFreshFetch;
      if (hook != null) {
        final urls = _urlCollector.collectUrls(response);
        unawaited(hook(urls).catchError((_) {}));
      }

      final filtered = _filter.filterExpired(response);
      final result = SdkResult.success(filtered);
      _inflightRequest!.complete(result);
      return result;
    } catch (e) {
      final result = SdkResult<ContentDeliveryResponse>.failure(e.toString());
      _inflightRequest!.complete(result);
      return result;
    } finally {
      _inflightRequest = null;
    }
  }

  /// Returns the most recent cached response for [screenIdentifier] without
  /// triggering a network fetch. Used by the media pre-warmer.
  Future<ContentDeliveryResponse?> peekCached(String? screenIdentifier) {
    return _cache.get(screenIdentifier);
  }

  /// Invalidate all cached content.
  Future<void> invalidateCache() async {
    await _cache.clear();
  }
}

