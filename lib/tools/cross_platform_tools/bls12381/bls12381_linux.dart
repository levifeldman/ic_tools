import 'main.dart';
import 'dart:typed_data';
import 'bls12381_linux_ffi.dart' show bls_stantiate, bls_verify;
import '../../tools.dart';
import 'package:ffi/ffi.dart';


class bls12381_linux extends Bls12381Flutter {
    @override
    Future<bool> load() async {
        return bls_stantiate() == 1;
    }
    
    @override
    bool verify_ffi(Uint8List autograph, Uint8List message, Uint8List blskey) {
        return bls_verify( bytesasahexstring(autograph).toNativeUtf8(), bytesasahexstring(message).toNativeUtf8(), bytesasahexstring(blskey).toNativeUtf8() ) == 1;
    }
}

Bls12381Flutter getBls12381Lib() => bls12381_linux();

