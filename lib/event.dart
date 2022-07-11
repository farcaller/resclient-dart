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

import 'model.dart';

abstract class ResEvent {}

/// Broadcasted when the websocket connects and the Res version is established.
class ConnectedEvent extends ResEvent {}

/// Broadcasted when the websocket is disconnected.
class DisconnectedEvent extends ResEvent {}

/// Broadcasted when the websocket is disconnected by the user.
class ClientForcedDisconnectedEvent extends ResEvent {}

abstract class ResourceEvent extends ResEvent {
  final RID rid;

  ResourceEvent(this.rid);
}

/// Broadcasted when fields on ResModel change.
class ModelChangedEvent extends ResourceEvent {
  final Map<RID, dynamic> newProps;
  final Map<RID, dynamic> oldProps;

  ModelChangedEvent(super.rid, this.newProps, this.oldProps);
}

abstract class CollectionEvent extends ResourceEvent {
  final int index;
  final dynamic value;

  CollectionEvent(super.rid, this.index, this.value);
}

/// Broadcasted when a value is added to a ResCollection.
class CollectionAddEvent extends CollectionEvent {
  CollectionAddEvent(super.rid, super.index, super.value);
}

/// Broadcasted when a value is removed from a ResCollection.
class CollectionRemoveEvent extends CollectionEvent {
  CollectionRemoveEvent(super.rid, super.index, super.value);
}

/// Broadcasted for any other server-initiated event.
class GenericEvent extends ResEvent {
  final RID rid;
  final String name;
  final dynamic payload;

  GenericEvent(this.rid, this.name, this.payload);
}
