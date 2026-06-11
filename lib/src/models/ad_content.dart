import 'package:json_annotation/json_annotation.dart';

part 'ad_content.g.dart';

/// Represents a single ad unit returned by content delivery.
///
/// Includes all fields the server returns. The Android SDK drops
/// [bannerType] and hardcodes [linkUrl] for lead ads -- this model
/// preserves both correctly.
@JsonSerializable()
class AdContent {
  final String? adType;
  final String? adId;
  final String? title;
  final String? campaignName;
  final String? topMessage;
  final String? contentType;
  final String? contentUrl;
  final String? bannerType;
  final String? bottomMessage;
  final String? buttonText;
  final String? publishDate;
  final String? expirationDate;
  final String? campaignId;
  final String? linkUrl;

  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? additionalData;

  const AdContent({
    this.adType,
    this.adId,
    this.title,
    this.campaignName,
    this.topMessage,
    this.contentType,
    this.contentUrl,
    this.bannerType,
    this.bottomMessage,
    this.buttonText,
    this.publishDate,
    this.expirationDate,
    this.campaignId,
    this.linkUrl,
    this.additionalData,
  });

  /// Whether this ad has expired based on [expirationDate].
  bool get isExpired {
    if (expirationDate == null) return false;
    final expiry = DateTime.tryParse(expirationDate!);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  factory AdContent.fromJson(Map<String, dynamic> json) =>
      _$AdContentFromJson(json);

  Map<String, dynamic> toJson() => _$AdContentToJson(this);
}
