/// Abstract interface for rotation cursor storage.
///
/// Production uses `SqliteRotationStorage`, tests use `InMemoryRotationStorage`.
abstract class RotationStorageBackend {
  /// Returns the last-shown adId for the given rotation key, or null if none.
  Future<String?> getLastShownAdId(String rotationKey);

  /// Records the adId that was just shown for the given rotation key.
  Future<void> setLastShownAdId(String rotationKey, String adId);

  /// Clear all rotation state.
  Future<void> clear();
}
