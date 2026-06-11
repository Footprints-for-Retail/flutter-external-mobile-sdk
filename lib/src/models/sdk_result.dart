/// Unified success/error wrapper for all SDK operations.
class SdkResult<T> {
  final T? data;
  final String? error;
  final String? errorCode;

  const SdkResult._({this.data, this.error, this.errorCode});

  /// Create a successful result.
  const SdkResult.success(T data) : this._(data: data);

  /// Create a failed result.
  const SdkResult.failure(String error, {String? errorCode})
      : this._(error: error, errorCode: errorCode);

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  /// Execute a future and wrap the result.
  static Future<SdkResult<T>> fromFuture<T>(
    Future<T> Function() fn,
  ) async {
    try {
      final result = await fn();
      return SdkResult.success(result);
    } catch (e) {
      return SdkResult.failure(e.toString());
    }
  }
}
