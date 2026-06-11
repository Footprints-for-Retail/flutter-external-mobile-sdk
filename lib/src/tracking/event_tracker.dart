import 'dart:async';

import '../api/footprints_api_client.dart';
import '../auth/auth_manager.dart';
import '../models/sdk_result.dart';
import '../models/tracking_event.dart';
import 'event_queue.dart';

/// Offline-first event tracker with batching and retry.
///
/// Events are persisted to a queue and flushed in batches. Solves both
/// existing SDKs' fire-and-forget problem.
class EventTracker {
  final FootprintsApiClient _apiClient;
  final AuthManager _authManager;
  final String _appKey;
  final EventQueue _queue;
  final int batchSize;
  final Duration batchInterval;
  final bool enableOfflineQueue;

  Timer? _flushTimer;

  EventTracker({
    required FootprintsApiClient apiClient,
    required AuthManager authManager,
    required String appKey,
    this.batchSize = 10,
    this.batchInterval = const Duration(seconds: 15),
    this.enableOfflineQueue = true,
    EventQueue? queue,
  })  : _apiClient = apiClient,
        _authManager = authManager,
        _appKey = appKey,
        _queue = queue ?? EventQueue();

  /// Start the periodic flush timer.
  Future<void> start() async {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(batchInterval, (_) => flush());
  }

  /// Stop the flush timer and drain remaining events.
  Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await flush();
  }


  /// Track an ad impression.
  Future<SdkResult<void>> trackImpression({
    required String campaignId,
    required String adId,
    String? actionType,
    double? scrollPercent,
    Duration? screenOnTime,
  }) async {
    final mid = await _authManager.getMobileId();
    if (mid == null) {
      return const SdkResult.failure('SDK not initialized');
    }

    final additionalData = <String, dynamic>{
      'campaignId': campaignId,
      'adId': adId,
    };
    if (scrollPercent != null) {
      additionalData['scrollViewPercentage'] = scrollPercent;
    }
    if (screenOnTime != null) {
      additionalData['screenOnTime'] = screenOnTime.inSeconds;
    }

    final event = TrackingEvent(
      appkey: _appKey,
      mid: mid,
      requestType: 'action',
      actionType: actionType ?? 'visit',
      additionalData: additionalData,
    );

    return _enqueueOrSend(event);
  }

  /// Flush queued events to the server.
  Future<void> flush() async {
    final events = await _queue.drain(batchSize);
    for (final event in events) {
      try {
        await _apiClient.sendEvent(event);
      } catch (_) {
        if (enableOfflineQueue) {
          await _queue.enqueue(event);
        }
        break;
      }
    }
  }

  Future<SdkResult<void>> _enqueueOrSend(TrackingEvent event) async {
    if (enableOfflineQueue) {
      await _queue.enqueue(event);
      return const SdkResult.success(null);
    }

    try {
      await _apiClient.sendEvent(event);
      return const SdkResult.success(null);
    } catch (e) {
      return SdkResult.failure(e.toString());
    }
  }
}
