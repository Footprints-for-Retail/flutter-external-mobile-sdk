import 'package:json_annotation/json_annotation.dart';

part 'tracking_event.g.dart';

/// Event sent to POST /mobileapi/send for reach and impression tracking.
@JsonSerializable()
class TrackingEvent {
  final String appkey;
  final String mid;

  /// "reach" or "impression"
  final String requestType;

  @JsonKey(includeIfNull: false)
  final String? actionType;

  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? additionalData;

  const TrackingEvent({
    required this.appkey,
    required this.mid,
    required this.requestType,
    this.actionType,
    this.additionalData,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) =>
      _$TrackingEventFromJson(json);

  Map<String, dynamic> toJson() => _$TrackingEventToJson(this);
}
