import 'dart:typed_data';

import 'package:js/js.dart';
import '../ic_tools.dart';






@JS()
@anonymous
class JSLegation  {
    external Uint8List get legatee_public_key_DER;
    external String get expiration_timestamp_nanoseconds;
    external List<String>? get target_canisters_ids;  
    external Uint8List get legator_public_key_DER;
    external Uint8List get legator_signature; 
    
    external factory JSLegation({
        Uint8List legatee_public_key_DER,
        String expiration_timestamp_nanoseconds,
        List<String>? target_canisters_ids,
        Uint8List legator_public_key_DER,
        Uint8List legator_signature,
        
    });
}

JSLegation jslegation_of_a_legation(Legation legation) {
    return JSLegation(
        legatee_public_key_DER: legation.legatee_public_key_DER,
        expiration_timestamp_nanoseconds: legation.expiration_timestamp_nanoseconds.toRadixString(10),
        target_canisters_ids: legation.target_canisters_ids != null ? legation.target_canisters_ids!.map<String>((Principal p)=>p.text).toList() : null,
        legator_public_key_DER: legation.legator_public_key_DER,
        legator_signature: legation.legator_signature, 
    );
}

Legation legation_of_a_jslegation(JSLegation jslegation) {
    return Legation(
        legatee_public_key_DER: jslegation.legatee_public_key_DER,
        expiration_timestamp_nanoseconds: BigInt.parse(jslegation.expiration_timestamp_nanoseconds, radix:10),
        target_canisters_ids: jslegation.target_canisters_ids != null ? jslegation.target_canisters_ids!.map<Principal>((String ps)=>Principal.text(ps)).toList() : null,
        legator_public_key_DER: jslegation.legator_public_key_DER,
        legator_signature: jslegation.legator_signature, 
    );
}








