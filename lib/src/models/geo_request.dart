import 'package:json_annotation/json_annotation.dart';

part 'geo_request.g.dart';

/// Request body for PUT /mobileapi/geo.
///
/// Includes [accuracy] which the Android SDK omits.
@JsonSerializable()
class GeoRequest {
  final String appkey;
  final String mid;
  final double lat;
  final double lon;

  @JsonKey(includeIfNull: false)
  final double? accuracy;

  @JsonKey(includeIfNull: false)
  final double? altitude;

  @JsonKey(includeIfNull: false)
  final double? heading;

  @JsonKey(includeIfNull: false)
  final double? speed;

  @JsonKey(includeIfNull: false)
  final String? timestamp;

  const GeoRequest({
    required this.appkey,
    required this.mid,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    this.timestamp,
  });

  factory GeoRequest.fromJson(Map<String, dynamic> json) =>
      _$GeoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GeoRequestToJson(this);
}
