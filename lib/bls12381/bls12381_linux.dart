import 'main.dart';
import 'dart:typed_data';


class bls12381_linux extends Bls12381Flutter {
    @override
    Future<void> load() async {
        return;
    }
    
    @override
    bool verify(Uint8List autograph, Uint8List message, Uint8List blskey) {
        print(':WARNING, plement linux rust-ffi bls-function. ');
        // throw Exception('make this work');
        return true;
    }

}

Bls12381Flutter getBls12381Lib() => bls12381_linux();

