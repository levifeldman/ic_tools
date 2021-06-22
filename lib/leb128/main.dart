import 'dart:typed_data';

import 'stub.dart'
    if (dart.library.io) 'leb128_dart.dart'
    if (dart.library.js) 'leb128_js.dart';




abstract class Leb128Flutter {

    Uint8List encodeUnsigned(x);
    dynamic decodeUnsigned(bytes);
    
}


Leb128Flutter leb128flutter = getLeb128Lib(); 

