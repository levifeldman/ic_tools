import 'dart:typed_data';

import 'stub.dart'
    if (dart.library.io) 'bls12381_linux.dart'
    if (dart.library.js) 'bls12381_web.dart';


/// Use the [bls12381] property in this [tools] library to get the instance of this class. 
abstract class Bls12381Flutter {
    bool _loadtry = false;
    bool _loadsuccess = false;
    
    /// Verify a BLS12381 signature.
    Future<bool> verify(Uint8List autograph, Uint8List message, Uint8List blskey) async {
        if (_loadtry==false) { 
            _loadsuccess = await load();
            _loadtry = true;
        }
        if (_loadsuccess==false) { 
            throw Exception('bls load bug'); 
        }
        return verify_ffi(autograph, message, blskey);
    }       
    
    /// For internal use.
    Future<bool> load(); //load function should return loadsuccess
    
    /// For internal use. Use the [verify] function to verify a BLS signature.
    bool verify_ffi(Uint8List autograph, Uint8List message, Uint8List blskey);

}

/// To verify a BLS12381 signature on a message, use the function [bls12381.verify].
Bls12381Flutter bls12381 = getBls12381Lib(); 


// await bls12381flutter.load();


// test

// Uint8List autograph = Uint8List.fromList([184, 158, 19, 162, 18, 200, 48, 88, 110, 170, 154, 213, 57, 70, 205, 150, 135, 24, 235, 236, 194, 126, 218, 132, 157, 146, 50, 103, 61, 205, 79, 68, 14, 139, 93, 243, 155, 241, 74, 136, 4, 140, 21, 225, 108, 188, 170, 190]);
// Uint8List message = Uint8List.fromList([104, 101, 108, 108, 111]);
// Uint8List pubkey = Uint8List.fromList([167, 98, 58, 147, 205, 181, 108, 77, 35, 217, 156, 20, 33, 106, 250, 171, 61, 253, 109, 79, 158, 179, 219, 35, 208, 56, 40, 11, 109, 92, 178, 202, 174, 226, 161, 157, 217, 44, 157, 247, 0, 29, 237, 226, 59, 240, 54, 188, 15, 51, 152, 45, 251, 65, 232, 250, 155, 142, 150, 181, 220, 62, 131, 213, 92, 164, 221, 20, 108, 126, 178, 232, 182, 133, 156, 181, 165, 219, 129, 93, 184, 104, 16, 184, 209, 44, 238, 21, 136, 181, 219, 243, 74, 77, 201, 165]);

// if (bls12381flutter.verify(autograph, message, pubkey) == false) {
//     throw Exception('see whats going on here this should be the same test as in the rust code');
// } else {
//     print('bls12381 test success');
// }


