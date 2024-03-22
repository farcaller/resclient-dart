## 0.8.6

* Update the YamlWriter interaction code (https://github.com/farcaller/resclient-dart/pull/1)

## 0.8.5

* Log the outgoing packets as JSON

## 0.8.4

* Allow reconnecting to a different endpoint. This flushes caches but keeps the
  events intact.

## 0.8.3

* Make the ratelimt retries looping if another rate limit is hit.
* Expose the forced socket closure from the client side via
  ClientForcedDisconnectedEvent.

## 0.8.2

* Handle the rate-limiting on the client side.

## 0.8.1

* Restore the missing tracing.
* Expose the ResClient of any given ResEntity.
* Properly parse the subscribe calls.

## 0.8.0

* Initial public release. All the primary flows work.
