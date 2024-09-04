# ic_tools
[![Pub Version](https://shields.io/pub/v/ic_tools)](https://pub.dev/packages/ic_tools)
----------
This is a package that connects dart-code with the [world-computer](https://internetcomputer.org).

For the Dart & Flutter, on the Web & Linux.

```dart
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';

main() async {
    
    Caller caller = Caller(keys: await Ed25519Keys.new_keys());
    print(caller.principal);
    
    Canister icp_ledger = Canister(Principal.text('ryjl3-tyaaa-aaaaa-aaaba-cai'));

    Uint8List sponse_bytes = await icp_ledger.call(
        calltype: CallType.query,
        method_name: 'icrc1_balance_of',
        put_bytes: c_forwards_one(
            Record.of_the_map({
                'owner': caller.principal,
                'subaccount': Option(value: null, value_type: Blob.type_mode())
            })
        )
    );
    BigInt e8s = (c_backwards_one(sponse_bytes) as Nat).value; 
    Tokens icp_tokens = Tokens(quantums: e8s, decimal_places: 8);
    print(icp_tokens);    

}
```

On A Linux:
 - create a folder: 'rust_bls12381' in the same directory as the pubspec.yaml file
 - put this file: https://github.com/levifeldman/ic_tools_dart/tree/master/rust_bls12381/librust_bls12381.so in that folder.

On The Web:
 - copy the ic_tools_webfiles folder ( https://github.com/levifeldman/ic_tools_dart/tree/master/ic_tools_webfiles ) into the flutter web folder.
 - put this line into the flutter index.html file before the flutter initialization script tags:

```html
<script src="ic_tools_webfiles/rust_wasm_bls12381/rust_wasm_bls12381.js"></script>   
```
