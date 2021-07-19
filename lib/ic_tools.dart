// FOR THE DO: 

// create Authorization-keys, call with an authorization. 
// bls on the liinux



import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:cbor/cbor.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:typed_data/typed_data.dart';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:base32/base32.dart';
import 'tools.dart';
import 'onthewebcheck/main.dart' show isontheweb;
import 'cbor/main.dart';
import 'leb128/main.dart' show leb128flutter;
import 'bls12381/main.dart' show bls12381flutter;
import 'candid/candid.dart';



String icbaseurl = 'https://ic0.app';
Uint8List icrootkey = Uint8List.fromList([48, 129, 130, 48, 29, 6, 13, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 1, 2, 1, 6, 12, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 2, 1, 3, 97, 0, 129, 76, 14, 110, 199, 31, 171, 88, 59, 8, 189, 129, 55, 60, 37, 92, 60, 55, 27, 46, 132, 134, 60, 152, 164, 241, 224, 139, 116, 35, 93, 20, 251, 93, 156, 12, 213, 70, 217, 104, 95, 145, 58, 12, 11, 44, 197, 52, 21, 131, 191, 75, 67, 146, 228, 103, 219, 150, 214, 91, 155, 180, 203, 113, 113, 18, 248, 71, 46, 13, 90, 77, 20, 80, 95, 253, 116, 132, 176, 18, 145, 9, 28, 95, 135, 185, 136, 131, 70, 63, 152, 9, 26, 11, 170, 174]);
// String icversion ?

Future<Map> ic_status() async {
    http.Response statussponse = await http.get(Uri.parse(icbaseurl + '/api/v2/status'));
    return cborflutter.cborbytesasadart(statussponse.bodyBytes);
}


class Canister {
    Uint8List canisterIdBlob;
    String canisterIdText;
    String canisterbaseurl;
    Canister(this.canisterIdText) : canisterIdBlob= icidtextasablob(canisterIdText), canisterbaseurl= icbaseurl + '/api/v2/canister/$canisterIdText/';

    Future<Uint8List> module_hash() async {
        List<dynamic> paths_values = await state(paths: [['canister', canisterIdBlob, 'module_hash']]);
        return paths_values[0];
    }
    Future<List<Uint8List>> controllers() async {
        List<dynamic> paths_values = await state(paths: [['canister', canisterIdBlob, 'controllers']]);
        List<dynamic> controllers_list = cborflutter.cborbytesasadart(paths_values[0]); //?buffer? orr List
        List<Uint8List> controllers_list_uint8list = controllers_list.map((controller_buffer)=>Uint8List.fromList(controller_buffer.toList())).toList();
        return controllers_list_uint8list;
    }
    // make a principal/id class that has a .bytes and .text
    Future<List<String>> controllers_as_text() async {
        List<Uint8List> controllers_list = await controllers();
        return controllers_list.map((controller_bytes)=>icidblobasatext(controller_bytes)).toList();
    }    
    
    // Note that the paths /canisters/<canister_id>/certified_data are not accessible with this method; these paths are only exposed to the canister themselves via the System API (see Certified data).
    
    

    Future<List> state({required List<List<dynamic>> paths, http.Client? httpclient}) async {        
        http.Request systemstatequest = http.Request('post', Uri.parse(canisterbaseurl + 'read_state'));
        systemstatequest.headers['Content-Type'] = 'application/cbor';
        List<List<Uint8List>> pathsbytes = paths.map((path)=>pathasapathbyteslist(path)).toList();
        Map getstatequestbodymap = {
            //"sender_pubkey": (blob)(optional)(for the authentication of this quest.) (The public key must authenticate the sender principal when it is set. set pubkey and sender_sig when sender is not the anonymous principal)()
            // "sender_delegation": ([] of the maps) ?find out more
            //"sender_sig": (blob)(optional)(for the authentication of this quest.)(by the secret_key-authorization: concatenation of the 11 bytes \x0Aic-request (the domain separator) and the 32 byte request id)
            "content": { // (quest-id is of this content-map)
                "request_type": 'read_state',//(text)
                "paths": pathsbytes,  // createstatequestpaths(paths, pathvariables),
                "sender": Uint8List.fromList([4]), // anonymous in the now(Principal) (:quirement. can be the anonymous principal? find out what is the anonymous principal.-> anonymous-principal is: byte: 0x04/00000100 .)(:self-authentication-id =  SHA-224(public_key) · 0x02 (29 bytes).))
                "nonce": createicquestnonce(),  // (blob)(optional)(used when make same quest soon between but make sure system sees two seperate quests) , 
                "ingress_expiry": createicquestingressexpiry()  // (nat)(:quirement.) (time of message time-out in nanoseconds since 1970)
            }
        };
        systemstatequest.bodyBytes = cborflutter.codeMap(getstatequestbodymap, withaselfscribecbortag: true);
        bool need_close_httpclient = false;
        if (httpclient==null) {
            httpclient = http.Client();
            need_close_httpclient == true;
        }
        http.Response statesponse = await http.Response.fromStream(await httpclient.send(systemstatequest));
        if (need_close_httpclient) { httpclient.close(); }
        if (statesponse.statusCode==200) {
            Map systemstatesponsemap = cborflutter.cborbytesasadart(statesponse.bodyBytes);
            Map certificate = cborflutter.cborbytesasadart(Uint8List.fromList(systemstatesponsemap['certificate'].toList()));
            verifycertificate(certificate); // will throw an exception if certificate is not valid.
            // print(certificate['tree']);
            List pathsvalues = paths.map((path)=>lookuppathvalueinaniccertificatetree(certificate['tree'], path)).toList();
            return pathsvalues;
        } else {
            throw Exception(':getstatesponsestatuscode: ${statesponse.statusCode}, body:\n${statesponse.body}');
        }
    }


    Future<dynamic> call({required String calltype, required String methodName}) async {
        if(calltype != 'call' && calltype != 'query') { throw Exception('calltype must be "call" or "query"'); }
        var canistercallquest = http.Request('post', Uri.parse(canisterbaseurl + calltype));
        canistercallquest.headers['Content-Type'] = 'application/cbor';
        Map canistercallquestbodymap = {
            //"sender_pubkey": (blob)(optional)(for the authentication of this quest.) (The public key must authenticate the sender principal when it is set. set pubkey and sender_sig when sender is not the anonymous principal)()
            // "sender_delegation": ([] of the maps) ?find out more. "(array of maps, optional): a chain of delegations, starting with the one signed by sender_pubkey and ending with the one delegating to the key relating to sender_sig."
            //"sender_sig": (blob)(optional)(for the authentication of this quest.)(by the secret_key-authorization: concatenation of the 11 bytes \x0Aic-request (the domain separator) and the 32 byte request id)
            "content": { // (quest-id is of this content-map)
                "request_type": calltype,//(text)
                "canister_id": canisterIdBlob, //(blob)(29-bytes)
                "method_name": methodName,//(text)(:name: canister-method.),
                "arg": Uint8List.fromList([68, 73, 68, 76, 1, 108, 1, 173, 249, 231, 138, 10, 113, 1, 0, 64, 99, 52, 50, 101, 54, 55, 53, 101, 56, 48, 52, 57, 56, 51, 50, 100, 99, 52, 97, 100, 56, 101, 102, 48, 99, 55, 55, 100, 54, 98, 56, 101, 56, 97, 99, 102, 51, 51, 97, 98, 99, 53, 53, 97, 100, 55, 52, 48, 53, 50, 53, 51, 53, 55, 101, 49, 57, 54, 97, 99, 53, 50, 97, 102]), //createcandidparams(),// (blob), (in the candid?)	
                "sender": Uint8List.fromList([4]), // anonymous in the now(Principal) (:quirement. can be the anonymous principal? find out what is the anonymous principal.-> anonymous-principal is: byte: 0x04/00000100 .)(:self-authentication-id =  SHA-224(public_key) · 0x02 (29 bytes).))
                "nonce": createicquestnonce(),  // (blob)(optional)(used when make same quest soon between but make sure system sees two seperate quests) , 
                "ingress_expiry": createicquestingressexpiry()  // (nat)(:quirement.) (time of message time-out in nanoseconds since 1970)
            }
        };
        Uint8List questId = icdatahash(canistercallquestbodymap['content']); // 32 bytes/256-bits with the sha256.    
        // auth fields set here if the call is with the authorization

        canistercallquest.bodyBytes = cborflutter.codeMap(canistercallquestbodymap,withaselfscribecbortag: true);
        var httpclient = http.Client();
        http.Response canistercallsponse = await http.Response.fromStream(await httpclient.send(canistercallquest));
        if (![202,200].contains(canistercallsponse.statusCode)) {
            // need "exception" here ? 
            throw Exception('ic call gave http-sponse-status: ${canistercallsponse.statusCode}, with a body: ${canistercallsponse.body}');
        }
        dynamic canistersponse;
        if (calltype == 'call') {
            List pathsvalues = [];
            String? callstatus;
            //:do: if poll certian mount of the times and no-sponse then try call again (with same nonce?)
            int c = 0;
            while (!['replied','rejected','done'].contains(callstatus) && c <= 15) {
                c += 1;
                print(':poll of the system-state.');
                await Future.delayed(Duration(seconds:2));
                pathsvalues = await state( 
                    paths: [
                        ['time'],
                        ['request_status', questId, 'status'], 
                        ['request_status', questId, 'reply']
                    ], 
                    httpclient: httpclient 
                ); 
                callstatus = pathsvalues[1];            
            }
            print(pathsvalues);
            if (callstatus=='replied') {
                canistersponse = candidsponsebytesasthedarttypes(pathsvalues[2]);
            }
        } 
        else 
        if (calltype == 'query') {
            canistersponse = cborflutter.cborbytesasadart(canistercallsponse.bodyBytes); // make canister sponse just the reply           
        }
        httpclient.close();
        return canistersponse;
    }




}





List<Uint8List> pathasapathbyteslist(List<dynamic> path) {
    // a path is a list of labels, see the ic-spec. 
    // this function converts string labels to utf8 blobs in a new-list for the convenience. 
    List<dynamic> pathb = [];
    for (int i=0;i<path.length;i++) { 
        pathb.add(path[i]);
        if (pathb[i] is String) {
            pathb[i] = utf8.encode(pathb[i]);    
        }
        // if (pathb[i] is List<int>) {
        //     pathb[i] = Uint8List.fromList(pathb[i]);
        // }??
    }
    return List.castFrom<dynamic, Uint8List>(pathb);
}



// Uint8List icquestbodymapcborcode(Map questbodymap) {
//     // Cbor cborcoder = Cbor(); 
//     // cborcoder.encoder.writeTag(tagSelfDescribedCbor);
//     // cborcoder.encoder.writeMap(questbodymap);
//     // return Uint8List.fromList(cborcoder.output.getData());
    
//     return Uint8List.fromList(Uint8List.fromList([217,217,247]) + cbor.encodeOne(dartmapasajsstruct(questbodymap), dartmapasajsstruct({'canonical': true, 'collapseBigIntegers': true})));
// }

// Map iccborsponsebytesasamap(Uint8List cborbytes) {
//     Cbor cborcoder = Cbor();
//     cborcoder.decodeFromList(cborbytes);
//     List? datalist = cborcoder.getDecodedData();
//     if (datalist==null) { throw Exception('cbor transform is null'); }
//     if (datalist.length<1 || datalist.length>1) { print(datalist); throw Exception('getdecodeddata gives ${datalist.length} items in the getdecodeddata-list'); }
//     return datalist[0];
// }

Uint8List icdatahash(dynamic datastructure, {bool show=false}) {
    var valueforthehash = <int>[];
    if (datastructure is String) {
        valueforthehash = utf8.encode(datastructure); }
    else if (datastructure is int || datastructure is BigInt) {
        valueforthehash = leb128flutter.encodeUnsigned(datastructure); }
    // else if (datastructure is BigInt) {
    //     valueforthehash = Leb128.encodeUnsigned(datastructure); }  // FIX THIS DATA how to get bytes on leb128 codeUnsigned(of a bigint/jsbignumber)
    else if (datastructure is Uint8List) {
        valueforthehash= datastructure; }
    else if (datastructure is List) {
        valueforthehash= datastructure.fold(<int>[], (p,c)=> p + icdatahash(c)); } 
    else if (datastructure is Map) {
        List<List<int>> datafieldshashs = [];
        for (String key in datastructure.keys) {
            List<int> fieldhash = [];
            fieldhash.addAll(sha256.convert(ascii.encode(key)).bytes);
            fieldhash.addAll(icdatahash(datastructure[key]));
            datafieldshashs.add(fieldhash);
            if (show==true) { print('fieldhash: ' + bytesasahexstring(fieldhash)); }
        }
        datafieldshashs.sort((a,b) => bytesasabitstring(a).compareTo(bytesasabitstring(b)));
        if (show==true) {
            for (List<int> fh in datafieldshashs) {
                print('with the sort: ' + datafieldshashs.indexOf(fh).toString() + ': ' + bytesasahexstring(fh));
            }
        }
        valueforthehash = datafieldshashs.fold(<int>[],(p,c)=>p+c); }
    else { 
        throw Exception('icdatahash: check: type of the datastructure: ${datastructure.runtimeType}');    
    } 
    return Uint8List.fromList(sha256.convert(valueforthehash).bytes);
}
 
String icidblobasatext(Uint8List idblob) {
    // Grouped(Base32(CRC32(b) · b)) 
    // The textual representation is conventionally printed with lower case letters, but parsed case-insensitively.
    Crc32 crc32 = Crc32();
    crc32.add(idblob);
    List<int> crc32checksum = crc32.close();
    Uint8List idblobwiththecrc32 = Uint8List.fromList(crc32checksum + idblob);
    String base32string = base32.encode(idblobwiththecrc32);
    String finalstring = '';
    for (int i=0;i<base32string.length; i++) {
        if (base32string[i]=='=') { break; } // base32 without the padding-char: '='
        finalstring+= base32string[i];
        if ((i+1)%5==0 && i!=base32string.length-1) { finalstring+= '-'; }
    }
    return finalstring.toLowerCase();
}

Uint8List icidtextasablob(String idtext) {
    String idbase32code = idtext.replaceAll('-', '');
    if (idbase32code.length%2!=0) { idbase32code+='='; }
    return Uint8List.fromList(base32.decode(idbase32code).sublist(4));
}

// "The recommended textual representation of a request id is a hexadecimal string with lower-case letters prefixed with '0x'. E.g., request id consisting of bytes [00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 0A, 0B, 0C, 0D, 0E, 0F, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 1A, 1B, 1C, 1D, 1E, 1F] should be displayed as 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f. ""
String questidbytesasastring(Uint8List questIdBytes) {
    return '0x' + bytesasahexstring(questIdBytes).toLowerCase();
}

Uint8List questidstringasabytes(String questIdString) {
    return Uint8List.view(hexToBytes(questIdString.substring(2))!);
}

Uint8List createicquestnonce() {
    return Uint8List.fromList(DateTime.now().hashCode.toRadixString(2).split('').map(int.parse).toList());
}

dynamic createicquestingressexpiry([Duration? duration]) { //can be a bigint or an int
    if (duration==null) {
        duration = (Duration(minutes: 4));
    }
    if (isontheweb) {
        return BigInt.from(DateTime.now().add(duration).millisecondsSinceEpoch)*BigInt.from(1000000); // microsecondsSinceEpoch*1000;
    } else {
        return DateTime.now().add(duration).millisecondsSinceEpoch*1000000; // microsecondsSinceEpoch*1000;
    }
}

Uint8List createdomainseparatorbytes(String domainsepstring) {
    return Uint8List.fromList([domainsepstring.length]..addAll(utf8.encode(domainsepstring)));
}

Uint8List constructicsystemstatetreeroothash(List tree) {
    List<int> v;
    if (tree[0] == 0) {
        assert(tree.length==1); 
        v = sha256.convert(createdomainseparatorbytes("ic-hashtree-empty")).bytes;
    } 
    if (tree[0] == 1) {
        assert(tree.length==3);
        v = sha256.convert(createdomainseparatorbytes("ic-hashtree-fork") + constructicsystemstatetreeroothash(tree[1]) + constructicsystemstatetreeroothash(tree[2])).bytes;
    }
    else if (tree[0] == 2) {
        assert(tree.length==3);
        v = sha256.convert(createdomainseparatorbytes("ic-hashtree-labeled") + tree[1] + constructicsystemstatetreeroothash(tree[2])).bytes;
    }
    else if (tree[0] == 3) {
        assert(tree.length==2); 
        v = sha256.convert(createdomainseparatorbytes("ic-hashtree-leaf") + tree[1]).bytes;
    }
    else if (tree[0] == 4) {
        assert(tree.length==2);
        v = tree[1];
    }    
    else {
        throw Exception(':system-state-tree is in the wrong-format.');
    }
    return Uint8List.fromList(v);
}

Uint8List derkeyasablskey(Uint8List derkey) {
    const int keylength = 96;
    Uint8List derprefix = Uint8List.fromList([48, 129, 130, 48, 29, 6, 13, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 1, 2, 1, 6, 12, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 2, 1, 3, 97, 0]);
    if ( derkey.length != derprefix.length+keylength ) { throw Exception(':wrong-length of the der-key.'); }
    if ( aresamebytes(derkey.sublist(0,derprefix.length), derprefix)==false ) { throw Exception(':wrong-begin of the der-key.'); }
    return derkey.sublist(derprefix.length);

}

void verifycertificate(Map certificate) {
    Uint8List treeroothash = constructicsystemstatetreeroothash(certificate['tree']);
    Uint8List derKey;
    if (certificate.containsKey('delegation')) {
        Map legation_certificate = cborflutter.cborbytesasadart(Uint8List.fromList(certificate['delegation']['certificate']));
        verifycertificate(legation_certificate);
        derKey = lookuppathvalueinaniccertificatetree(legation_certificate['tree'], ['subnet', Uint8List.fromList(certificate['delegation']['subnet_id'].toList()), 'public_key']);
    } else {
        derKey = icrootkey; }
    Uint8List blskey = derkeyasablskey(derKey);
    print("sig len: ${certificate['signature'].length}, pk len: ${blskey.length}");
    bool certificatevalidity = bls12381flutter.verify(Uint8List.fromList(certificate['signature'].toList()), Uint8List.fromList(createdomainseparatorbytes('ic-state-root').toList()..addAll(treeroothash)), blskey);
    print(certificatevalidity);
    if (certificatevalidity == false) { 
        // print(':CERTIFICATE IS: VOID.');
        throw Exception(':CERTIFICATE IS: VOID.'); 
    }
}

String getstatetreepathvaluetype(List<dynamic> path) {
    String? valuetype;
    if (path.length == 1) {
        if (path[0]=='time') {
            valuetype = 'natural';
        }
    } 
    else if (path.length == 3) {
        if (path[0]=='subnet') {
            if (path[2]=='public_key') {
                valuetype = 'blob';
            }
        }
        if (path[0]=='request_status') {
            if (path[2]=='status') {
                valuetype = 'text';
            }
            else if (path[2]=='reply') {
                valuetype = 'blob';
            }
            else if (path[2]=='reject_code') {
                valuetype = 'natural';
            }
            else if (path[2]=='reject_message') {
                valuetype = 'text';
            }
        }
        if (path[0]=='canister') {
            if (path[2]=='certified_data') {
                valuetype = 'blob';
            }
            else if (path[2]=='module_hash') {
                valuetype = 'blob';
            }
            else if (path[2]=='controllers') {
                valuetype = 'blob';
            }
        }
    }
    if (valuetype==null) { throw Exception(':library is with the void-knowledge of the quest-path.'); }
    return valuetype;
}

Map<String, Function(Uint8List)> systemstatepathvaluetypetransform = {
    'blob'    : (li)=>li,
    'natural' : (li)=>leb128flutter.decodeUnsigned(li),
    'text'    : (li)=>utf8.decode(li)
};

List flattentreeforks(List tree) {
    if (tree[0]==0) {
        return [];
    }
    else if (tree[0]==1) {
        return flattentreeforks(tree[1]) + flattentreeforks(tree[2]);
    }
    return [tree];
}
    
dynamic lookuppathvalueinaniccertificatetree(List tree, List<dynamic> path) {
    Uint8List? valuebytes = lookuppathbvaluebinaniccertificatetree(tree, pathasapathbyteslist(path));
    if (valuebytes==null) { return valuebytes; }
    return systemstatepathvaluetypetransform[getstatetreepathvaluetype(path)]!(valuebytes);
}

Uint8List? lookuppathbvaluebinaniccertificatetree(List tree, List<Uint8List> pathb) {
    if (pathb.length > 0) {
        List flattrees = flattentreeforks(tree);
        for (List flattree in flattrees) {
            if (flattree[0]==2) {
                if (aresamebytes(flattree[1], pathb[0]) == true) {
                    return lookuppathbvaluebinaniccertificatetree(flattree[2], pathb.sublist(1));
                }
            }
        }
    }
    else {
        if (tree[0]==3) {
            return Uint8List.fromList(tree[1]);
        }
    }
}










