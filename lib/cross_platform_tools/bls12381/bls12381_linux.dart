import 'main.dart';
import 'dart:typed_data';


class bls12381_linux extends Bls12381Flutter {
    @override
    Future<bool> load() async {
        print(':do: make bls_verify_ffi function on the linux');
        return true;
    }
    
    @override
    bool verify_ffi(Uint8List autograph, Uint8List message, Uint8List blskey) {
        print(':WARNING IS: A LACK OF THE CHECK OF THE AUTOGRAPH');
        // throw Exception('make this work');
        return true;
    }

}

Bls12381Flutter getBls12381Lib() => bls12381_linux();

