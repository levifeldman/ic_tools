@JS('WebAssembly')
library jswasmlib;

import 'package:js/js.dart';


external instantiate(dynamic bytes, dynamic importObj); // bytes is the wasmfile bytes. importObj is an object containing configuration information that is passed into the loaded .wasm file. imported_func method expected by the WebAssembly file.














