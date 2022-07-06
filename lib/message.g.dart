// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => MessageDto(
      id: json['id'] as int?,
      result: json['result'],
      error: json['error'] == null
          ? null
          : ResError.fromJson(json['error'] as Map<String, dynamic>),
      event: json['event'] as String?,
      data: json['data'],
    );

Map<String, dynamic> _$MessageDtoToJson(MessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'result': instance.result,
      'error': instance.error,
      'event': instance.event,
      'data': instance.data,
    };
