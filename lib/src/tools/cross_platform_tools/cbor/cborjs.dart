import 'cborjslib.dart';
import 'main.dart';
import 'dart:typed_data';
import 'dart:js';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '../js/tools.dart';
import '../js/bignumber/main.dart';


class cborjs extends CborFlutter {
    @override
    Uint8List codeMap(Map map, {withaselfscribecbortag=false}) {
        Uint8List v = cborjslib.encodeOne(dartmapasajsstruct(map), dartmapasajsstruct({'canonical': false, 'collapseBigIntegers': true}));
        if (withaselfscribecbortag) { v = Uint8List.fromList([217,217,247] + v); }
        return v;
    } 
    // @override
    // dynamic cborbytesasadart(Uint8List bytes);
}


CborFlutter getCborLib() => cborjs();







