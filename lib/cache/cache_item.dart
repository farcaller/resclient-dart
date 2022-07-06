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

import '../model.dart';

class CacheItem {
  final String rid;
  ResEntry? _item;
  int _directReferences = 0;
  int _indirectReferenes = 0;

  CacheItem(this.rid);

  ResEntry? get item => _item;

  set item(ResEntry? newItem) {
    _item = newItem;
  }

  addIndirectReference({int value = 1}) {
    _indirectReferenes += value;
  }

  addDirectRefence({int value = 1}) {
    _directReferences += value;
  }
}
