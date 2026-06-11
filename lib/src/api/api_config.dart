/// API client configuration constants.
class ApiConfig {
  /// Default connect timeout.
  static const defaultConnectTimeout = Duration(seconds: 15);

  /// Default read timeout.
  static const defaultReadTimeout = Duration(seconds: 30);

  /// Default max retry attempts.
  static const defaultMaxRetries = 3;

  /// Mobile API base path.
  static const mobileApiPath = '/mobileapi';

  ApiConfig._();
}
