import 'main.dart';
import 'dart:typed_data';
import 'bls12381_linux_ffi.dart' show bls_stantiate, bls_verify, dartstringasaffipointerutf8;
import '../../tools.dart';
import 'package:ffi/ffi.dart';


class bls12381_linux extends Bls12381Flutter {
    @override
    Future<bool> load() async {
        // print(':do: make bls_verify_ffi function on the linux');
        // return true;
        return bls_stantiate() == 1;
    }
    
    @override
    bool verify_ffi(Uint8List autograph, Uint8List message, Uint8List blskey) {
        // print(':WARNING IS: A LACK OF THE CHECK OF THE AUTOGRAPH');
        // throw Exception('make this work');
        // return true;
        return bls_verify( bytesasahexstring(autograph).toNativeUtf8(), bytesasahexstring(message).toNativeUtf8(), bytesasahexstring(blskey).toNativeUtf8() ) == 1;
    }
}

Bls12381Flutter getBls12381Lib() => bls12381_linux();

