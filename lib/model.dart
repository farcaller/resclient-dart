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

import 'dart:math' as math;

import 'package:glog/glog.dart';
import 'package:res_client/client.dart';
import 'package:tuple/tuple.dart';

import 'error.dart';
import 'event.dart';

const logger = GlogContext('res_model');

typedef RID = String;

// TODO: split this file. Dart seems to be anal about circular imports though.

abstract class ResEntry {
  final String rid;
  final ResClient _client;

  String get type;

  ResEntry(this._client, this.rid);

  factory ResEntry.fromResource(ResClient client, String type, String rid) {
    switch (type) {
      case 'model':
        return ResModel(client, rid);
      case 'collection':
        return ResCollection(client, rid);
      default:
        throw CacheInconsistenyException(
            'the cache tried to spawn the unknown type $type for $rid', null);
    }
  }

  initData(dynamic data);
  List<ResEvent> updateData(dynamic data);
  ResEvent? handleEvent(String name, dynamic data);

  @override
  bool operator ==(Object other) {
    if (other is ResEntry) {
      return rid == other.rid;
    }
    return false;
  }

  @override
  int get hashCode => rid.hashCode;
}

class ResModel extends ResEntry {
  final Map<String, dynamic> _data = {};

  ResModel(super._client, super.rid) {
    logger.debug('new model for $rid');
  }

  @override
  String get type {
    return 'model';
  }

  @override
  String toString() {
    return '<ResModel $rid>';
  }

  Map<String, dynamic> toJson() => _data;

  dynamic operator [](String index) => _data[index];

  @override
  initData(dynamic newData) {
    if (newData is! Map<String, dynamic>) {
      throw InvalidMessageException(
          'tried to update the model $rid with ${newData.runtimeType}',
          newData);
    }
    _data.clear();
    _data.addAll(newData.map((key, value) =>
        MapEntry(key, _client.parseValue(value, addIndirect: true))));
  }

  @override
  List<ResEvent> updateData(dynamic newData) {
    if (newData is! Map<String, dynamic>) {
      throw InvalidMessageException(
          'tried to update the model $rid with ${newData.runtimeType}',
          newData);
    }

    final updates = _updateData(newData, reset: true);
    if (updates != null) {
      return [ModelChangedEvent(rid, updates.item1, updates.item2)];
    }
    return [];
  }

  Tuple2<Map<RID, dynamic>, Map<RID, dynamic>>? _updateData(dynamic newData,
      {required bool reset}) {
    final indirect = <RID, int>{};
    final newProps = <RID, dynamic>{};
    final oldProps = <RID, dynamic>{};

    updateIndirect(dynamic value, int counter) {
      if (value is ResEntry) {
        indirect[value.rid] = (indirect[value.rid] ?? 0) + counter;
      }
    }

    for (final e in newData.entries) {
      final key = e.key;

      final newValue = _client.parseValue(e.value, addIndirect: true);
      final oldValue = _data[key];
      newProps[key] = newValue;
      oldProps[key] = oldValue;
      if (newValue == ResAction.delete) {
        _data.remove(key);
        if (oldValue is ResModel) {
          updateIndirect(oldValue, -1);
        }
      } else {
        if (oldValue != null) {
          if (newValue != oldValue) {
            _data[key] = newValue;
            updateIndirect(oldValue, -1);
            updateIndirect(newValue, 1);
          }
        } else {
          oldProps[key] = ResAction.delete;
          _data[key] = newValue;
          updateIndirect(newValue, 1);
        }
      }
    }

    if (reset) {
      final keysToDelete = [];
      _data.entries.where((e) => !newData.containsKey(e.key)).forEach((e) {
        newProps[e.key] = ResAction.delete;
        oldProps[e.key] = e.value;
        keysToDelete.add(e.key);
        updateIndirect(e.value, -1);
      });
      for (final key in keysToDelete) {
        _data.remove(key);
      }
    }

    if (newProps.isEmpty) {
      return null;
    }

    for (final e in indirect.entries) {
      if (e.value == 0) {
        continue;
      }
      final cacheItem = _client.get(e.key);
      if (cacheItem == null) {
        throw CacheInconsistenyException(
            'cacheItem ${e.key} not available while resolving the update for $rid',
            newData);
      }
      cacheItem.addDirectRefence(value: e.value);
      if (e.value < 0) {
        // TODO:
        logger.debug('try delete ${cacheItem.rid}');
      }
    }

    return Tuple2(newProps, oldProps);
  }

  @override
  ModelChangedEvent? handleEvent(String name, dynamic data) {
    if (name == 'change') {
      if (data is! Map<String, dynamic>) {
        throw InvalidMessageException(
            'tried to update the model $rid with ${data.runtimeType}', data);
      }
      final values = data['values'];
      if (values is! Map<String, dynamic>) {
        throw InvalidMessageException(
            'tried to update the model $rid with ${values.runtimeType}',
            values);
      }
      _client.cacheResources(data);
      final updates = _updateData(values, reset: false);
      if (updates != null) {
        return ModelChangedEvent(rid, updates.item1, updates.item2);
      }
    }
    return null;
  }
}

class ResCollection extends ResEntry {
  final List<dynamic> _items = [];

  ResCollection(super._client, super.rid) {
    logger.debug('new collection for $rid');
  }

  @override
  String get type {
    return 'collection';
  }

  List<dynamic> toJson() => _items;

  List<dynamic> get items => _items;

  @override
  initData(dynamic data) {
    if (data is! List<dynamic>) {
      throw InvalidMessageException(
          'tried to update the collection $rid with ${data.runtimeType}', data);
    }
    _items.clear();
    _items.addAll(
        data.map((value) => _client.parseValue(value, addIndirect: true)));
  }

  @override
  List<ResEvent> updateData(dynamic newData) {
    final evts = <ResEvent>[];

    if (newData is! List<dynamic>) {
      throw InvalidMessageException(
          'tried to update the collection $rid with ${newData.runtimeType}',
          newData);
    }

    final a = _items;
    final b =
        newData.map((e) => _client.parseValue(e, addIndirect: false)).toList();
    _patchDiff(a, b, onAdd: (value, idx) {
      _items.insert(idx, value);
      if (value is ResEntry) {
        final cacheItem = _client.get(value.rid);
        if (cacheItem == null) {
          throw CacheInconsistenyException(
              'cacheItem ${value.rid} not available while resolving the update for $rid',
              newData);
        }
        cacheItem.addIndirectReference();
      }
      evts.add(CollectionAddEvent(rid, idx, value));
    }, onRemove: (idx) {
      final value = _items.removeAt(idx);
      if (value is ResEntry) {
        final cacheItem = _client.get(value.rid);
        if (cacheItem == null) {
          throw CacheInconsistenyException(
              'cacheItem ${value.rid} not available while resolving the update for $rid',
              newData);
        }
        cacheItem.addIndirectReference(value: -1);
        // TODO: try delete
      }
    });

    return evts;
  }

  ResEvent? handleEvent(String name, dynamic data) {
    switch (name) {
      case 'add':
        return _handleAddEvent(data);
      case 'remove':
        return _handleRemoveEvent(data);
      default:
        return null;
    }
  }

  CollectionAddEvent _handleAddEvent(data) {
    _client.cacheResources(data);
    final idx = data['idx'];
    if (idx is! int) {
      throw InvalidMessageException(
          'collection add event idx is not int', data);
    }
    final rawValue = data['value'];
    final value = _client.parseValue(rawValue, addIndirect: true);
    _items.insert(idx, value);
    return CollectionAddEvent(rid, idx, value);
  }

  CollectionRemoveEvent _handleRemoveEvent(data) {
    final idx = data['idx'];
    if (idx is! int) {
      throw InvalidMessageException(
          'collection add event idx is not int', data);
    }
    final value = _items.removeAt(idx);
    if (value is ResEntry) {
      final cacheItem = _client.get(value.rid);
      if (cacheItem == null) {
        throw CacheInconsistenyException(
            'cacheItem ${value.rid} not available while resolving the update for $rid',
            data);
      }
      cacheItem.addIndirectReference(value: -1);
      // TODO: try delete
    }
    return CollectionRemoveEvent(rid, idx, value);
  }
}

class ResRef extends ResEntry {
  ResRef(super._client, super.rid);

  @override
  ResEvent? handleEvent(String name, data) {
    throw UnimplementedError();
  }

  @override
  initData(data) {
    throw UnimplementedError();
  }

  @override
  String get type => throw UnimplementedError();

  @override
  List<ResEvent> updateData(data) {
    throw UnimplementedError();
  }
}

enum ResAction { delete }

void _patchDiff(List<dynamic> a, List<dynamic> b,
    {required void Function(dynamic, int) onAdd,
    required void Function(int) onRemove}) {
  var aa = a;
  var bb = b;
  var start = 0;
  var m = a.length;
  var n = b.length;

  // trim off the matching items at the beginning
  while (start < m && start < n && a[start] == b[start]) {
    ++start;
  }
  // oops, they equal; my job here is done
  if (start == m && start == n) {
    return;
  }
  // trim off the matching items at the end
  while (start < m && start < n && a[m - 1] == b[n - 1]) {
    --m;
    --n;
  }
  if (start > 0 || m < a.length) {
    aa = a.sublist(start, m);
    m = aa.length;
  }
  if (start > 0 || n < b.length) {
    bb = b.sublist(start, n);
    n = bb.length;
  }
  final List<List<int>> c = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (var i = 0; i < m; i++) {
    for (var j = 0; j < n; j++) {
      c[i + 1][j + 1] =
          aa[i] == bb[j] ? c[i][j] + 1 : math.max(c[i + 1][j], c[i][j + 1]);
    }
  }
  var idx = start + m;
  var i = m;
  var j = n;
  var r = 0;
  final adds = <_AddValue>[];
  while (true) {
    m = i - 1;
    n = j - 1;
    if (i > 0 && j > 0 && aa[m] == bb[n]) {
      --i;
      --j;
    } else if (j > 0 && (i == 0 || c[i][n] >= c[m][j])) {
      adds.add(_AddValue(n, idx + r));
      --j;
    } else if (i > 0 && (j == 0 || c[i][n] < c[m][j])) {
      onRemove(--idx);
      ++r;
      --i;
    } else {
      break;
    }
  }

  final len = adds.length - 1;
  for (var i = len; i >= 0; --i) {
    final add = adds[i];
    onAdd(bb[add.index], add.offset - r + len - i);
  }
}

class _AddValue {
  final int index;
  final int offset;

  _AddValue(this.index, this.offset);
}
