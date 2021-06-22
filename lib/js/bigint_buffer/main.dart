@JS()
library bigint_buffer;


import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '../jslib.dart' show Uint8Array;


@JS()
class bigint_buffer {
    external static Uint8Array toBufferLE(bigint_hexstring, hexstring_width);
}
