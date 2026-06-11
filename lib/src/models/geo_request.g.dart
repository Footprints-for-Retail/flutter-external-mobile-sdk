// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoRequest _$GeoRequestFromJson(Map<String, dynamic> json) => GeoRequest(
      appkey: json['appkey'] as String,
      mid: json['mid'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String?,
    );

Map<String, dynamic> _$GeoRequestToJson(GeoRequest instance) =>
    <String, dynamic>{
      'appkey': instance.appkey,
      'mid': instance.mid,
      'lat': instance.lat,
      'lon': instance.lon,
      if (instance.accuracy case final value?) 'accuracy': value,
      if (instance.altitude case final value?) 'altitude': value,
      if (instance.heading case final value?) 'heading': value,
      if (instance.speed case final value?) 'speed': value,
      if (instance.timestamp case final value?) 'timestamp': value,
    };
