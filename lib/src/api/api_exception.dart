import '../models/error_codes.dart';

/// Typed exception for Footprints API errors.
class FootprintsApiException implements Exception {
  final String message;
  final int? statusCode;
  final FootprintsErrorCode? errorCode;

  const FootprintsApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() =>
      'FootprintsApiException($statusCode): $message [${errorCode?.name}]';
}
