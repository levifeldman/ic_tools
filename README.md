# ic_tools

----------
This is a package that connects dart-code with the DFINITY-INTERNET-COMPUTER.

This package is for the Dart & Flutter, on the Web & Linux.

See lib/src/common.dart for some samples.

----------

```dart
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';



main() async {
    Caller caller = CallerEd25519.new_keys();
    String caller_icp_id = icp_id(caller.principal);
    IcpTokens icp_balance = await check_icp_balance(caller_icp_id);

    print(caller);
    print(caller_icp_id);
    print(icp_balance);
}
```

----------

runs with the sound-null-safety.

----------

On the Linux:
 - create a folder: 'rust_bls12381' in the same directory as the pubspec.yaml file
 - put this file: https://github.com/levifeldman/ic_tools_dart/tree/master/rust_bls12381/librust_bls12381.so in that folder.

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
