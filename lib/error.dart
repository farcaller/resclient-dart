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

import 'package:json_annotation/json_annotation.dart';

part 'error.g.dart';

@JsonSerializable()
class ResError {
  final String code;
  final String message;
  final dynamic data;

  ResError({required this.code, required this.message, this.data});

  factory ResError.fromJson(Map<String, dynamic> json) =>
      _$ResErrorFromJson(json);

  @override
  String toString() => '<ResError "$code": $message>';

  Map<String, dynamic> toJson() => _$ResErrorToJson(this);
}

/// Thrown if the incoming message is malformed, unparseable or contains
/// conflicting data.
class InvalidMessageException implements Exception {
  final String description;
  final dynamic context;

  InvalidMessageException(this.description, this.context);

  @override
  String toString() => '<InvalidMessageException "$description": $context>';
}

/// Sent to the pending callbacks if the client disconnected while the call is
/// in flight.
class ClientDisconnectedException implements Exception {
  ClientDisconnectedException();

  @override
  String toString() => '<ClientDisconnectedException>';
}

/// Thrown if the reconciliation of the cache failed due to an incoming reply or
/// event.
class CacheInconsistenyException implements Exception {
  final String description;
  final dynamic context;

  CacheInconsistenyException(this.description, this.context);

  @override
  String toString() => '<CacheInconsistenyException "$description": $context>';
}
