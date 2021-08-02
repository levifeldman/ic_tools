import 'main.dart';
import 'dart:typed_data';

import 'package:leb128/leb128.dart';


class leb128dart extends Leb128Flutter {
    // @override
    // Uint8List encodeUnsigned(x) {
    //     return Uint8List.fromList(Leb128.encodeUnsigned(x));
    // }
    
    // @override
    // dynamic decodeUnsigned(bytes) {
    //     return Leb128.decodeUnsigned(bytes);
    // }

    @override
    Uint8List encodeSigned(x) {
        return Uint8List.fromList(Leb128.encodeSigned(x));
    }
    
    @override
    dynamic decodeSigned(bytes) {
        return Leb128.decodeSigned(bytes);
    }
    
}




Leb128Flutter getLeb128Lib() => leb128dart();