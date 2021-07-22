@JS()
library leb128;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'dart:typed_data';

import 'dart:js' as js;

import '../js/jslib.dart' show Uint8Array;



@JS()
class leb128 {
    external static List<int> encodeUIntBuffer(numberbuffer);
    external static dynamic decodeUIntBuffer(numberbuffer);
    external static List<int> encodeIntBuffer(numberbuffer);
    external static dynamic decodeIntBuffer(numberbuffer);
    
}