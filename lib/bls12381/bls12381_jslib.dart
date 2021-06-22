@JS()
library rbls12381;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'dart:typed_data';

import 'dart:js' as js;

@JS()
external Future<void> rbls12381_load_wasm(); // turn into a dart-function



@JS()
external bool wloadbls();

@JS()
external bool wverify(autograph, message, blskey);





@JS()
external int wsumtest(int x, int y);

@JS()
external int wminustest(int x, int y);



