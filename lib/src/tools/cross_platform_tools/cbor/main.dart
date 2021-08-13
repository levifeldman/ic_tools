import 'dart:typed_data';

import 'package:cbor/cbor.dart';

import 'stub.dart'
    if (dart.library.io) 'cbordart.dart'
    if (dart.library.js) 'cborjs.dart';




abstract class CborFlutter {

    Uint8List codeMap(Map map, {withaselfscribecbortag=false}); 
    
    dynamic cborbytesasadart(Uint8List bytes) {
        Cbor cborcoder = Cbor();
        cborcoder.decodeFromList(bytes);
        List? datalist = cborcoder.getDecodedData();
        if (datalist==null) { throw Exception('cbor transform is null'); }
        if (datalist.length<1 || datalist.length>1) { print(datalist); throw Exception('getdecodeddata gives ${datalist.length} items in the getdecodeddata-list'); }
        return datalist[0];
    }
}


CborFlutter cborflutter = getCborLib(); 









