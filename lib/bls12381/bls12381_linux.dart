import 'main.dart';
import 'dart:typed_data';


class bls12381_linux extends Bls12381Flutter {
    @override
    Future<void> load() async {
        return;
    }
    
    @override
    bool verify(Uint8List autograph, Uint8List message, Uint8List blskey) {
        print(':WARNING IS: A LACK OF THE CHECK OF THE AUTOGRAPH');
        return true;
    }

}

Bls12381Flutter getBls12381Lib() => bls12381_linux();

