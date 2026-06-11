import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity to trigger event queue flushes.
class ConnectivityMonitor {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Callback invoked when connectivity is restored.
  void Function()? onConnectivityRestored;

  ConnectivityMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Start monitoring connectivity changes.
  void start() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any(
        (r) => r != ConnectivityResult.none,
      );
      if (hasConnection) {
        onConnectivityRestored?.call();
      }
    });
  }

  /// Stop monitoring.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
