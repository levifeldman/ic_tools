@JS()
library cbor;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'dart:typed_data';

import 'dart:js' as js;


// import '../foreign-code/js/jslib.dart';




@JS()
class cbor {
    external static Uint8List encodeOne(o, choices);
}







// cbor.encodeOne(JSON.parse(txt), {canonical: true, collapseBigIntegers: true})




