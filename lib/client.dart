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

library res_client;

import 'dart:async';
import 'dart:convert';

import 'package:glog/glog.dart';
import 'package:res_client/message.dart';
import 'package:res_client/model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'cache/cache_item.dart';
import 'error.dart';
import 'event.dart';

typedef AuthCallback = Future<void> Function();

const logger = GlogContext('res_client');

class ResClient {
  final Uri _endpoint;
  WebSocketChannel? _channel;
  int _currentId = 0;
  final Map<int, Completer<dynamic>> _callbacks = {};
  final Map<String, CacheItem> _cache = {};
  final StreamController<ResEvent> _eventsController;
  final AuthCallback? _authCallback;

  ResClient(this._endpoint, {AuthCallback? authCallback})
      : _eventsController = StreamController.broadcast(),
        _authCallback = authCallback;

  reconnect() {
    _channel = WebSocketChannel.connect(_endpoint);
    _channel!.stream.listen(_onData, onError: _onError, onDone: _onDone);

    _currentId = 0;
    _sendVersion();
  }

  forceClose() {
    _channel?.sink.close();
  }

  Stream<ResEvent> get events {
    return _eventsController.stream;
  }

  Future<dynamic> _send(Map object) async {
    _currentId++;
    final completer = Completer<dynamic>();
    _callbacks[_currentId] = completer;

    object['id'] = _currentId;

    logger.trace('--> $object');
    final payload = jsonEncode(object);
    _channel!.sink.add(payload);

    return completer.future;
  }

  MessageDto _parseDto(dynamic data) {
    try {
      final payload = jsonDecode(data) as Map<String, dynamic>;
      final dto = MessageDto.fromJson(payload);
      return dto;
    } catch (e) {
      logger.warning('failed to parse the incoming message: $e');
      throw InvalidMessageException('failed to deserialize the message', data);
      // TODO: makes sense?
    }
  }

  _onData(dynamic data) {
    final message = _parseDto(data);
    logger.trace('<-- $message');

    if (message.id != null) {
      _handleResponse(message);
    } else if (message.event != null) {
      _handleEvent(message);
    } else {
      throw InvalidMessageException(
          "the message doesn't have the `id` or `event` set", data);
    }
  }

  _handleResponse(MessageDto message) {
    final callback = _callbacks[message.id];
    if (callback == null) {
      throw InvalidMessageException(
          'the requested id ${message.id} has no callback', message);
    }
    _callbacks.remove(message.id);

    final result = message.result;
    final error = message.error;
    if (result != null) {
      callback.complete(result);
    } else if (error != null) {
      callback.completeError(error);
    } else {
      throw InvalidMessageException(
          "the message doesn't have the `result` or `error` set", message);
    }
  }

  _handleEvent(MessageDto message) {
    final event = message.event!;
    final idx = event.lastIndexOf('.');
    if (idx == -1 || idx == event.length - 1) {
      throw InvalidMessageException(
          "the event name doesn't contain the `.`: $event", message);
    }
    final rid = event.substring(0, idx);
    final name = event.substring(idx + 1);

    final cacheItem = _cache[rid];
    if (cacheItem == null) {
      throw InvalidMessageException(
          "received an event for unknown rid $rid", message);
    }
    if (name == 'unsubscribe') {
      _handleUnsubscribeEvent(cacheItem);
    } else {
      final item = cacheItem.item;
      if (item == null) {
        throw InvalidMessageException(
            "received an event for unresolved rid $rid", message);
      }
      final evt = item.handleEvent(name, message.data);
      if (evt != null) {
        _eventsController.add(evt);
      } else {
        _eventsController.add(GenericEvent(rid, name, message.data));
      }
    }
  }

  _handleUnsubscribeEvent(CacheItem cacheItem) {
    // TODO: implement
    throw 'not implemented';
  }

  _onDone() {
    for (final e in _callbacks.entries) {
      e.value.completeError(ClientDisconnectedException());
    }
    _callbacks.clear();
    logger.debug('websocket closed');
    _eventsController.add(DisconnectedEvent());
  }

  _onError(Object error) {
    logger.error('websocket error: $error');
    _onDone();
  }

  _sendVersion() async {
    final response = await _send({
      'method': 'version',
      'params': {'protocol': '1.2.1'},
    });

    logger.debug('got version reply $response');
    _eventsController.add(ConnectedEvent());
  }

  auth(String rid, String method, {Map<String, dynamic>? params}) async {
    final result = await _call('auth', rid, method, params: params);
    return result;
  }

  _call(String type, String requestRid, String? method,
      {Map<String, dynamic>? params}) async {
    final authCallback = _authCallback;
    if (authCallback != null && type != 'auth') {
      // we will allow auth calls through, but not anything else if the callback is set.
      await authCallback();
    }
    final result = await _send({
      'method': '$type.$requestRid${method != null ? '.$method' : ''}',
      'params': params ?? {},
    });

    final rid = result['rid'];

    if (rid != null) {
      cacheResources(result);
      return _cache[rid]?.item;
    } else if (result.containsKey('payload')) {
      // payload can be null
      return result['payload'];
    } else {
      throw InvalidMessageException(
          'call response has both `rid` and `payload` missing', result);
    }
  }

  Future<dynamic> call(String rid, String method,
      {Map<String, dynamic>? params}) {
    return _call('call', rid, method, params: params);
  }

  Future<dynamic> subscribe(String rid) {
    return _call('subscribe', rid, null);
  }

  cacheResources(dynamic payload) {
    final resourceTypes = ['model', 'collection'];
    final typedResources = {};
    final Map<String, Map<String, dynamic>> typeSync = {};

    for (final type in resourceTypes) {
      final resources = payload['${type}s'];
      if (resources is! Map<String, dynamic>) {
        continue;
      }
      typedResources[type] = resources;
      typeSync[type] = _createResources(resources, type);
    }

    for (final type in resourceTypes) {
      final resources = payload['${type}s'];
      if (resources is! Map<String, dynamic>) {
        continue;
      }

      for (final e in resources.entries) {
        final rid = e.key;
        if (!typeSync[type]!.containsKey(rid)) {
          final cacheItem = _cache[rid];
          cacheItem!.item!.initData(e.value);
        }
      }
    }

    for (final typeValues in typeSync.values) {
      for (final e in typeValues.entries) {
        final cacheItem = _cache[e.key];
        if (cacheItem == null) {
          throw CacheInconsistenyException(
              "can't sync '${e.key}': no cache item", e.value);
        }
        final item = cacheItem.item;
        if (item == null) {
          throw CacheInconsistenyException(
              "can't sync '${e.key}': no item in cache item", e.value);
        }
        final evts = item.updateData(e.value);
        for (final evt in evts) {
          _eventsController.add(evt);
        }
      }
    }
  }

  dynamic parseValue(dynamic value, {required bool addIndirect}) {
    if (value == null) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      final rid = value['rid'];
      if (rid != null) {
        final soft = value['soft'];
        if (soft == true) {
          return ResRef(this, rid);
        }
        final cacheItem = _cache[rid];
        if (cacheItem == null) {
          throw CacheInconsistenyException(
              'cacheItem $rid not available while resolving the value', value);
        }
        if (addIndirect) {
          cacheItem.addIndirectReference();
        }
        return cacheItem.item;
      }

      final data = value['data'];
      if (data != null) {
        return data;
      }

      final action = value['action'];
      if (action == 'delete') {
        return ResAction.delete;
      }
    } else {
      return value;
    }
  }

  Map<String, dynamic> _createResources(
      Map<String, dynamic> resources, String type) {
    final sync = <String, dynamic>{};

    for (final e in resources.entries) {
      final rid = e.key;
      var cacheItem = _cache[rid];
      if (cacheItem == null) {
        cacheItem = CacheItem(rid);
        _cache[rid] = cacheItem;
      } else {
        // TODO: check staleness?
      }
      final item = cacheItem.item;
      if (item != null) {
        if (item.type != type) {
          throw CacheInconsistenyException(
              'old type ${item.type} differs from $type on $rid', e.value);
        }
        sync[rid] = e.value;
      } else {
        cacheItem.item = ResEntry.fromResource(this, type, rid);
      }
    }

    return sync;
  }

  CacheItem? get(String rid) {
    return _cache[rid];
  }

  List<String> get cachedRids {
    return _cache.keys.toList();
  }

  void dispose() {
    _channel?.sink.close();
  }
}
