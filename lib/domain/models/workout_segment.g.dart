// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_segment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkoutSegment _$WorkoutSegmentFromJson(Map<String, dynamic> json) =>
    _WorkoutSegment(
      kind: $enumDecode(_$SegmentKindEnumMap, json['kind']),
      reps: (json['reps'] as num?)?.toInt() ?? 1,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      durationSec: (json['durationSec'] as num?)?.toInt(),
      targetPaceSecPerKm: (json['targetPaceSecPerKm'] as num?)?.toDouble(),
      label: json['label'] as String?,
    );

Map<String, dynamic> _$WorkoutSegmentToJson(_WorkoutSegment instance) =>
    <String, dynamic>{
      'kind': _$SegmentKindEnumMap[instance.kind]!,
      'reps': instance.reps,
      'distanceKm': instance.distanceKm,
      'durationSec': instance.durationSec,
      'targetPaceSecPerKm': instance.targetPaceSecPerKm,
      'label': instance.label,
    };

const _$SegmentKindEnumMap = {
  SegmentKind.warmup: 'warmup',
  SegmentKind.hard: 'hard',
  SegmentKind.recovery: 'recovery',
  SegmentKind.tempo: 'tempo',
  SegmentKind.steady: 'steady',
  SegmentKind.cooldown: 'cooldown',
};
