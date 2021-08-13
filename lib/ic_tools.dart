// FOR THE DO: 

// create Authorization-keys, call with an authorization. 
// create legations-portunities

// check each curance of the int/BigInt .parse(), make sure radix parameter is correct

import 'dart:core';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:typed_data/typed_data.dart';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:archive/archive.dart';
import 'package:base32/base32.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

import 'tools/tools.dart';
import 'candid.dart';

DartSha256 sha256 = DartSha256();


String icbaseurl = 'https://ic0.app';
Uint8List icrootkey = Uint8List.fromList([48, 129, 130, 48, 29, 6, 13, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 1, 2, 1, 6, 12, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 2, 1, 3, 97, 0, 129, 76, 14, 110, 199, 31, 171, 88, 59, 8, 189, 129, 55, 60, 37, 92, 60, 55, 27, 46, 132, 134, 60, 152, 164, 241, 224, 139, 116, 35, 93, 20, 251, 93, 156, 12, 213, 70, 217, 104, 95, 145, 58, 12, 11, 44, 197, 52, 21, 131, 191, 75, 67, 146, 228, 103, 219, 150, 214, 91, 155, 180, 203, 113, 113, 18, 248, 71, 46, 13, 90, 77, 20, 80, 95, 253, 116, 132, 176, 18, 145, 9, 28, 95, 135, 185, 136, 131, 70, 63, 152, 9, 26, 11, 170, 174]);



Future<Map> ic_status() async {
    http.Response statussponse = await http.get(Uri.parse(icbaseurl + '/api/v2/status'));
    return cborflutter.cborbytesasadart(statussponse.bodyBytes);
}




class Principal {
    final Uint8List bytes;
    final String text;
    Principal(this.text) : bytes = icidtextasabytes(text);
    static Principal oftheBytes(Uint8List bytes) {
        Principal p = Principal(icidbytesasatext(bytes));
        if (aresamebytes(p.bytes, bytes) != true) {  throw Exception('ic id functions look '); }
        return p;
    }
    static Principal ofPublicKeyDER(Uint8List pub_key_der) {
        DartSha224 sha224 = DartSha224();
        List<int> principal_bytes = [];
        principal_bytes.addAll(sha224.hashSync(pub_key_der).bytes);
        principal_bytes.add(2);
        return Principal.oftheBytes(Uint8List.fromList(principal_bytes));
    }
    String toString() => 'Principal: ${this.text}';
}




abstract class Caller {
    final Uint8List public_key;
    final Uint8List private_key;
    late final Principal principal; 
    Uint8List get public_key_DER;

    Caller({required this.public_key, required this.private_key}) {
        this.principal = Principal.ofPublicKeyDER(public_key_DER); 
    }
    Future<Uint8List> private_key_authorize_function(Uint8List message);

    Future<Uint8List> authorize_call_questId(Uint8List questId) async {
        List<int> message = []; 
        message.addAll(utf8.encode('\x0Aic-request'));
        message.addAll(questId);
        return await private_key_authorize_function(Uint8List.fromList(message));
    }
}

class CallerEd25519 extends Caller {    
    CallerEd25519({required Uint8List public_key, required Uint8List private_key}) : super(public_key: public_key, private_key: private_key) {
        if (public_key.length != 32 || private_key.length != 32) {
            throw Exception('Ed25519 Public-key and Private-key both must be 32 bytes');
        }
    }
    static Future<CallerEd25519> new_keys() async {
        DartEd25519 ed25519 = DartEd25519();
        SimpleKeyPair simplekeypair = await ed25519.newKeyPair();
        List<int> pvate_key = await simplekeypair.extractPrivateKeyBytes(); 
        List<int> pub_key = (await simplekeypair.extractPublicKey()).bytes;
        return CallerEd25519(public_key: Uint8List.fromList(pub_key), private_key: Uint8List.fromList(pvate_key));
    }
    static Uint8List DER_public_key_start = Uint8List.fromList([
        ...[48, 42], // SEQUENCE
        ...[48, 5], // SEQUENCE
        ...[6, 3], // OBJECT
        ...[43, 101, 112], // Ed25519 OID
        ...[3], // OBJECT
        ...[32 + 1], // BIT STRING // ...[Ed25519PublicKey.RAW_KEY_LENGTH + 1],
        ...[0], // 'no padding'
    ]);
    Uint8List get public_key_DER => Uint8List.fromList([ ...DER_public_key_start, ...this.public_key]);
    Future<Uint8List> private_key_authorize_function(Uint8List message) async {
        DartEd25519 ed25519 = DartEd25519();
        SimpleKeyPairData simplekeypairdata = SimpleKeyPairData(this.private_key, publicKey: SimplePublicKey(this.public_key, type: KeyPairType.ed25519), type: KeyPairType.ed25519 );        
        Signature signature = await ed25519.sign(message, keyPair: simplekeypairdata ); 
        return Uint8List.fromList(signature.bytes);
    }
}




class Canister {
    final Principal principal;
    final String canisterbaseurl;

    Canister(this.principal) : canisterbaseurl= icbaseurl + '/api/v2/canister/${principal.text}/';   

    Future<Uint8List> module_hash() async {
        List<dynamic> paths_values = await state(paths: [['canister', this.principal.bytes, 'module_hash']]);
        return paths_values[0] as Uint8List;
    }
    Future<List<Principal>> controllers() async {
        List<dynamic> paths_values = await state(paths: [['canister', this.principal.bytes, 'controllers']]);
        List<dynamic> controllers_list = cborflutter.cborbytesasadart(paths_values[0]); //?buffer? orr List
        List<Uint8List> controllers_list_uint8list = controllers_list.map((controller_buffer)=>Uint8List.fromList(controller_buffer.toList())).toList();
        List<Principal> controllers_list_principals = controllers_list_uint8list.map((Uint8List controller_bytes)=>Principal.oftheBytes(controller_bytes)).toList();
        return controllers_list_principals;
    }
    // Note that the paths /canisters/<canister_id>/certified_data are not accessible with this method; these paths are only exposed to the canister themselves via the System API (see Certified data).


    Future<List> state({required List<List<dynamic>> paths, http.Client? httpclient, Caller? caller}) async {        
        http.Request systemstatequest = http.Request('post', Uri.parse(canisterbaseurl + 'read_state'));
        systemstatequest.headers['Content-Type'] = 'application/cbor';
        List<List<Uint8List>> pathsbytes = paths.map((path)=>pathasapathbyteslist(path)).toList();
        Map getstatequestbodymap = {
            "content": { 
                "request_type": 'read_state',//(text)
                "paths": pathsbytes,  
                "sender": caller != null ? caller.principal.bytes : Uint8List.fromList([4]), // anonymous in the now(Principal) (:quirement. can be the anonymous principal? find out what is the anonymous principal.-> anonymous-principal is: byte: 0x04/00000100 .)(:self-authentication-id =  SHA-224(public_key) · 0x02 (29 bytes).))
                "nonce": createicquestnonce(),  // (blob)(optional)(used when make same quest soon between but make sure system sees two seperate quests) , 
                "ingress_expiry": createicquestingressexpiry()  // (nat)(:quirement.) (time of message time-out in nanoseconds since 1970)
            }
        };
        if (caller != null) {
            getstatequestbodymap['sender_pubkey'] = caller.public_key_DER;
            Uint8List questId = icdatahash(getstatequestbodymap['content']);
            getstatequestbodymap['sender_sig'] = await caller.authorize_call_questId(questId);
            // if (with the authority-legations) {
            //     ...
            // }
        }
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
            await verifycertificate(certificate); // will throw an exception if certificate is not valid.
            List pathsvalues = paths.map((path)=>lookuppathvalueinaniccertificatetree(certificate['tree'], path)).toList();
            return pathsvalues;
        } else {
            throw Exception(':statesponse_statuscode: ${statesponse.statusCode}, body:\n${statesponse.body}');
        }
    }


    Future<Uint8List> call({required String calltype, required String method_name, Uint8List? put_bytes, Caller? caller}) async {
        if(calltype != 'call' && calltype != 'query') { throw Exception('calltype must be "call" or "query"'); }
        var canistercallquest = http.Request('post', Uri.parse(canisterbaseurl + calltype));
        canistercallquest.headers['Content-Type'] = 'application/cbor';
        Map canistercallquestbodymap = {
            //"sender_pubkey": (blob)(optional)(for the authentication of this quest.) (The public key must authenticate the sender principal when it is set. set pubkey and sender_sig when sender is not the anonymous principal)()
            // "sender_delegation": ([] of the maps) ?find out more. "(array of maps, optional): a chain of delegations, starting with the one signed by sender_pubkey and ending with the one delegating to the key relating to sender_sig."
            //"sender_sig": (blob)(optional)(for the authentication of this quest.)(by the secret_key-authorization: concatenation of the 11 bytes \x0Aic-request (the domain separator) and the 32 byte request id)
            "content": { // (quest-id is of this content-map)
                "request_type": calltype,//(text)
                "canister_id": principal.bytes, //(blob)
                "method_name": method_name,//(text)(:name: canister-method.),
                "arg": put_bytes != null ? put_bytes : Uint8List.fromList([]), 
                "sender": caller != null ? caller.principal.bytes : Uint8List.fromList([4]), // anonymous-principal is: byte: 0x04/00000100 .)(:self-authentication-id =  SHA-224(public_key) · 0x02 (29 bytes).))
                "nonce": createicquestnonce(),  // (blob)(optional)(used when make same quest soon between but make sure system sees two seperate quests) , 
                "ingress_expiry": createicquestingressexpiry()  // (nat)(:quirement.) (:time of the message-time-out in the nanoseconds since the year-~1970)
            }
        };
        Uint8List questId = icdatahash(canistercallquestbodymap['content']); // 32 bytes/256-bits with the sha256.    
        if (caller != null) {
            canistercallquestbodymap['sender_pubkey'] = caller.public_key_DER;
            canistercallquestbodymap['sender_sig'] = await caller.authorize_call_questId(questId);
            // if (with the authority-legations) {
            //     ...
            // }
        }
        canistercallquest.bodyBytes = cborflutter.codeMap(canistercallquestbodymap,withaselfscribecbortag: true);
        
        var httpclient = http.Client();
        BigInt time_check_nanoseconds = BigInt.from(DateTime.now().millisecondsSinceEpoch - Duration(seconds: 30).inMilliseconds) * BigInt.from(1000000); // - 30 seconds brcause of the possible-slippage in the time-syncronization of the nodes. 
        http.Response canistercallsponse = await http.Response.fromStream(await httpclient.send(canistercallquest));
        if (![202,200].contains(canistercallsponse.statusCode)) {
            throw Exception('ic call gave http-sponse-status: ${canistercallsponse.statusCode}, with the body: ${canistercallsponse.body}');
        }
        String? callstatus;
        Uint8List? canistersponse;
        int? reject_code;
        String? reject_message;
        if (calltype == 'call') {
            List pathsvalues = [];
            int c = 0;
            while (!['replied','rejected','done'].contains(callstatus) && c <= 15) {
                c += 1;
                // print(':poll of the system-state.');
                await Future.delayed(Duration(seconds:2));
                pathsvalues = await state( 
                    paths: [
                        ['time'],
                        ['request_status', questId, 'status'], 
                        ['request_status', questId, 'reply'],
                        ['request_status', questId, 'reject_code'],
                        ['request_status', questId, 'reject_message']
                    ], 
                    httpclient: httpclient,
                    caller: caller 
                ); 
                // time-check, not in verify_certificate-function bc that would create new Datetime.now() on each verify and that is slow.
                BigInt certificate_time_nanoseconds = pathsvalues[0] is int ? BigInt.from(pathsvalues[0] as int) : pathsvalues[0] as BigInt;
                if (certificate_time_nanoseconds < time_check_nanoseconds) { throw Exception('IC got back certificate that has an old timestamp: ${(time_check_nanoseconds - certificate_time_nanoseconds) / BigInt.from(1000000000) / 60} minutes ago.'); } // put the timestamp
                
                callstatus = pathsvalues[1];            
            }
            // print(pathsvalues);
            canistersponse = pathsvalues[2];
            reject_code = pathsvalues[3];
            reject_message = pathsvalues[4];
        } 

        else if (calltype == 'query') {
            Map canister_query_sponse_map = cborflutter.cborbytesasadart(canistercallsponse.bodyBytes); // make canister sponse just the reply           
            callstatus = canister_query_sponse_map['status'];
            canistersponse = canister_query_sponse_map.keys.toList().contains('reply') && canister_query_sponse_map['reply'].keys.toList().contains('arg') ? Uint8List.view(canister_query_sponse_map['reply']['arg'].buffer) : null;
            reject_code = canister_query_sponse_map.keys.toList().contains('reject_code') ? canister_query_sponse_map['reject_code'] : null;
            reject_message = canister_query_sponse_map.keys.toList().contains('reject_message') ? canister_query_sponse_map['reject_message'] : null;
        }
        
        if (callstatus == 'replied') {
            // good
        } else if (callstatus=='rejected') {
            throw Exception('Call Reject: reject_code: ${reject_code}: ${system_call_reject_codes[reject_code]}: ${reject_message}.');
        } else if (callstatus=='done') {
            throw Exception('call-status is "done", cant see the canister-reply');
        } else {
            throw Exception('Call error: call-status: ${callstatus}');
        }
        
        httpclient.close();
        return canistersponse!;
    }

}




Map<int, String> system_call_reject_codes = {
    1: 'SYS_FATAL', //, Fatal system error, retry unlikely to be useful.',
    2: 'SYS_TRANSIENT', //, Transient system error, retry might be possible.',
    3: 'DESTINATION_INVALID', //, Invalid destination (e.g. canister/account does not exist)',
    4: 'CANISTER_REJECT', // , Explicit reject by the canister.',
    5: 'CANISTER_ERROR', //, Canister error (e.g., trap, no response)' 
};



List<Uint8List> pathasapathbyteslist(List<dynamic> path) {
    // a path is a list of labels, see the ic-spec. 
    // this function converts string labels to utf8 blobs in a new-list for the convenience. 
    List<dynamic> pathb = [];
    for (int i=0;i<path.length;i++) { 
        pathb.add(path[i]);
        if (pathb[i] is String) {
            pathb[i] = utf8.encode(pathb[i]);    
        }
    }
    return List.castFrom<dynamic, Uint8List>(pathb);
}


Uint8List icdatahash(dynamic datastructure, {bool show=false}) {
    var valueforthehash = <int>[];
    if (datastructure is String) {
        valueforthehash = utf8.encode(datastructure); }
    else if (datastructure is int || datastructure is BigInt) {
        valueforthehash = leb128flutter.encodeUnsigned(datastructure); }
    else if (datastructure is Uint8List) {
        valueforthehash= datastructure; }
    else if (datastructure is List) {
        valueforthehash= datastructure.fold(<int>[], (p,c)=> p + icdatahash(c)); } 
    else if (datastructure is Map) {
        List<List<int>> datafieldshashs = [];
        for (String key in datastructure.keys) {
            List<int> fieldhash = [];
            fieldhash.addAll(sha256.hashSync(ascii.encode(key)).bytes);
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
    return Uint8List.fromList(sha256.hashSync(valueforthehash).bytes);
}
 

// "The recommended textual representation of a request id is a hexadecimal string with lower-case letters prefixed with '0x'. E.g., request id consisting of bytes [00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 0A, 0B, 0C, 0D, 0E, 0F, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 1A, 1B, 1C, 1D, 1E, 1F] should be displayed as 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f. ""
String questidbytesasastring(Uint8List questIdBytes) {
    return '0x' + bytesasahexstring(questIdBytes).toLowerCase();
}

Uint8List questidstringasabytes(String questIdString) {
    if (questIdString.substring(0,2)=='0x') { questIdString = questIdString.substring(2); }
    return hexstringasthebytes(questIdString);
}

Uint8List createicquestnonce() {
    return Uint8List.fromList(DateTime.now().hashCode.toRadixString(2).split('').map(int.parse).toList());
}

dynamic createicquestingressexpiry([Duration? duration]) { //can be a bigint or an int
    if (duration==null) {
        duration = (Duration(minutes: 4));
    }
    BigInt bigint = BigInt.from(DateTime.now().add(duration).millisecondsSinceEpoch) * BigInt.from(1000000); // microsecondsSinceEpoch*1000;
    return bigint.isValidInt ? bigint.toInt() : bigint;
}

Uint8List createdomainseparatorbytes(String domainsepstring) {
    return Uint8List.fromList([domainsepstring.length]..addAll(utf8.encode(domainsepstring)));
}

Uint8List constructicsystemstatetreeroothash(List tree) {
    List<int> v;
    if (tree[0] == 0) {
        assert(tree.length==1); 
        v = sha256.hashSync(createdomainseparatorbytes("ic-hashtree-empty")).bytes;
    } 
    if (tree[0] == 1) {
        assert(tree.length==3);
        v = sha256.hashSync(createdomainseparatorbytes("ic-hashtree-fork") + constructicsystemstatetreeroothash(tree[1]) + constructicsystemstatetreeroothash(tree[2])).bytes;
    }
    else if (tree[0] == 2) {
        assert(tree.length==3);
        v = sha256.hashSync(createdomainseparatorbytes("ic-hashtree-labeled") + tree[1] + constructicsystemstatetreeroothash(tree[2])).bytes;
    }
    else if (tree[0] == 3) {
        assert(tree.length==2); 
        v = sha256.hashSync(createdomainseparatorbytes("ic-hashtree-leaf") + tree[1]).bytes;
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

Future<void> verifycertificate(Map certificate) async {
    Uint8List treeroothash = constructicsystemstatetreeroothash(certificate['tree']);
    Uint8List derKey;
    if (certificate.containsKey('delegation')) {
        Map legation_certificate = cborflutter.cborbytesasadart(Uint8List.fromList(certificate['delegation']['certificate']));
        await verifycertificate(legation_certificate);
        derKey = lookuppathvalueinaniccertificatetree(legation_certificate['tree'], ['subnet', Uint8List.fromList(certificate['delegation']['subnet_id'].toList()), 'public_key']);
    } else {
        derKey = icrootkey; }
    Uint8List blskey = derkeyasablskey(derKey);
    bool certificatevalidity = await bls12381flutter.verify(Uint8List.fromList(certificate['signature'].toList()), Uint8List.fromList(createdomainseparatorbytes('ic-state-root').toList()..addAll(treeroothash)), blskey);
    // print(certificatevalidity);
    if (certificatevalidity == false) { 
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
    if (valuetype==null) { throw Exception(':library: ic_tools is with the void-knowledge of the quest-path.'); }
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
    
dynamic lookuppathvalueinaniccertificatetree(List tree, List<dynamic> path) {
    Uint8List? valuebytes = lookuppathbvaluebinaniccertificatetree(tree, pathasapathbyteslist(path));
    if (valuebytes==null) { return valuebytes; }
    return systemstatepathvaluetypetransform[getstatetreepathvaluetype(path)]!(valuebytes);
}



String icidbytesasatext(Uint8List idblob) {
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

Uint8List icidtextasabytes(String idtext) {
    String idbase32code = idtext.replaceAll('-', '');
    if (idbase32code.length%2!=0) { idbase32code+='='; }
    return Uint8List.fromList(base32.decode(idbase32code).sublist(4));
}







