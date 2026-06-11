// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdContent _$AdContentFromJson(Map<String, dynamic> json) => AdContent(
      adType: json['adType'] as String?,
      adId: json['adId'] as String?,
      title: json['title'] as String?,
      campaignName: json['campaignName'] as String?,
      topMessage: json['topMessage'] as String?,
      contentType: json['contentType'] as String?,
      contentUrl: json['contentUrl'] as String?,
      bannerType: json['bannerType'] as String?,
      bottomMessage: json['bottomMessage'] as String?,
      buttonText: json['buttonText'] as String?,
      publishDate: json['publishDate'] as String?,
      expirationDate: json['expirationDate'] as String?,
      campaignId: json['campaignId'] as String?,
      linkUrl: json['linkUrl'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AdContentToJson(AdContent instance) => <String, dynamic>{
      'adType': instance.adType,
      'adId': instance.adId,
      'title': instance.title,
      'campaignName': instance.campaignName,
      'topMessage': instance.topMessage,
      'contentType': instance.contentType,
      'contentUrl': instance.contentUrl,
      'bannerType': instance.bannerType,
      'bottomMessage': instance.bottomMessage,
      'buttonText': instance.buttonText,
      'publishDate': instance.publishDate,
      'expirationDate': instance.expirationDate,
      'campaignId': instance.campaignId,
      'linkUrl': instance.linkUrl,
      if (instance.additionalData case final value?) 'additionalData': value,
    };
