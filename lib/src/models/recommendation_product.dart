import 'package:json_annotation/json_annotation.dart';

part 'recommendation_product.g.dart';

/// Response wrapper for recommendation product endpoints.
@JsonSerializable()
class RecommendationProductsResponse {
  final bool success;

  @JsonKey(includeIfNull: false)
  final String? mobileId;

  @JsonKey(defaultValue: [])
  final List<RecommendationProduct> data;

  const RecommendationProductsResponse({
    required this.success,
    this.mobileId,
    this.data = const [],
  });

  factory RecommendationProductsResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$RecommendationProductsResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$RecommendationProductsResponseToJson(this);
}

/// Individual recommendation product.
@JsonSerializable()
class RecommendationProduct {
  final String? id;
  final String? name;
  final String? url;
  final String? image;
  final String? price;
  final String? description;
  final String? category;
  final String? campaignId;
  final String? adId;

  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? additionalData;

  const RecommendationProduct({
    this.id,
    this.name,
    this.url,
    this.image,
    this.price,
    this.description,
    this.category,
    this.campaignId,
    this.adId,
    this.additionalData,
  });

  factory RecommendationProduct.fromJson(Map<String, dynamic> json) =>
      _$RecommendationProductFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationProductToJson(this);
}
