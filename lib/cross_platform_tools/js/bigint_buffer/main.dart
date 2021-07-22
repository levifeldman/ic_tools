@JS()
library bigint_buffer;


import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '../jslib.dart' show Uint8Array;
import 'dart:typed_data';
import 'package:typed_data/typed_data.dart';

@JS()
class bigint_buffer {
    external static Uint8List toBufferLE(bigint_hexstring, hexstring_width);
    external static toBigIntLE(big_int_buffer);
}
