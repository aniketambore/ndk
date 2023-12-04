import 'dart:ui';

import 'package:dart_ndk/nips/nip01/bip340_event_verifier.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:flutter/services.dart';
import 'package:hex/hex.dart';

class AcinqEventVerifier extends Bip340EventVerifier {

  static const platform = MethodChannel('flutter.native/helper');

  @override
  Future<bool> verify(Nip01Event event) async {
    // if (PlatformUtil.isWeb()) {
    //   /// TODO implement JS binding for fast verification with some JS lib
    //   return true;
    // }
    // if (PlatformUtil.isAndroid() && appState != AppLifecycleState.inactive) {
      return await platform.invokeMethod("verifySignature", {
        "signature": HEX.decode(event.sig),
        "hash": HEX.decode(event.id),
        "pubKey": HEX.decode(event.pubKey)
      });
    // }
    // return await super.verify(event);
  }
}