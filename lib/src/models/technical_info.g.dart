// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technical_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicalInfo _$TechnicalInfoFromJson(Map<String, dynamic> json) =>
    TechnicalInfo(
      screenSize: json['screenSize'] as String,
      deviceType: json['deviceType'] as String,
      deviceOs: json['deviceOs'] as String,
      deviceUuid: json['deviceUuid'] as String?,
      deviceId: json['deviceId'] as String?,
      androidAdvertisingId: json['androidAdvertisingId'] as String?,
      iosAdvertisingId: json['iosAdvertisingId'] as String?,
      ipAddress: json['ipAddress'] as String?,
    );

Map<String, dynamic> _$TechnicalInfoToJson(TechnicalInfo instance) =>
    <String, dynamic>{
      'screenSize': instance.screenSize,
      'deviceType': instance.deviceType,
      'deviceOs': instance.deviceOs,
      if (instance.deviceUuid case final value?) 'deviceUuid': value,
      if (instance.deviceId case final value?) 'deviceId': value,
      if (instance.androidAdvertisingId case final value?)
        'androidAdvertisingId': value,
      if (instance.iosAdvertisingId case final value?)
        'iosAdvertisingId': value,
      if (instance.ipAddress case final value?) 'ipAddress': value,
    };
