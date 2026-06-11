import 'package:json_annotation/json_annotation.dart';

part 'init_response.g.dart';

/// Response from POST /mobileapi/init.
@JsonSerializable()
class InitResponse {
  final bool success;

  @JsonKey(includeIfNull: false)
  final String? mobileId;

  @JsonKey(includeIfNull: false)
  final String? message;

  const InitResponse({
    required this.success,
    this.mobileId,
    this.message,
  });

  factory InitResponse.fromJson(Map<String, dynamic> json) =>
      _$InitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InitResponseToJson(this);
}
