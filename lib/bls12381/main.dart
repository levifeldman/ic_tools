import 'dart:typed_data';

import 'stub.dart'
    if (dart.library.io) 'bls12381_linux.dart'
    if (dart.library.js) 'bls12381_web.dart';



abstract class Bls12381Flutter {
    Future<void> load();
    bool verify(Uint8List autograph, Uint8List message, Uint8List blskey);
}

Bls12381Flutter bls12381flutter = getBls12381Lib(); 

