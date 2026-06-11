import 'package:json_annotation/json_annotation.dart';

part 'content_delivery_request.g.dart';

/// Request body for POST /mobileapi/content-delivery.
///
/// Includes [additionalData] and [searchQuery] which the Android SDK omits.
@JsonSerializable()
class ContentDeliveryRequest {
  final String appkey;
  final String mid;

  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? additionalData;

  @JsonKey(includeIfNull: false)
  final String? searchQuery;

  const ContentDeliveryRequest({
    required this.appkey,
    required this.mid,
    this.additionalData,
    this.searchQuery,
  });

  factory ContentDeliveryRequest.fromJson(Map<String, dynamic> json) =>
      _$ContentDeliveryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ContentDeliveryRequestToJson(this);
}
