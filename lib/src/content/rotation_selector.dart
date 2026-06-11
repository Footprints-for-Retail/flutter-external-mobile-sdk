import 'dart:math';

import '../models/ad_content.dart';
import '../storage/rotation_storage_backend.dart';

/// Rotation strategy for picking an ad from a list of candidates.
enum RotationStrategy {
  /// Always return the first candidate (no rotation).
  none,

  /// Cycle through candidates in order, persisting the cursor to disk.
  /// After the last ad, wraps back to the first.
  roundRobin,

  /// Pick a random candidate each time. No state.
  random,
}

/// Picks which ad to render when multiple ads are available for the same
/// placement (e.g., same `bannerType` across multiple campaigns).
///
/// The selector does NOT know about banner types or content types — it just
/// receives a pre-filtered list of candidates plus a rotation key. Callers
/// are responsible for filtering + constructing the key.
class RotationSelector {
  final RotationStorageBackend _storage;
  final RotationStrategy _strategy;
  final Random _random;

  RotationSelector({
    required RotationStorageBackend storage,
    RotationStrategy strategy = RotationStrategy.roundRobin,
    Random? random,
  })  : _storage = storage,
        _strategy = strategy,
        _random = random ?? Random();

  /// Pick an ad from [candidates] using the configured [strategy].
  ///
  /// Returns null if [candidates] is empty. Advances the rotation cursor
  /// (when applicable) so the next call returns a different ad.
  Future<AdContent?> pick(
    List<AdContent> candidates, {
    required String rotationKey,
  }) async {
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    switch (_strategy) {
      case RotationStrategy.none:
        return candidates.first;

      case RotationStrategy.random:
        return candidates[_random.nextInt(candidates.length)];

      case RotationStrategy.roundRobin:
        final lastAdId = await _storage.getLastShownAdId(rotationKey);
        final lastIndex = lastAdId == null
            ? -1
            : candidates.indexWhere((a) => a.adId == lastAdId);

        // If the previously shown ad is no longer in the list (campaign
        // ended, new content), start from the beginning.
        final nextIndex = (lastIndex + 1) % candidates.length;
        final picked = candidates[nextIndex];

        if (picked.adId != null) {
          await _storage.setLastShownAdId(rotationKey, picked.adId!);
        }
        return picked;
    }
  }
}
