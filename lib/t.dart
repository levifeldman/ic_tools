import 'cbor/main.dart';
import 'ic-tools.dart';
import 'dart:typed_data';
import 'onthewebcheck/main.dart';
import 'package:leb128/leb128.dart';





void main() async {
    //var x = 'l';
    //print(x);

    //U u = U();
    //
    //print('<hello>'.replaceFirst('<', '').replaceFirst('>',''));

    //print('dfsfd_lkjlkj'.split('_').removeLast());
    
    // Map m = {
    //     't': U.create
    // };
    // print(m['t']().h);

    // int input = 624485;
    // Uint8List output= Leb128.encodeUnsigned(input);
    // output.forEach((x) {
    //     print(x.toRadixString(16) + ' - ' + x.toString());
    // });

    // print(utf8.encode('Aic-request'));
    // print(ascii.encode('hi'));
    // print(DateTime.now().hashCode.toRadixString(2));
    // print(utf8.encode('hi'));
    // List<int> l = [];
    // l.addAll(sha256.convert(ascii.encode('request_type')).bytes);
    // l.addAll(sha256.convert(utf8.encode('call')).bytes);
    
    // print(hex.encode(l));

    // print(sha256.convert(utf8.encode('f')));

    // var x = [[0,0,1,1,0,0,1],[1,0,1,0,0,0],[0,0,1,1,1,1]];
    // x.sort((a,b) => a.join().compareTo(b.join()));
    // print(x);
    // Uint8Buffer u = Uint8Buffer();
    // u.add(5);
    // print(u);

    // Map<String,dynamic> m = {
    //     "content": {
    //         "request_type": "call",
    //         "canister_id": Uint8List.view(hexToBytes('ABCD01')!),
    //         "method_name": "say_hello",
    //         "arg": Uint8List.view(hexToBytes('0061736d01000000')!)
    //     },
    //     "sender_sig": Uint8List.view(hexToBytes('DEADBEEF')!),
    //     "sender_pubkey": Uint8List.view(hexToBytes('b7a3c12dc0c8c748ab07525b701122b88bd78f600c76342d27f25e5f92444cde')!)
    // };
    // Uint8List bl = icquestbodymapcborcode(m);
    // String x = '';
    // bl.forEach((int i) {
    //     x = x+i.toRadixString(16);
    // });
    // print(x);
    // print('---------');
    // print(iccborsponsebytesasamap(bl));


    // print('---------------------------------------');
    
    // Map map = { 
    //     "request_type": "call", 
    //     "canister_id": Uint8List.view(hexToBytes('00000000000004D2')!), 
    //     "method_name": "hello", 
    //     "arg": Uint8List.fromList([])
    // };
    // print(sha256.convert(map['arg']));

    // var x = Uint8List.view(hexToBytes('ABCD01')!);
    // print(x);
    // print(icidblobasatext(x));
    // print(hex.encode(icidtextasablob('em77e-bvlzu-aq')));
    // print(hex.encode(icidtextasablob('ryjl3-tyaaa-aaaaa-aaaba-cai')));




    // String canisteridtext = 'rrkah-fqaaa-aaaaa-aaaaq-cai';
    // String canisteridtext = 'aaaaa-aa';
    print(await ictest());








    // {tree: 
    //     [
    //         [
    //             prune-8b19d3da898292bdd26a7bd31dc95bc3e97628dc586379fdf386a343e723abcc, 
    //             [
    //                 {
    //                     request_status: [
    //                         [
    //                             prune-a0cdfdaaf62de0ebca793fe4dde715c0de3b345a051b72be034074ff23c9b07f, 
    //                             [
    //                                 [
    //                                     [
    //                                         prune-26a1f833842acfc22b138e4e31627853039a677dd6e1889888286bea3e305f90, 
    //                                         [
    //                                             [
    //                                                 {
    //                                                     [101, 141, 170, 214, 187, 181, 219, 187, 86, 137, 248, 3, 170, 42, 115, 228, 100, 105, 135, 176, 57, 230, 113, 245, 81, 232, 48, 162, 43, 6, 82, 76]: [
    //                                                         prune-734ac5064590136f680886289dedcb131156ddaddf7de8b32855980978ad422d, 
    //                                                         {
    //                                                             status: replied
    //                                                         }
    //                                                     ]
    //                                                 }, 
    //                                                 prune-18b37c626ab75171940e71e271c2a7caf52771b4fdff2c1609da028dbdf47149
    //                                             ], 
    //                                             prune-3d6bf25a16ea6b0b1f7a34c0c15678e69fcb038c4fc2c3d36ebad8871394a6cb
    //                                         ]
    //                                     ], 
    //                                     prune-de28749dcfc9e808ee1aa63e5e81f2b604a24b20a84e170f68f8b51871834ce1
    //                                 ], 
    //                                 prune-5c48e03e533d6d2138a6afcdf32998fcb127908600f40cc5317f261c3fc370cc
    //                             ]
    //                         ], 
    //                         prune-3af392b3562f814e7e45b779cb6d982db98ed2d29565b3f35e473b785b98956d
    //                     ]
    //                 }, 
    //                 prune-8176f976f14972cba7f87f97c3c8a0349e75444d8cc93ab511abda2c21bfa664
    //             ]
    //         ],
    //         [
    //             prune-077a2ef106a6921ff653f5f454e458efb7fca0aac77cb378144af93c01615cb5, 
    //             {
    //                 time: 1622264548802195869
    //             }
    //         ]
    //     ], 
    //     signature: 893c6545c0c5479068b92d1fccc0a4ebc45a828769638c074b820da9416cf1ba0ff7dda224d65c211225e8589df249c4
    // }

    // print(Uint8List.view(hexToBytes('308182301d060d2b0601040182dc7c0503010201060c2b0601040182dc7c05030201036100')!));



}





class U {
    final h = 'string';
    static create() => U();
}


Future<dynamic> ictest() async {
    
    // print(Leb128.encodeUnsigned(500));

    IC ic = IC('ryjl3-tyaaa-aaaaa-aaaba-cai');
    return await ic.callCanister(calltype: 'call', methodName: 'account_balance_dfx');
    
    // var v;
    // if (isontheweb) {
    //     v = Leb128.encodeUnsigned(BigInt.parse('1623210160036000000'));
    // } else {
    //     v = Leb128.encodeUnsigned(1623210160036000000);
    // }

    // print(v);

    // List<List<dynamic>> paths = [
    //                     ['time'],
    //                     ['request_status', Uint8List.fromList([1,2,3,4,5]), 'status'], 
    //                     ['request_status', Uint8List.fromList([1,2,3,4,5]), 'reply']
    //                 ];
    // List<List<Uint8List>> pathsbytes = paths.map((path)=>pathasapathbyteslist(path)).toList();
    // print(pathsbytes);
    // print(cborflutter.codeMap({'12345': pathsbytes}));
    
    
    // if (isontheweb) {
    //     print(cborflutter.codeMap({'lllll': BigInt.parse('1623210160036000000')}));
    // } else {
    //     print(cborflutter.codeMap({'lllll': 1623210160036000000}));
    // }
    // print(DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch*1000000);

    // List<List<dynamic>> paths = [
    //                     ['time'],
    //                     ['request_status', Uint8List.fromList([1,2,3,4,5]), 'status'], 
    //                     ['request_status', Uint8List.fromList([1,2,3,4,5]), 'reply']
    //                 ];
    // List<List<Uint8List>> pathsbytes = paths.map((path)=>pathasapathbyteslist(path)).toList();
    // Map getstatequestbodymap = {
    //     //"sender_pubkey": (blob)(optional)(for the authentication of this quest.) (The public key must authenticate the sender principal when it is set. set pubkey and sender_sig when sender is not the anonymous principal)()
    //     // "sender_delegation": ([] of the maps) ?find out more
    //     //"sender_sig": (blob)(optional)(for the authentication of this quest.)(by the secret_key-authorization: concatenation of the 11 bytes \x0Aic-request (the domain separator) and the 32 byte request id)
    //     "content": { // (quest-id is of this content-map)
    //         "request_type": 'read_state',//(text)
    //         "paths": pathsbytes,  // createstatequestpaths(paths, pathvariables),
    //         "sender": Uint8List.fromList([4]), // anonymous in the now(Principal) (:quirement. can be the anonymous principal? find out what is the anonymous principal.-> anonymous-principal is: byte: 0x04/00000100 .)(:self-authentication-id =  SHA-224(public_key) · 0x02 (29 bytes).))
    //         "nonce": Uint8List.fromList([1,1,1,1,1,1,1,1,1,1]),  // (blob)(optional)(used when make same quest soon between but make sure system sees two seperate quests) , 
    //         "ingress_expiry": createicquestingressexpiry()  // (nat)(:quirement.) (time of message time-out in nanoseconds since 1970)
    //     }
    // };
    // if (isontheweb) {
    //     getstatequestbodymap['content']['ingress_expiry'] = BigInt.parse('1623210160036000000');
    // } else {
    //     getstatequestbodymap['content']['ingress_expiry'] = 1623210160036000000;
    // }
    // print(cborflutter.codeMap(getstatequestbodymap));





    // Map canistercallquestbodymap = {
    //     //"sender_pubkey": (blob)(optional)(for the authentication of this quest.) (The public key must authenticate the sender principal when it is set. set pubkey and sender_sig when sender is not the anonymous principal)()
    //     // "sender_delegation": ([] of the maps) ?find out more. "(array of maps, optional): a chain of delegations, starting with the one signed by sender_pubkey and ending with the one delegating to the key relating to sender_sig."
    //     //"sender_sig": (blob)(optional)(for the authentication of this quest.)(by the secret_key-authorization: concatenation of the 11 bytes \x0Aic-request (the domain separator) and the 32 byte request id)
    //     "content": { // (quest-id is of this content-map)
    //         "request_type": 'call',//(text)
    //         "canister_id": Uint8List.fromList([1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9]), //(blob)(29-bytes)
    //         "method_name": 'methodname',//(text)(:name: canister-method.),
    //         "arg": Uint8List.fromList([68, 73, 68, 76, 1, 108, 1, 173, 249, 231, 138, 10, 113, 1, 0, 64, 99, 52, 50, 101, 54, 55, 53, 101, 56, 48, 52, 57, 56, 51, 50, 100, 99, 52, 97, 100, 56, 101, 102, 48, 99, 55, 55, 100, 54, 98, 56, 101, 56, 97, 99, 102, 51, 51, 97, 98, 99, 53, 53, 97, 100, 55, 52, 48, 53, 50, 53, 51, 53, 55, 101, 49, 57, 54, 97, 99, 53, 50, 97, 102]), //createcandidparams(),// (blob), (in the candid?)	
    //         "sender": Uint8List.fromList([4]), // anonymous in the now(Principal) (:quirement. can be the anonymous principal? find out what is the anonymous principal.-> anonymous-principal is: byte: 0x04/00000100 .)(:self-authentication-id =  SHA-224(public_key) · 0x02 (29 bytes).))
    //         "nonce": Uint8List.fromList([1,1,1,1,1,1,1,1,1,1]),  // (blob)(optional)(used when make same quest soon between but make sure system sees two seperate quests) , 
    //         "ingress_expiry": createicquestingressexpiry()  // (nat)(:quirement.) (time of message time-out in nanoseconds since 1970)
    //     }
    // };
    // if (isontheweb) {
    //     canistercallquestbodymap['content']['ingress_expiry'] = BigInt.parse('1623210160036000000');
    // } else {
    //     canistercallquestbodymap['content']['ingress_expiry'] = 1623210160036000000;
    // }
    // print(cborflutter.codeMap(canistercallquestbodymap, withaselfscribecbortag: true));
}







// [217, 217, 247, 161, 103, 99, 111, 110, 116, 101, 110, 116, 167, 108, 114, 101, 113, 117, 101, 115, 116, 95, 116, 121, 112, 101, 100, 99, 97, 108, 108, 107, 99, 97, 110, 105, 115, 116, 101, 114, 95, 105, 100, 74, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 107, 109, 101, 116, 104, 111, 100, 95, 110, 97, 109, 101, 115, 97, 99, 99, 111, 117, 110, 116, 95, 98, 97, 108, 97, 110, 99, 101, 95, 100, 102, 120, 99, 97, 114, 103, 88, 80, 68, 73, 68, 76, 1, 108, 1, 173, 249, 231, 138, 10, 113, 1, 0, 64, 99, 52, 50, 101, 54, 55, 53, 101, 56, 48, 52, 57, 56, 51, 50, 100, 99, 52, 97, 100, 56, 101, 102, 48, 99, 55, 55, 100, 54, 98, 56, 101, 56, 97, 99, 102, 51, 51, 97, 98, 99, 53, 53, 97, 100, 55, 52, 48, 53, 50, 53, 51, 53, 55, 101, 49, 57, 54, 97, 99, 53, 50, 97, 102, 102, 115, 101, 110, 100, 101, 114, 65, 4, 101, 110, 111, 110, 99, 101, 88, 29, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 110, 105, 110, 103, 114, 101, 115, 115, 95, 101, 120, 112, 105, 114, 121, 27, 22, 134, 142, 216, 95, 98, 75, 128]



// Error: Exception: :getstatesponsestatuscode: 422, body:
// Could not parse body as read request: invalid type: map, expected a sequence



// to do invalid type: sequence, expected a borrowed byte array





// [161, 103, 99, 111, 110, 116, 101, 110, 116, 165, 108, 114, 101, 113, 117, 101, 115, 116, 95, 116, 121, 112, 101, 106, 114, 101, 97, 100, 95, 115, 116, 97, 116, 101, 101, 112, 97, 116, 104, 115, 131, 129, 68, 116, 105, 109, 101, 131, 78, 114, 101, 113, 117, 101, 115, 116, 95, 115, 116, 97, 116, 117, 115, 69, 1, 2, 3, 4, 5, 70, 115, 116, 97, 116, 117, 115, 131, 78, 114, 101, 113, 117, 101, 115, 116, 95, 115, 116, 97, 116, 117, 115, 69, 1, 2, 3, 4, 5, 69, 114, 101, 112, 108, 121, 102, 115, 101, 110, 100, 101, 114, 65, 4, 101, 110, 111, 110, 99, 101, 74, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 110, 105, 110, 103, 114, 101, 115, 115, 95, 101, 120, 112, 105, 114, 121, 27, 22, 134, 205, 10, 88, 192, 49, 0]

// [161, 103, 99, 111, 110, 116, 101, 110, 116, 165, 108, 114, 101, 113, 117, 101, 115, 116, 95, 116, 121, 112, 101, 106, 114, 101, 97, 100, 95, 115, 116, 97, 116, 101, 101, 112, 97, 116, 104, 115, 131, 129, 68, 116, 105, 109, 101, 131, 78, 114, 101, 113, 117, 101, 115, 116, 95, 115, 116, 97, 116, 117, 115, 69, 1, 2, 3, 4, 5, 70, 115, 116, 97, 116, 117, 115, 131, 78, 114, 101, 113, 117, 101, 115, 116, 95, 115, 116, 97, 116, 117, 115, 69, 1, 2, 3, 4, 5, 69, 114, 101, 112, 108, 121, 102, 115, 101, 110, 100, 101, 114, 65, 4, 101, 110, 111, 110, 99, 101, 74, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 110, 105, 110, 103, 114, 101, 115, 115, 95, 101, 120, 112, 105, 114, 121, 27, 22, 134, 205, 10, 88, 192, 49, 0]





// [161, 103, 99, 111, 110, 116, 101, 110, 116, 165, 108, 114, 101, 113, 117, 101, 115, 116, 95, 116, 121, 112, 101, 106, 114, 101, 97, 100, 95, 115, 116, 97, 116, 101, 101, 112, 97, 116, 104, 115, 131, 129, 68, 116, 105, 109, 101, 131, 78, 114, 101, 113, 117, 101, 115, 116, 95, 115, 116, 97, 116, 117, 115, 69, 1, 2, 3, 4, 5, 70, 115, 116, 97, 116, 117, 115, 131, 78, 114, 101, 113, 117, 101, 115, 116, 95, 115, 116, 97, 116, 117, 115, 69, 1, 2, 3, 4, 5, 69, 114, 101, 112, 108, 121, 102, 115, 101, 110, 100, 101, 114, 65, 4, 101, 110, 111, 110, 99, 101, 74, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 110, 105, 110, 103, 114, 101, 115, 115, 95, 101, 120, 112, 105, 114, 121, 27, 22, 134, 205, 10, 88, 192, 49, 0]
// [161, 103, 99, 111, 110, 116, 101, 110, 116, 165, 108, 114, 101, 113, 117, 101, 115, 116, 95, 116, 121, 112, 101, 106, 114, 101, 97, 100, 95, 115, 116, 97, 116, 101, 101, 112, 97, 116, 104, 115, 131, 129, 68, 116, 105, 109, 101, 131, 78, 114, 101, 113, 117, 101, 115, 116, 95, 115, 116, 97, 116, 117, 115, 69, 1, 2, 3, 4, 5, 70, 115, 116, 97, 116, 117, 115, 131, 78, 114, 101, 113, 117, 101, 115, 116, 95, 115, 116, 97, 116, 117, 115, 69, 1, 2, 3, 4, 5, 69, 114, 101, 112, 108, 121, 102, 115, 101, 110, 100, 101, 114, 65, 4, 101, 110, 111, 110, 99, 101, 74, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 110, 105, 110, 103, 114, 101, 115, 115, 95, 101, 120, 112, 105, 114, 121, 27, 22, 134, 205, 10, 88, 192, 49, 0]




// [217, 217, 247, 161, 103, 99, 111, 110, 116, 101, 110, 116, 167, 108, 114, 101, 113, 117, 101, 115, 116, 95, 116, 121, 112, 101, 100, 99, 97, 108, 108, 107, 99, 97, 110, 105, 115, 116, 101, 114, 95, 105, 100, 88, 29, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 107, 109, 101, 116, 104, 111, 100, 95, 110, 97, 109, 101, 106, 109, 101, 116, 104, 111, 100, 110, 97, 109, 101, 99, 97, 114, 103, 88, 80, 68, 73, 68, 76, 1, 108, 1, 173, 249, 231, 138, 10, 113, 1, 0, 64, 99, 52, 50, 101, 54, 55, 53, 101, 56, 48, 52, 57, 56, 51, 50, 100, 99, 52, 97, 100, 56, 101, 102, 48, 99, 55, 55, 100, 54, 98, 56, 101, 56, 97, 99, 102, 51, 51, 97, 98, 99, 53, 53, 97, 100, 55, 52, 48, 53, 50, 53, 51, 53, 55, 101, 49, 57, 54, 97, 99, 53, 50, 97, 102, 102, 115, 101, 110, 100, 101, 114, 65, 4, 101, 110, 111, 110, 99, 101, 74, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 110, 105, 110, 103, 114, 101, 115, 115, 95, 101, 120, 112, 105, 114, 121, 27, 22, 134, 205, 10, 88, 192, 49, 0]
// [217, 217, 247, 161, 103, 99, 111, 110, 116, 101, 110, 116, 167, 108, 114, 101, 113, 117, 101, 115, 116, 95, 116, 121, 112, 101, 100, 99, 97, 108, 108, 107, 99, 97, 110, 105, 115, 116, 101, 114, 95, 105, 100, 88, 29, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 107, 109, 101, 116, 104, 111, 100, 95, 110, 97, 109, 101, 106, 109, 101, 116, 104, 111, 100, 110, 97, 109, 101, 99, 97, 114, 103, 88, 80, 68, 73, 68, 76, 1, 108, 1, 173, 249, 231, 138, 10, 113, 1, 0, 64, 99, 52, 50, 101, 54, 55, 53, 101, 56, 48, 52, 57, 56, 51, 50, 100, 99, 52, 97, 100, 56, 101, 102, 48, 99, 55, 55, 100, 54, 98, 56, 101, 56, 97, 99, 102, 51, 51, 97, 98, 99, 53, 53, 97, 100, 55, 52, 48, 53, 50, 53, 51, 53, 55, 101, 49, 57, 54, 97, 99, 53, 50, 97, 102, 102, 115, 101, 110, 100, 101, 114, 65, 4, 101, 110, 111, 110, 99, 101, 74, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 110, 105, 110, 103, 114, 101, 115, 115, 95, 101, 120, 112, 105, 114, 121, 27, 22, 134, 205, 10, 88, 192, 49, 0]








