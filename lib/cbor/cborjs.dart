import 'cborjslib.dart';
import 'main.dart';
import 'dart:typed_data';
import '../js/jslib.dart';

class cborjs extends CborFlutter {
    @override
    Uint8List codeMap(Map map, {withaselfscribecbortag=false}) {
        Uint8List v = cbor.encodeOne(dartmapasajsstruct(map), dartmapasajsstruct({'canonical': false, 'collapseBigIntegers': true}));
        if (withaselfscribecbortag) { v = Uint8List.fromList([217,217,247] + v); }
        return v;
    } 
    // @override
    // dynamic cborbytesasadart(Uint8List bytes);
}


CborFlutter getCborLib() => cborjs();



