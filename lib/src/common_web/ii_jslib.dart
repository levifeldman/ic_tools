@JS()
library ii_jslib;

import 'dart:typed_data';
import 'package:js/js.dart';




@JS()
@anonymous
class InternetIdentityAuthorize {
    external String get kind; 
    external Uint8List get sessionPublicKey;
    external int get maxTimeToLive; // js bigint. dart BigInt is not operating with js
    external String? get derivationOrigin;

    external factory InternetIdentityAuthorize({
        String kind, 
        Uint8List sessionPublicKey,
        int maxTimeToLive,
        String? derivationOrigin
    });
}

InternetIdentityAuthorize create_ii_auth_quest({        
    required String kind, 
    required Uint8List sessionPublicKey,
    required int maxTimeToLive,
    String? derivationOrigin
}) {
    if (derivationOrigin == null) {
        return InternetIdentityAuthorize(
            kind:kind, 
            sessionPublicKey:sessionPublicKey,
            maxTimeToLive:maxTimeToLive 
        );
    } else {
        return InternetIdentityAuthorize(
            kind:kind, 
            sessionPublicKey:sessionPublicKey,
            maxTimeToLive:maxTimeToLive,
            derivationOrigin:derivationOrigin
        );
    } 

}









