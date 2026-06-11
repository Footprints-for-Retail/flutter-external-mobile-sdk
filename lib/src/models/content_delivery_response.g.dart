// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_delivery_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentDeliveryResponse _$ContentDeliveryResponseFromJson(
        Map<String, dynamic> json) =>
    ContentDeliveryResponse(
      success: json['success'] as bool,
      mobileId: json['mobileId'] as String?,
      data: json['data'] == null
          ? null
          : ContentDeliveryData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ContentDeliveryResponseToJson(
        ContentDeliveryResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      if (instance.mobileId case final value?) 'mobileId': value,
      if (instance.data case final value?) 'data': value,
    };

ContentDeliveryData _$ContentDeliveryDataFromJson(Map<String, dynamic> json) =>
    ContentDeliveryData(
      displayAd: (json['displayAd'] as List<dynamic>?)
              ?.map((e) => AdContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videoAdHorizontal: (json['videoAdHorizontalVideo'] as List<dynamic>?)
              ?.map((e) => AdContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videoAdVertical: (json['videoAdVerticalVideo'] as List<dynamic>?)
              ?.map((e) => AdContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      leadAd: (json['leadAd'] as List<dynamic>?)
              ?.map((e) => AdContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sponsoredProducts: (json['sponsoredProducts'] as List<dynamic>?)
              ?.map((e) => AdContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendationProducts: (json['recommendationProducts'] as List<dynamic>?)
              ?.map((e) => AdContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mobileNotifications: (json['mobileNotifications'] as List<dynamic>?)
              ?.map((e) => AdContent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ContentDeliveryDataToJson(
        ContentDeliveryData instance) =>
    <String, dynamic>{
      'displayAd': instance.displayAd,
      'videoAdHorizontalVideo': instance.videoAdHorizontal,
      'videoAdVerticalVideo': instance.videoAdVertical,
      'leadAd': instance.leadAd,
      'sponsoredProducts': instance.sponsoredProducts,
      'recommendationProducts': instance.recommendationProducts,
      'mobileNotifications': instance.mobileNotifications,
    };
