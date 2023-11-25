[![Build Status](https://github.com/relaystr/dart_ndk/actions/workflows/tests.yaml/badge.svg?branch=master)](https://github.com/relaystr/dart_ndk/actions?query=workflow%3A"tests"+branch%3Amaster)
[![Coverage](https://codecov.io/github/relaystr/dart_ndk/graph/badge.svg?token=OP3PZCXCML)](https://codecov.io/github/relaystr/dart_ndk)
[![Pub](https://img.shields.io/pub/v/dart_ndk.svg)](https://pub.dev/packages/dart_ndk)
[![License](https://img.shields.io/github/license/relaystr/dart_ndk.svg)](LICENSE.txt)


Dart Nostr Development Kit

## Features

### Gossip/outbox model of relay discovery and connectivity

The simplest characterization of the gossip model is just this: *reading the posts of people you follow from the relays that they wrote them to.*

<img src="https://mikedilger.com/gossip-model/gossip-model.png" style="width:400px; height:400px"/>

more details on https://mikedilger.com/gossip-model/

### NIPs
- [x] Event Builders / WebSocket Subscriptions ([NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md))
- [x] User Profiles (edit/follow/unfollow - [NIP-02](https://github.com/nostr-protocol/nips/blob/master/02.md))
- [x] Private Messages ([NIP-04](https://github.com/nostr-protocol/nips/blob/master/04.md))
- [x] Nostr Address ([NIP-05](https://github.com/nostr-protocol/nips/blob/master/05.md))
- [x] Event Deletion ([NIP-09](https://github.com/nostr-protocol/nips/blob/master/09.md))
- [x] Relay Info ([NIP-11](https://github.com/nostr-protocol/nips/blob/master/11.md))
- [x] Reactions ([NIP-25](https://github.com/nostr-protocol/nips/blob/master/25.md))
- [x] Lists ([NIP-51](https://github.com/nostr-protocol/nips/blob/master/51.md))
- [x] Relay List Metadata ([NIP-65](https://github.com/nostr-protocol/nips/blob/master/65.md))
- [ ] Bech Encoding support ([NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md))
- [ ] Wallet Connect API ([NIP-47](https://github.com/nostr-protocol/nips/blob/master/47.md))
- [ ] Zaps (private, public, anon, non-zap) ([NIP-57](https://github.com/nostr-protocol/nips/blob/master/57.md))
- [ ] Badges ([NIP-58](https://github.com/nostr-protocol/nips/blob/master/58.md))

## Getting started
Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  dart_nostr: any
```

## Usage


```dart
        RelayManager manager = RelayManager();

        await manager.connect();
        
        NostrRequest request = await manager.query(
          Filter(kinds: [Nip01Event.TEXT_NODE_KIND], authors: [pubKey]));
        await for (final event in request.stream) {
          print(event);
        }

```
