import 'main.dart';
import 'dart:typed_data';
import 'package:typed_data/typed_data.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'leb128_jslib.dart' as leb128jslib;
import '../js/jslib.dart';
import '../js/bigint_buffer/main.dart';
import '../tools.dart';

class leb128js extends Leb128Flutter {
    @override
    Uint8List encodeUnsigned(x) {
        return Uint8List.fromList(leb128jslib.leb128.encodeUIntBuffer(bigint_buffer.toBufferLE(x.toRadixString(16), (x.toRadixString(16).length/2).round())));
    }
    
    @override
    dynamic decodeUnsigned(bytes) {
        BigIntJS bijs = bigint_buffer.toBigIntLE(getProperty(leb128jslib.leb128.decodeUIntBuffer(bytes), 'value'));
        String bijs_string = bijs.toString();
        BigInt bi = BigInt.parse(bijs_string);
        return bi.isValidInt ? bi.toInt() : bi;
    }
    
    @override
    Uint8List encodeSigned(x) {
        return Uint8List.fromList(leb128jslib.leb128.encodeIntBuffer(bigint_buffer.toBufferLE(x.toRadixString(16), (x.toRadixString(16).length/2).round())));
    }
    
    @override
    dynamic decodeSigned(bytes) {
        BigIntJS bijs = bigint_buffer.toBigIntLE(getProperty(leb128jslib.leb128.decodeIntBuffer(bytes), 'value'));
        String bijs_string = bijs.toString();
        BigInt bi = BigInt.parse(bijs_string);
        return bi.isValidInt ? bi.toInt() : bi;
    }
}


Leb128Flutter getLeb128Lib() => leb128js();






