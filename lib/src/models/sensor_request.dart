import 'package:json_annotation/json_annotation.dart';

part 'sensor_request.g.dart';

/// Request body for PUT /mobileapi/sensors (BLE beacon data).
@JsonSerializable()
class SensorRequest {
  final String appkey;
  final String mid;
  final List<SensorData> sensors;

  const SensorRequest({
    required this.appkey,
    required this.mid,
    required this.sensors,
  });

  factory SensorRequest.fromJson(Map<String, dynamic> json) =>
      _$SensorRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SensorRequestToJson(this);
}

/// Individual BLE beacon sensor reading.
@JsonSerializable()
class SensorData {
  final String uuid;
  final int major;
  final int minor;
  final String proximity;
  final int rssi;

  const SensorData({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.proximity,
    required this.rssi,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) =>
      _$SensorDataFromJson(json);

  Map<String, dynamic> toJson() => _$SensorDataToJson(this);
}
