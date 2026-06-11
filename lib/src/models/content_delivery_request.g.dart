// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_delivery_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentDeliveryRequest _$ContentDeliveryRequestFromJson(
        Map<String, dynamic> json) =>
    ContentDeliveryRequest(
      appkey: json['appkey'] as String,
      mid: json['mid'] as String,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      searchQuery: json['searchQuery'] as String?,
    );

Map<String, dynamic> _$ContentDeliveryRequestToJson(
        ContentDeliveryRequest instance) =>
    <String, dynamic>{
      'appkey': instance.appkey,
      'mid': instance.mid,
      if (instance.additionalData case final value?) 'additionalData': value,
      if (instance.searchQuery case final value?) 'searchQuery': value,
    };
