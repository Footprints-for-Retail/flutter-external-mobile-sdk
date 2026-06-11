// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SensorRequest _$SensorRequestFromJson(Map<String, dynamic> json) =>
    SensorRequest(
      appkey: json['appkey'] as String,
      mid: json['mid'] as String,
      sensors: (json['sensors'] as List<dynamic>)
          .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SensorRequestToJson(SensorRequest instance) =>
    <String, dynamic>{
      'appkey': instance.appkey,
      'mid': instance.mid,
      'sensors': instance.sensors,
    };

SensorData _$SensorDataFromJson(Map<String, dynamic> json) => SensorData(
      uuid: json['uuid'] as String,
      major: (json['major'] as num).toInt(),
      minor: (json['minor'] as num).toInt(),
      proximity: json['proximity'] as String,
      rssi: (json['rssi'] as num).toInt(),
    );

Map<String, dynamic> _$SensorDataToJson(SensorData instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'major': instance.major,
      'minor': instance.minor,
      'proximity': instance.proximity,
      'rssi': instance.rssi,
    };
