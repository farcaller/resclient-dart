// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResError _$ResErrorFromJson(Map<String, dynamic> json) => ResError(
      code: json['code'] as String,
      message: json['message'] as String,
      data: json['data'],
    );

Map<String, dynamic> _$ResErrorToJson(ResError instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };
