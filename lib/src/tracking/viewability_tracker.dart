/// Tracks ad viewability for impression counting.
///
/// Uses VisibilityDetector in the widget layer. This class manages
/// the timing thresholds and deduplication logic.
class ViewabilityTracker {
  /// Minimum visible fraction to count as viewable (MRC standard: 50%).
  final double visibilityThreshold;

  /// Minimum time visible to count as an impression (1 second for display ads).
  final Duration timeThreshold;

  final Set<String> _recordedImpressions = {};

  ViewabilityTracker({
    this.visibilityThreshold = 0.5,
    this.timeThreshold = const Duration(seconds: 1),
  });

  /// Check if this ad has already recorded an impression.
  bool hasRecordedImpression(String adId) {
    return _recordedImpressions.contains(adId);
  }

  /// Mark an ad as having recorded an impression.
  void recordImpression(String adId) {
    _recordedImpressions.add(adId);
  }

  /// Clear all recorded impressions (e.g., on new content fetch).
  void reset() {
    _recordedImpressions.clear();
  }
}
