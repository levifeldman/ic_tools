@JS()
library rbls12381;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'dart:js_util';
import 'dart:typed_data';

import 'dart:js' as js;



@JS()
external rust_wasm_bls12381_load(wasm_path);


@JS()
external bool bls_stantiate();

@JS()
external bool bls_verify(autograph, message, pubkey);




