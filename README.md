# ic_tools

----------
This is a package for the connection of the dart-code with the DFINITY-INTERNET-COMPUTER.

This package is for the Dart &: Flutter, on the Web &: Linux.

----------

Checkout src/common.dart (https://github.com/levifeldman/ic_tools_dart/blob/master/lib/src/common.dart) for some samples.

----------

runs with the sound-null-safety.

----------


On the web:
 - copy the ic_tools_webfiles folder ( https://github.com/levifeldman/ic_tools_dart/tree/master/ic_tools_webfiles ) into the flutter web folder.
 - put this in the flutter index.html file right before the main.dart.js script tag:  

```html
<script src="ic_tools_webfiles/unpkg_bignumber.js"></script>  
<script src="ic_tools_webfiles/cbor-web.js"></script>  
<script src="ic_tools_webfiles/rust_wasm_bls12381/rust_wasm_bls12381.js"></script>   
```



----------
 

