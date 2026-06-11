import 'package:json_annotation/json_annotation.dart';
import 'technical_info.dart';

part 'init_request.g.dart';

/// Request body for POST /mobileapi/init.
///
/// Server Joi schema requires either [userEmail] or [pushNotificationToken].
/// [additionalData] is an array of {attributeName, attributeValue} maps
/// for custom variables (server field name, NOT "customVariable").
@JsonSerializable()
class InitRequest {
  final String appkey;
  final TechnicalInfo technicalInfo;

  @JsonKey(includeIfNull: false)
  final String? userEmail;

  @JsonKey(includeIfNull: false)
  final String? userPhone;

  @JsonKey(includeIfNull: false)
  final String? pushNotificationToken;

  @JsonKey(includeIfNull: false)
  final List<Map<String, dynamic>>? additionalData;

  /// mobileId from a previous init (for returning devices).
  @JsonKey(includeIfNull: false)
  final String? mid;

  const InitRequest({
    required this.appkey,
    required this.technicalInfo,
    this.userEmail,
    this.userPhone,
    this.pushNotificationToken,
    this.additionalData,
    this.mid,
  });

  factory InitRequest.fromJson(Map<String, dynamic> json) =>
      _$InitRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InitRequestToJson(this);
}
