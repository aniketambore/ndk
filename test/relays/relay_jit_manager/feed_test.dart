import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/mem_cache_manager.dart';
import 'package:dart_ndk/nips/nip01/bip340_event_verifier.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/event_verifier.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_manager.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:developer' as developer;

void main() async {
  group(
    "Calculate best relays (external REAL)",
    skip: true,
    () {
      _calculateBestRelaysForNpubContactsFeed(String npub,
          {int relayMinCountPerPubKey = 2}) async {
        CacheManager cacheManager = MemCacheManager();
        RelayJitManager relayJitManager =
            RelayJitManager(cacheManager: cacheManager);
        // wait for the relays to connect
        await Future.delayed(Duration(seconds: 2));

        KeyPair key = KeyPair.justPublicKey(Helpers.decodeBech32(npub)[0]);

        EventVerifier eventVerifier = Bip340EventVerifier();

        NostrRequestJit contactsRequest = NostrRequestJit.query(
          "contacts",
          filters: [
            Filter(authors: [key.publicKey], kinds: [ContactList.KIND]),
          ],
          eventVerifier: eventVerifier,
        );

        relayJitManager.handleRequest(
          contactsRequest,
          desiredCoverage: relayMinCountPerPubKey,
        );

        contactsRequest.responseStream.listen((event) {
          var contactList = ContactList.fromEvent(event);
          cacheManager.saveContactList(contactList);
        });

        await Future.delayed(Duration(seconds: 5));

        ContactList? myContactList =
            cacheManager.loadContactList(key.publicKey);
        expect(myContactList, isNotNull);

        // get nip65 data
        NostrRequestJit nip65Request = NostrRequestJit.query(
          "nip65",
          filters: [
            Filter(authors: myContactList!.contacts, kinds: [Nip65.KIND]),
          ],
          eventVerifier: eventVerifier,
        );

        relayJitManager.handleRequest(
          nip65Request,
          desiredCoverage: relayMinCountPerPubKey,
        );

        nip65Request.responseStream.listen((event) {
          cacheManager.saveEvent(event);
        });

        await Future.delayed(Duration(seconds: 5));
        var nip65Data = cacheManager.loadEvents(
          pubKeys: myContactList.contacts,
          kinds: [Nip65.KIND],
        );

        developer.log('##################################################');

        NostrRequestJit feedRequest = NostrRequestJit.subscription(
          "feed-test",
          filters: [
            Filter(
              authors: myContactList.contacts,
              kinds: [Nip01Event.TEXT_NODE_KIND],
              since:
                  (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 60 * 60 * 1,
            ),
          ],
          eventVerifier: eventVerifier,
        );

        relayJitManager.handleRequest(
          feedRequest,
          desiredCoverage: relayMinCountPerPubKey,
        );

        NostrRequestJit feedRequest2 = NostrRequestJit.subscription(
          "feed-test2",
          filters: [
            Filter(
              authors: myContactList.contacts,
              kinds: [Nip01Event.TEXT_NODE_KIND],
              since:
                  (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 60 * 60 * 4,
            ),
          ],
          eventVerifier: eventVerifier,
        );

        relayJitManager.handleRequest(
          feedRequest2,
          desiredCoverage: relayMinCountPerPubKey,
        );

        List<Nip01Event> events = [];
        feedRequest2.responseStream.listen((event) {
          events.add(event);
        });

        await Future.delayed(Duration(seconds: 5));
        //developer.log("FEED: ${events.toString()}");

        developer.log('##################################################');
        developer.log(
            "Relay: {relay.url} - {relay.assignedPubkeys.length} - {relay.relayUsefulness}");
        for (var relay in relayJitManager.connectedRelays) {
          developer.log(
              "Relay: ${relay.url} - ${relay.assignedPubkeys.length} - ${relay.relayUsefulness.toString()}");
        }
        developer
            .log('relays count: ${relayJitManager.connectedRelays.length}');
        developer.log('##################################################');
      }

      test('Leo feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub1w9llyw8c3qnn7h27u3msjlet8xyjz5phdycr5rz335r2j5hj5a0qvs3tur",
            relayMinCountPerPubKey: 2);
      }, timeout: Timeout.parse('10m'));

      test('Fmar feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub1xpuz4qerklyck9evtg40wgrthq5rce2mumwuuygnxcg6q02lz9ms275ams",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('mikedilger feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub1acg6thl5psv62405rljzkj8spesceyfz2c32udakc2ak0dmvfeyse9p35c",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('Fiatjaf feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('Love is Bitcoin (3k follows) feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub1kwcatqynqmry9d78a8cpe7d882wu3vmrgcmhvdsayhwqjf7mp25qpqf3xx",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));
    },
  );
}
