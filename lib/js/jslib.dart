@JS()
library jslib;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'bignumber/main.dart';
import 'dart:typed_data';
import 'dart:js';


@JS('Uint8Array')
@anonymous
class Uint8Array {
    external static Uint8Array from(dynamic iterable); 
    external get buffer;
}

// external from(iterable);







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
        return Uint8Array.from(v).buffer;
    } else {
        var givev = [];
        for (int i=0;i<v.length;i++) {
            givev.add(dartlisttypeasajstype(v[i]));
        }
        return jsify(givev);
    }
}







// only good for numbers i think, without the wasm-bindgen.
// Future<List<Function>> loadwasmfunctions(String filename, List<String> foreignfunctionnames) async {
//     List<Function> foreignFunctions = [];
//     var quest = http.Request('get', Uri.parse(filename));
//     quest.headers['Accept'] = 'application/wasm';
//     http.Response s = await http.Response.fromStream(await quest.send());
//     var w = await promiseToFuture(await instantiate(s.bodyBytes, dartmapasajsstruct({'imports': {'imported_func': allowInterop((x)=>x)}})));
//     var wasmforeignports = getProperty(getProperty(w,'instance'), 'exports');
//     for (String foreignfunctionname in foreignfunctionnames) {
//         foreignFunctions.add(getProperty(wasmforeignports, foreignfunctionname));
//     }
//     return foreignFunctions;
// }






