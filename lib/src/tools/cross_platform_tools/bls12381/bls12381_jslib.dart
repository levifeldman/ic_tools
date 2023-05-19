@JS()
library rbls12381;

import 'package:js/js.dart';



@JS()
external rust_wasm_bls12381_load(wasm_path);


@JS()
external bool bls_stantiate();

@JS()
external bool bls_verify(autograph, message, pubkey);




