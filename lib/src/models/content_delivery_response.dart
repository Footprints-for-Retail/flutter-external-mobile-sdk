import 'package:json_annotation/json_annotation.dart';
import 'ad_content.dart';

part 'content_delivery_response.g.dart';

/// Response from POST /mobileapi/content-delivery.
@JsonSerializable()
class ContentDeliveryResponse {
  final bool success;

  @JsonKey(includeIfNull: false)
  final String? mobileId;

  @JsonKey(includeIfNull: false)
  final ContentDeliveryData? data;

  const ContentDeliveryResponse({
    required this.success,
    this.mobileId,
    this.data,
  });

  factory ContentDeliveryResponse.fromJson(Map<String, dynamic> json) =>
      _$ContentDeliveryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ContentDeliveryResponseToJson(this);
}

/// Container for ad content grouped by ad type.
@JsonSerializable()
class ContentDeliveryData {
  @JsonKey(defaultValue: [])
  final List<AdContent> displayAd;

  @JsonKey(name: 'videoAdHorizontalVideo', defaultValue: [])
  final List<AdContent> videoAdHorizontal;

  @JsonKey(name: 'videoAdVerticalVideo', defaultValue: [])
  final List<AdContent> videoAdVertical;

  @JsonKey(defaultValue: [])
  final List<AdContent> leadAd;

  @JsonKey(defaultValue: [])
  final List<AdContent> sponsoredProducts;

  @JsonKey(defaultValue: [])
  final List<AdContent> recommendationProducts;

  @JsonKey(defaultValue: [])
  final List<AdContent> mobileNotifications;

  const ContentDeliveryData({
    this.displayAd = const [],
    this.videoAdHorizontal = const [],
    this.videoAdVertical = const [],
    this.leadAd = const [],
    this.sponsoredProducts = const [],
    this.recommendationProducts = const [],
    this.mobileNotifications = const [],
  });

  factory ContentDeliveryData.fromJson(Map<String, dynamic> json) =>
      _$ContentDeliveryDataFromJson(json);

  Map<String, dynamic> toJson() => _$ContentDeliveryDataToJson(this);
}
