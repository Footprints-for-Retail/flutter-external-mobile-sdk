// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendationProductsResponse _$RecommendationProductsResponseFromJson(
        Map<String, dynamic> json) =>
    RecommendationProductsResponse(
      success: json['success'] as bool,
      mobileId: json['mobileId'] as String?,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) =>
                  RecommendationProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RecommendationProductsResponseToJson(
        RecommendationProductsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      if (instance.mobileId case final value?) 'mobileId': value,
      'data': instance.data,
    };

RecommendationProduct _$RecommendationProductFromJson(
        Map<String, dynamic> json) =>
    RecommendationProduct(
      id: json['id'] as String?,
      name: json['name'] as String?,
      url: json['url'] as String?,
      image: json['image'] as String?,
      price: json['price'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      campaignId: json['campaignId'] as String?,
      adId: json['adId'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RecommendationProductToJson(
        RecommendationProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'image': instance.image,
      'price': instance.price,
      'description': instance.description,
      'category': instance.category,
      'campaignId': instance.campaignId,
      'adId': instance.adId,
      if (instance.additionalData case final value?) 'additionalData': value,
    };
