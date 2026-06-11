import 'package:json_annotation/json_annotation.dart';

part 'technical_info.g.dart';

/// Device technical information sent during init.
@JsonSerializable()
class TechnicalInfo {
  final String screenSize;
  final String deviceType;
  final String deviceOs;

  @JsonKey(includeIfNull: false)
  final String? deviceUuid;

  @JsonKey(name: 'deviceId', includeIfNull: false)
  final String? deviceId;

  @JsonKey(includeIfNull: false)
  final String? androidAdvertisingId;

  @JsonKey(includeIfNull: false)
  final String? iosAdvertisingId;

  @JsonKey(includeIfNull: false)
  final String? ipAddress;

  const TechnicalInfo({
    required this.screenSize,
    required this.deviceType,
    required this.deviceOs,
    this.deviceUuid,
    this.deviceId,
    this.androidAdvertisingId,
    this.iosAdvertisingId,
    this.ipAddress,
  });

  factory TechnicalInfo.fromJson(Map<String, dynamic> json) =>
      _$TechnicalInfoFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicalInfoToJson(this);
}
