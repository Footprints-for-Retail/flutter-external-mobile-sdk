// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'init_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitResponse _$InitResponseFromJson(Map<String, dynamic> json) => InitResponse(
      success: json['success'] as bool,
      mobileId: json['mobileId'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$InitResponseToJson(InitResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      if (instance.mobileId case final value?) 'mobileId': value,
      if (instance.message case final value?) 'message': value,
    };
