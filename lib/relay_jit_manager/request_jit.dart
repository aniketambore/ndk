import 'dart:async';

import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/event_verifier.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_config.dart';
import 'package:logging/logging.dart';

///
///! currently a partial copy of request.dart, need to discuss how to resolve this
///

final log = Logger('NostrRequestJit');

class NostrRequestJit {
  String id;
  EventVerifier eventVerifier;

  List<Filter> filters;

  StreamController<Nip01Event> responseController =
      StreamController<Nip01Event>();

  /// If true, the request will be closed when all requests received EOSE
  bool closeOnEOSE;

  ///
  int? timeout;

  Function(NostrRequestJit)? onTimeout;

  Stream<Nip01Event> get responseStream => timeout != null
      ? responseController.stream.timeout(Duration(seconds: timeout!),
          onTimeout: (sink) {
          if (onTimeout != null) {
            onTimeout!.call(this);
          }
        })
      : responseController.stream;

  NostrRequestJit.query(
    this.id, {
    required this.eventVerifier,
    required this.filters,
    this.closeOnEOSE = true,
    this.timeout = RelayJitConfig.DEFAULT_STREAM_IDLE_TIMEOUT,
    this.onTimeout,
  });
  NostrRequestJit.subscription(
    this.id, {
    required this.eventVerifier,
    required this.filters,
    this.closeOnEOSE = false,
  });

  /// verify event and add to response stream
  void onMessage(Nip01Event event) async {
    // verify event
    bool validSig = await eventVerifier.verify(event);

    if (!validSig) {
      log.warning("🔑⛔ Invalid signature on event: $event");
      return;
    }
    event.validSig = validSig;

    // add to response stream
    responseController.add(event);
  }
}
