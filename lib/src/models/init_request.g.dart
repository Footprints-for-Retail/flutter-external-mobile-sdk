// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'init_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitRequest _$InitRequestFromJson(Map<String, dynamic> json) => InitRequest(
      appkey: json['appkey'] as String,
      technicalInfo:
          TechnicalInfo.fromJson(json['technicalInfo'] as Map<String, dynamic>),
      userEmail: json['userEmail'] as String?,
      userPhone: json['userPhone'] as String?,
      pushNotificationToken: json['pushNotificationToken'] as String?,
      additionalData: (json['additionalData'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      mid: json['mid'] as String?,
    );

Map<String, dynamic> _$InitRequestToJson(InitRequest instance) =>
    <String, dynamic>{
      'appkey': instance.appkey,
      'technicalInfo': instance.technicalInfo,
      if (instance.userEmail case final value?) 'userEmail': value,
      if (instance.userPhone case final value?) 'userPhone': value,
      if (instance.pushNotificationToken case final value?)
        'pushNotificationToken': value,
      if (instance.additionalData case final value?) 'additionalData': value,
      if (instance.mid case final value?) 'mid': value,
    };
