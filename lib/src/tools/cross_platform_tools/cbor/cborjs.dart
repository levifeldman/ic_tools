import 'cborjslib.dart';
import 'main.dart';
import 'dart:typed_data';
import 'dart:js';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '../js/bignumber/main.dart';

class cborjs extends CborFlutter {
    @override
    Uint8List codeMap(Map map, {withaselfscribecbortag=false}) {
        Uint8List v = cborjslib.encodeOne(dartmapasajsstruct(map), dartmapasajsstruct({'canonical': false, 'collapseBigIntegers': true}));
        if (withaselfscribecbortag) { v = Uint8List.fromList([217,217,247] + v); }
        return v;
    } 
    // @override
    // dynamic cborbytesasadart(Uint8List bytes);
}


CborFlutter getCborLib() => cborjs();








dartmapasajsstruct(Map dartmap) {
    var jsstruct = newObject();
    dartmap.forEach((k,v){
        if (v is Map<String,dynamic>) {
            v = dartmapasajsstruct(v);
        } else if (v is List || v is Uint8List) {
            v = dartlisttypeasajstype(v);
        } else if (v is Uint8List) {
            print('dfdfdffddf');
        
        } else if (v is BigInt) {
            v = BigNumber(v);
        }
        setProperty(jsstruct, k, v);
    });
    
    
    return jsstruct;
}

dartlisttypeasajstype(dynamic v) {
    if (v is Uint8List) {
        // Uint8Array jsversion = new Uint8Array(v);
        return v.buffer;
    } else {
        var givev = [];
        for (int i=0;i<v.length;i++) {
            givev.add(dartlisttypeasajstype(v[i]));
        }
        return jsify(givev);
    }
}


