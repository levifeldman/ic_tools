import 'main.dart';
import 'dart:typed_data';
import 'leb128_jslib.dart' as leb128jslib;
import '../js/jslib.dart';
import '../js/bigint_buffer/main.dart';


class leb128js extends Leb128Flutter {
    @override
    Uint8List encodeUnsigned(x) {
        return Uint8List.fromList(leb128jslib.leb128.encodeUIntBuffer(bigint_buffer.toBufferLE(x.toRadixString(16), (x.toRadixString(16).length/2).round())));
    }
    
    @override
    dynamic decodeUnsigned(bytes) {

    }
}


Leb128Flutter getLeb128Lib() => leb128js();






