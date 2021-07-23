# ic_tools

import 'package:ic_tools/ic_tools.dart';  
import 'package:ic_tools/candid.dart';  

Canister can = Canister('ryjl3-tyaaa-aaaaa-aaaba-cai');  
List sponse = await can.call(calltype: 'call', methodName: 'account_balance_dfx');  
print(sponse);    
print(sponse[0]);    

----------

dart --no-sound-null-safety lib/t.dart

----------

On the web:
 - copy the ic_tools_webfiles folder into the flutter web folder.
 - put this in the flutter index.html file right before the main.dart.js script tag:  

    <script src="ic_tools_webfiles/unpkg_bignumber.js"></script>  
    <script src="ic_tools_webfiles/cbor-web.js"></script>  
    <script src="ic_tools_webfiles/leb128.js"></script>  
    <script src="ic_tools_webfiles/bigint_buffer.js"></script>  
    <script src="ic_tools_webfiles/rust_wasm_bls12381/rust_wasm_bls12381.js"></script>   




----------
 

Cannot run with sound null safety, because the following dependencies
don't support null safety:
 - package:base32
 - package:leb128


----------


