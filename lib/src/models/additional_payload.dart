import 'package:json_annotation/json_annotation.dart';

part 'additional_payload.g.dart';

/// Key-value payload used for custom data in API requests.
@JsonSerializable()
class AdditionalPayload {
  final String key;
  final dynamic value;

  const AdditionalPayload({
    required this.key,
    required this.value,
  });

  factory AdditionalPayload.fromJson(Map<String, dynamic> json) =>
      _$AdditionalPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AdditionalPayloadToJson(this);
}
