// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sponsored_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SponsoredProductsResponse _$SponsoredProductsResponseFromJson(
        Map<String, dynamic> json) =>
    SponsoredProductsResponse(
      success: json['success'] as bool,
      mobileId: json['mobileId'] as String?,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => SponsoredProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$SponsoredProductsResponseToJson(
        SponsoredProductsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      if (instance.mobileId case final value?) 'mobileId': value,
      'data': instance.data,
    };

SponsoredProduct _$SponsoredProductFromJson(Map<String, dynamic> json) =>
    SponsoredProduct(
      id: json['id'] as String?,
      name: json['name'] as String?,
      url: json['url'] as String?,
      image: json['image'] as String?,
      campaignId: json['campaignId'] as String?,
      adId: json['adId'] as String?,
      offerPrice: json['offerPrice'] as String?,
      originalPrice: json['originalPrice'] as String?,
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SponsoredProductToJson(SponsoredProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'image': instance.image,
      'campaignId': instance.campaignId,
      'adId': instance.adId,
      'offerPrice': instance.offerPrice,
      'originalPrice': instance.originalPrice,
      'sku': instance.sku,
      'description': instance.description,
      'category': instance.category,
      if (instance.additionalData case final value?) 'additionalData': value,
    };
