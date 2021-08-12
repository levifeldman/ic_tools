import 'main.dart';
import 'dart:html';

import 'dart:typed_data';
import 'dart:convert';
// import 'webfiles.dart';



class onthewebcheckweb extends onthewebcheck {
    @override
    bool isontheweb = true;

    // onthewebcheckweb() {
    //     print('starting onthewebcheckweb class');

    //     ScriptElement sc = new ScriptElement();
    //     // sc.type = "text/javascript";
    //     // sc.async = true;
    //     sc.src = 'https://unpkg.com/bignumber.js'; // change to the download base64 code version
    //     document.body!.nodes.add(sc);

    //     List<Uint8List> src_list = [ bigint_buffer__js, cborhyphenweb__js, leb128__js, rust_wasm_bls12381___rust_wasm_bls12381__js ]; 
    //     Base64Codec b64urlcoder = Base64Codec(); //.urlSafe
    //     for (Uint8List src in src_list) {
    //         print(src_list.indexOf(src));
    //         ScriptElement s = new ScriptElement();
    //         // s.type = "text/javascript";
    //         // s.async = true;
    //         s.src = 'data:text/javascript;base64,' +  b64urlcoder.encode(src);
    //         // print(s.innerText);
    //         // s.charset?
    //         document.body!.nodes.add(s);
    //     }
        
    // }    // try sync first if need async then switch location
}






onthewebcheck getonthewebcheckstance() => onthewebcheckweb();

