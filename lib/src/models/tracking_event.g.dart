// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackingEvent _$TrackingEventFromJson(Map<String, dynamic> json) =>
    TrackingEvent(
      appkey: json['appkey'] as String,
      mid: json['mid'] as String,
      requestType: json['requestType'] as String,
      actionType: json['actionType'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TrackingEventToJson(TrackingEvent instance) =>
    <String, dynamic>{
      'appkey': instance.appkey,
      'mid': instance.mid,
      'requestType': instance.requestType,
      if (instance.actionType case final value?) 'actionType': value,
      if (instance.additionalData case final value?) 'additionalData': value,
    };
