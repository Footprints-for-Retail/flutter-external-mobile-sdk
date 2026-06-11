import 'dart:async';

import '../config/log_level.dart';
import '../content/content_manager.dart';
import 'footprints_media_cache_manager.dart';
import 'media_url_collector.dart';

/// Lazy media pre-warmer.
///
/// On ad-widget mount, reads the most recently cached content-delivery
/// response via [ContentManager.peekCached] and enqueues background
/// downloads for every URL matching the requested [bannerType] that is
/// not already cached.
///
/// Downloads are fire-and-forget — callers never await them, and a failure
/// to warm never surfaces to the widget. See
/// `docs/flutter_implementation/10-media-cache-strategy.md` §4.3.
class MediaPrewarmer {
  final FootprintsMediaCacheManager _cache;
  final ContentManager _contentManager;
  final MediaUrlCollector _collector;
  final LogLevel _logLevel;
  final int _budgetBytes;

  MediaPrewarmer({
    required FootprintsMediaCacheManager cache,
    required ContentManager contentManager,
    required int budgetBytes,
    MediaUrlCollector collector = const MediaUrlCollector(),
    LogLevel logLevel = LogLevel.none,
  })  : _cache = cache,
        _contentManager = contentManager,
        _collector = collector,
        _budgetBytes = budgetBytes,
        _logLevel = logLevel;

  /// Enqueue background warms for URLs matching [bannerType] on the screen
  /// identified by [screenIdentifier].
  Future<void> prewarmForBannerType(
    String? bannerType, {
    String? screenIdentifier,
  }) async {
    try {
      final response = await _contentManager.peekCached(screenIdentifier);
      if (response == null) return;

      final urls = _collector.collectUrls(response, bannerType: bannerType);
      if (urls.isEmpty) return;

      var occupied = await _cache.totalSize();

      for (final url in urls) {
        // Skip if already cached.
        final existing = await _cache.getFileForUrl(url);
        if (existing != null) {
          _debug('prewarm skip (cached): $url');
          continue;
        }

        // Naive budget pre-check: if we're already over budget, let the
        // cache's own LRU handle churn rather than add more pressure.
        if (occupied >= _budgetBytes) {
          _debug('prewarm skip (budget full): $url');
          continue;
        }

        // Fire-and-forget — do not block the caller.
        unawaited(_cache.prewarm(url));
        _debug('prewarm enqueue: $url');
        // Nudge the running total forward by the blended average so a
        // burst of enqueues doesn't all pass the budget check.
        occupied += 500 * 1024;
      }
    } catch (_) {
      // Pre-warm is opportunistic; never surface errors.
    }
  }

  void _debug(String message) {
    if (_logLevel.index >= LogLevel.debug.index) {
      // Routed through print to keep a zero-dependency log path. Integrators
      // who want structured logs should attach their own LogLevel handler.
      // ignore: avoid_print
      print('[footprints_sdk] media_prewarmer: $message');
    }
  }
}
