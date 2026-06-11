import 'dart:async';
import 'package:dio/dio.dart';

/// Dio interceptor for exponential backoff retry on transient failures.
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final attempts = _getAttemptCount(err.requestOptions);
    if (attempts >= maxRetries) {
      return handler.next(err);
    }

    final delay = attempts < retryDelays.length
        ? retryDelays[attempts]
        : retryDelays.last;

    await Future<void>.delayed(delay);

    err.requestOptions.extra['retryAttempt'] = attempts + 1;

    try {
      final dio = Dio()..options = BaseOptions(
        baseUrl: err.requestOptions.baseUrl,
        headers: err.requestOptions.headers,
        connectTimeout: err.requestOptions.connectTimeout,
        receiveTimeout: err.requestOptions.receiveTimeout,
      );
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  int _getAttemptCount(RequestOptions options) {
    return (options.extra['retryAttempt'] as int?) ?? 0;
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}
