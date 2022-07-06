// Copyright 2022 Vladimir Pouzanov <farcaller@gmail.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'error.dart';

part 'message.g.dart';

@JsonSerializable()
class MessageDto {
  final int? id;
  final dynamic result;
  final ResError? error;
  final String? event;
  final dynamic data;

  MessageDto({this.id, this.result, this.error, this.event, this.data});

  factory MessageDto.fromJson(Map<String, dynamic> json) =>
      _$MessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDtoToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
