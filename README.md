# ic_tools

----------
This is a package for the connection of the dart-code with the DFINITY-INTERNET-COMPUTER.

This package is for the Dart &: Flutter, on the Web &: Linux.

----------

```dart
import 'dart:typed_data';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';

Future<void> main() async {
    Canister ledger = Canister(Principal('ryjl3-tyaaa-aaaaa-aaaba-cai'));
    String icp_id = 'ecedd9b3595d88667b78315da6af8e0de29164ef718f96930e0459017d5d8a04';
    Record record = Record.oftheMap({ 'account': Text(icp_id) });
    Uint8List sponse_bytes = await ledger.call( calltype: 'call', method_name: 'account_balance_dfx', put_bytes: c_forwards([record]) );
    Record icpts_balance_record = c_backwards(sponse_bytes)[0] as Record;
    Nat64 e8s = icpts_balance_record['e8s'] as Nat64;
    double icp_count = e8s.value / 100000000; 
    print(icp_count);
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
