@JS()
library jslib;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'bignumber/main.dart';
import 'dart:typed_data';
import 'dart:js';

// @anonymous
// @JS('Uint8Array')
// class Uint8Array {
//     external Uint8Array(dynamic iterable); 
//     external ArrayBuffer buffer;
// }

// // @anonymous
// @JS()
// class ArrayBuffer {

// }

// external from(iterable);

@JS('BigInt')
class BigIntJS {
    external String toString([radix]); 
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






