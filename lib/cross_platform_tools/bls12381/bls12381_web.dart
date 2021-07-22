import 'main.dart';
import 'dart:typed_data';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '../js/jslib.dart';
import 'bls12381_jslib.dart';
import 'dart:js' as js;
import '../../tools.dart';


class bls12381_web extends Bls12381Flutter {
    
    @override
    Future<bool> load() async {
        await promiseToFuture(rust_wasm_bls12381_load('ic_tools_webfiles/rust_wasm_bls12381/rust_wasm_bls12381_bg.wasm'));
        return bls_stantiate();            
    }    
    @override
    bool verify_ffi(Uint8List autograph, Uint8List message, Uint8List pubkey) {
        return bls_verify(autograph, message, pubkey);  
    }


}



Bls12381Flutter getBls12381Lib() => bls12381_web();