import 'main.dart';
import 'dart:typed_data';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '../js/jslib.dart';
import 'bls12381_jslib.dart';

class bls12381_web extends Bls12381Flutter {
    @override
    Future<void> load() async {
        await promiseToFuture(rbls12381_load_wasm());  
        bool loadsuccess = wloadbls();
        if (loadsuccess==false) { throw Exception('loadbls fail'); }    
        else {print('successfull-blsload'); }  
    }
    
    @override
    bool verify(Uint8List autograph, Uint8List message, Uint8List blskey) {
        return wverify(Uint8Array.from(autograph), Uint8Array.from(message), Uint8Array.from(blskey));  
    }

}

Bls12381Flutter getBls12381Lib() => bls12381_web();