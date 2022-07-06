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

import 'package:crypto/crypto.dart';

const salt = 'TheStoryStartsHere';

String saltPassword(String password) {
  final passwordBytes = utf8.encode(password);
  final hmac = Hmac(sha256, ascii.encode(salt));
  final digest = hmac.convert(passwordBytes);
  return base64.encode(digest.bytes);
}
