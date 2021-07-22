import 'main.dart';
import 'dart:typed_data';
import 'package:cbor/cbor.dart';





class cbordart extends CborFlutter {
    @override
    Uint8List codeMap(Map map, {withaselfscribecbortag=false}) {
        Cbor cborcoder = Cbor(); 
        if (withaselfscribecbortag) { cborcoder.encoder.writeTag(tagSelfDescribedCbor); }
        cborcoder.encoder.writeMap(map);
        return Uint8List.fromList(cborcoder.output.getData());
    }
    
    // @override
    // dynamic cborbytesasadart(Uint8List bytes) {

    // }
}




CborFlutter getCborLib() => cbordart();