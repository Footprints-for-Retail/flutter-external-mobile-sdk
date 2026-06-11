import 'package:json_annotation/json_annotation.dart';

part 'sponsored_product.g.dart';

/// Response wrapper for sponsored product endpoints.
@JsonSerializable()
class SponsoredProductsResponse {
  final bool success;

  @JsonKey(includeIfNull: false)
  final String? mobileId;

  @JsonKey(defaultValue: [])
  final List<SponsoredProduct> data;

  const SponsoredProductsResponse({
    required this.success,
    this.mobileId,
    this.data = const [],
  });

  factory SponsoredProductsResponse.fromJson(Map<String, dynamic> json) =>
      _$SponsoredProductsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoredProductsResponseToJson(this);
}

/// Individual sponsored product.
@JsonSerializable()
class SponsoredProduct {
  final String? id;
  final String? name;
  final String? url;
  final String? image;
  final String? campaignId;
  final String? adId;
  final String? offerPrice;
  final String? originalPrice;
  final String? sku;
  final String? description;
  final String? category;

  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? additionalData;

  const SponsoredProduct({
    this.id,
    this.name,
    this.url,
    this.image,
    this.campaignId,
    this.adId,
    this.offerPrice,
    this.originalPrice,
    this.sku,
    this.description,
    this.category,
    this.additionalData,
  });

  factory SponsoredProduct.fromJson(Map<String, dynamic> json) =>
      _$SponsoredProductFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoredProductToJson(this);
}
