import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// SDK-owned unified media cache for images and videos.
///
/// One disk store, one LRU, one TTL. Keyed by CDN URL — the Footprints
/// platform guarantees a new URL for every replacement creative, so
/// URL-identity is a safe invalidation key.
///
/// The widgets use this via `cacheManager:` on `CachedNetworkImage` and
/// via [getFileForUrl] / [prewarm] on the video widget. See
/// `docs/flutter_implementation/10-media-cache-strategy.md`.
class FootprintsMediaCacheManager extends CacheManager {
  /// Sqflite DB / subdir name under `<temp>/footprints_sdk/media`.
  static const String _cacheKey = 'footprints_sdk_media';

  /// Approximate average file size used to convert a byte budget into
  /// `flutter_cache_manager`'s object-count cap. 500 KB is a reasonable
  /// blended average across image + video (heavy on videos).
  static const int _avgBytesPerObject = 500 * 1024;

  /// Floor on the object-count cap, so a tiny byte budget still accommodates
  /// a meaningful number of small creatives.
  static const int _minCacheObjectCount = 50;

  static FootprintsMediaCacheManager? _instance;
  static int _configuredMaxBytes = 100 * 1024 * 1024;
  static Duration _configuredTtl = const Duration(days: 10);

  FootprintsMediaCacheManager._(super.config);

  /// Returns the process-wide singleton, constructing it lazily from the
  /// most recently configured parameters (or defaults if never configured).
  static FootprintsMediaCacheManager get instance {
    return _instance ??= FootprintsMediaCacheManager._(
      Config(
        _cacheKey,
        stalePeriod: _configuredTtl,
        maxNrOfCacheObjects: _objectCap(_configuredMaxBytes),
      ),
    );
  }

  /// Configure the singleton. Safe to call once from [FootprintsSdk]'s
  /// constructor. Calling again with different values is a no-op for the
  /// already-constructed singleton — the underlying `flutter_cache_manager`
  /// instance is immutable at construction time.
  static void configure({
    required int maxBytes,
    required Duration ttl,
  }) {
    _configuredMaxBytes = maxBytes;
    _configuredTtl = ttl;
    // If the singleton has not yet been constructed, this takes effect on
    // first access. If it has, we deliberately do NOT rebuild it — swapping
    // managers mid-flight would orphan in-flight downloads and confuse
    // `CachedNetworkImage` widgets that captured the previous reference.
  }

  /// Test-only reset. Does not close the backing DB.
  static void resetForTesting() {
    _instance = null;
    _configuredMaxBytes = 100 * 1024 * 1024;
    _configuredTtl = const Duration(days: 10);
  }

  static int _objectCap(int maxBytes) {
    final approx = maxBytes ~/ _avgBytesPerObject;
    return approx < _minCacheObjectCount ? _minCacheObjectCount : approx;
  }

  /// Total bytes currently on disk. Sums `length` over every `CacheObject`.
  Future<int> totalSize() async {
    try {
      final objects = await config.repo.getAllObjects();
      var total = 0;
      for (final o in objects) {
        total += o.length ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Empties the cache (files + metadata).
  Future<void> clearAll() async {
    try {
      await emptyCache();
    } catch (_) {
      // Best-effort — if the backing store is unavailable, the widgets
      // will simply fall through to network fetches.
    }
  }

  /// Evict any cached URL that is not in [keepUrls]. Fire-and-forget; the
  /// caller should not block on this.
  Future<void> evictUrlsNotIn(Set<String> keepUrls) async {
    try {
      final objects = await config.repo.getAllObjects();
      for (final o in objects) {
        if (!keepUrls.contains(o.url) && !keepUrls.contains(o.key)) {
          await removeFile(o.key);
        }
      }
    } catch (_) {
      // Swallow — eviction is opportunistic. TTL will clean up eventually.
    }
  }

  /// Returns the cached file if present, else null. Does NOT trigger a
  /// download.
  Future<io.File?> getFileForUrl(String url) async {
    try {
      final info = await getFileFromCache(url);
      if (info == null) return null;
      // `package:file/file.dart` File has a .path; we re-wrap as dart:io.File
      // for callers (VideoPlayerController.file takes dart:io.File).
      return io.File(info.file.path);
    } catch (_) {
      return null;
    }
  }

  /// Triggers a download into the cache (if not already present). Returns
  /// the resulting file when ready. Callers should generally fire-and-forget.
  Future<io.File?> prewarm(String url) async {
    try {
      final file = await getSingleFile(url);
      return io.File(file.path);
    } catch (_) {
      return null;
    }
  }

  /// Tries the cache first; returns null (caller should stream from URL) if
  /// not cached, and kicks off a background download so the next mount hits
  /// cache.
  Future<io.File?> getOrStream(String url) async {
    final cached = await getFileForUrl(url);
    if (cached != null) return cached;
    // Fire-and-forget background warm.
    unawaited(prewarm(url));
    return null;
  }
}
