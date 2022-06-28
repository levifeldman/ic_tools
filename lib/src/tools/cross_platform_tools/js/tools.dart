import 'dart:typed_data';
import 'dart:html';
import 'dart:js';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

export './jslib.dart';

import './bignumber/main.dart';




dartmapasajsstruct(Map dartmap) { // Map<String, dynamic>
    var jsstruct = newObject();
    dartmap.forEach((k,v){
        if (v is Map) {
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

dartlisttypeasajstype(List v) {
    
    if (v is Uint8List) {
        // Uint8Array jsversion = new Uint8Array(v);
        return v.buffer;
    } else {
        List givev = [];
        for (int i=0;i<v.length;i++) {
            if (v[i] is List || v[i] is Uint8List) {
                givev.add(dartlisttypeasajstype(v[i]));
            } else if (v[i] is Map) {
                givev.add(dartmapasajsstruct(v[i]));
            } else {
                givev.add(v[i]);
            }
        }
        return jsify(givev);
    }
}



