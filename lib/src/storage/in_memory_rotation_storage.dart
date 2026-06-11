import 'rotation_storage_backend.dart';

/// In-memory implementation of [RotationStorageBackend] for testing.
class InMemoryRotationStorage implements RotationStorageBackend {
  final Map<String, String> _cursors = {};

  @override
  Future<String?> getLastShownAdId(String rotationKey) async {
    return _cursors[rotationKey];
  }

  @override
  Future<void> setLastShownAdId(String rotationKey, String adId) async {
    _cursors[rotationKey] = adId;
  }

  @override
  Future<void> clear() async {
    _cursors.clear();
  }
}
