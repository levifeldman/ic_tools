import 'dart:core';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:archive/archive.dart';
import 'package:base32/base32.dart';
import './cbor/cbor.dart';
import './cbor/simple.dart' as cbor_simple;

import './tools/tools.dart';
import './candid.dart';




/// The gateway url that this agent will use to connect to the network. 
/// 
/// This can be set to localhost in a development environment.
Uri icbaseurl = Uri.parse('https://icp-api.io');

/// The root key of the IC network that is the root of the trust for the verification of the communications.
///
/// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#root-of-trust>
Uint8List icrootkey = Uint8List.fromList([48, 129, 130, 48, 29, 6, 13, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 1, 2, 1, 6, 12, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 2, 1, 3, 97, 0, 129, 76, 14, 110, 199, 31, 171, 88, 59, 8, 189, 129, 55, 60, 37, 92, 60, 55, 27, 46, 132, 134, 60, 152, 164, 241, 224, 139, 116, 35, 93, 20, 251, 93, 156, 12, 213, 70, 217, 104, 95, 145, 58, 12, 11, 44, 197, 52, 21, 131, 191, 75, 67, 146, 228, 103, 219, 150, 214, 91, 155, 180, 203, 113, 113, 18, 248, 71, 46, 13, 90, 77, 20, 80, 95, 253, 116, 132, 176, 18, 145, 9, 28, 95, 135, 185, 136, 131, 70, 63, 152, 9, 26, 11, 170, 174]);


/// Returns various status information about the network.
/// 
/// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#api-status> 
Future<Map> ic_status() async {
    http.Response statussponse = await http.get(icbaseurl.replace(pathSegments: ['api', 'v2', 'status']));
    Object? r = cbor_simple.cbor.decode(statussponse.bodyBytes);
    return r as Map;
}



/// Identifier for a [Canister] or [Caller].
/// 
/// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#principal> 
class Principal extends PrincipalReference {
    /// The bytes of this [Principal] 
    Uint8List get bytes => super.id!.bytes;
    
    /// The textual-representation of this [Principal]
    ///
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#textual-ids>
    final String text;
    
    /// The [text] is the textual-representation of a [Principal].
    Principal(this.text) : super(id: Blob(icidtextasabytes(text)))  /*bytes = icidtextasabytes(text)*/ {  
        
    }
    
    /// The [candid] library uses this constructor when creating a [Principal] in **TypeStance** mode. 
    /// Check the [candid] library main page documentation for more on the **TypeStance** mode of a [CandidType].
    /// 
    /// Calling the [bytes] getter on a Principal created with this constructor will throw an error.
    Principal.typestance() : text = '', super(isTypeStance: true);
    
    static Principal oftheBytes(Uint8List bytes) {
        Principal p = Principal(icidbytesasatext(bytes));
        if (aresamebytes(p.bytes, bytes) != true) {  throw Exception('ic id functions look '); }
        return p;
    }
    static Principal ofthePublicKeyDER(Uint8List pub_key_der) {
        List<int> principal_bytes = [];
        principal_bytes.addAll(sha224.convert(pub_key_der).bytes);
        principal_bytes.add(2);
        return Principal.oftheBytes(Uint8List.fromList(principal_bytes));
    }
    /// Same as [this.text]
    String toString() => '${this.text}';
    
    @override
    bool operator ==(covariant Principal other) => /*other is Principal && */aresamebytes(other.bytes, this.bytes);

    @override
    int get hashCode => this.bytes.first + this.bytes.last;
}



/// Abstract class for a caller that calls the internet-computer.
abstract class Caller {
    
    /// The DER encoded public-key of the [Caller].
    final Uint8List public_key_DER;
        
    Caller({required this.public_key_DER});
    
    /// The function that signs a message using this [Caller]'s private-key. Returns a signature on the message.
    Future<Uint8List> authorize(Uint8List message);

    /// The [Principal] of this [Caller].
    Principal get principal => Principal.ofthePublicKeyDER(this.public_key_DER); 
    
    /// Signs a [request_id](https://internetcomputer.org/docs/current/references/ic-interface-spec/#request-id) for authenticating a request to the network.
    /// 
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#authentication>
    Future<Uint8List> authorize_call_quest_id(Uint8List questId) async {
        List<int> message = []; 
        message.addAll(utf8.encode('\x0Aic-request'));
        message.addAll(questId);
        return await authorize(Uint8List.fromList(message));
    }
    
    /// Signs a [Legation] hash when creating a [Legation].    
    Future<Uint8List> authorize_legation_hash(Uint8List legation_hash) async {
        List<int> message = []; 
        message.addAll(utf8.encode('\x1Aic-request-auth-delegation'));
        message.addAll(legation_hash);
        return await authorize(Uint8List.fromList(message));
    }

    String toString() => 'Caller: ' + this.principal.text;
}

/// A basic implementation of a [Caller] using the [Ed25519](https://ed25519.cr.yp.to/index.html) signature scheme.
class CallerEd25519 extends Caller {
    /// The DER prefix for the DER encoding of the [public_key].
    static Uint8List DER_public_key_start = Uint8List.fromList([
        ...[48, 42],
        ...[48, 5],
        ...[6, 3],
        ...[43, 101, 112],
        ...[3], 
        ...[32 + 1],
        ...[0],
    ]);

    /// The public-key of this caller's key-pair without the DER prefix. 32-bytes. 
    Uint8List get public_key => this.public_key_DER.sublist(CallerEd25519.DER_public_key_start.length);
    /// The private-key of this caller's key-pair. 32-bytes.
    final Uint8List private_key;

    CallerEd25519({required Uint8List public_key, required this.private_key}) : super(public_key_DER: Uint8List.fromList([ ...DER_public_key_start, ...public_key])) {
        if (public_key.length != 32 || private_key.length != 32) {
            throw Exception('Ed25519 Public-key and Private-key both must be 32 bytes');
        }
    }

    static CallerEd25519 new_keys() {
        ed.KeyPair ed_key_pair = ed.generateKey();
        return CallerEd25519(
            public_key  : Uint8List.fromList(ed_key_pair.publicKey.bytes), 
            private_key : ed.seed(ed_key_pair.privateKey)
        );
    }
    
    Future<Uint8List> authorize(Uint8List message) async {
        return ed.sign(ed.newKeyFromSeed(this.private_key), message);
    }

    /// Verifies a message signed by an Ed25519 key-pair.
    static bool verify({ required Uint8List message, required Uint8List signature, required Uint8List pubkey}) {
        return ed.verify(ed.PublicKey(pubkey), message, signature);
    }
}


/// This class is used to delegate an authorization from one public-key to another.
/// The [Internet-Identity](https://identity.ic0.app) canister signs a delegation for a user's session-key letting the session-key-caller call on the user's behalf. 
class Legation {
    /// The DER encoded public-key of the legatee - the receiver of the delegation.
    final Uint8List legatee_public_key_DER;
    /// The expiration for this delegation.
    final BigInt expiration_unix_timestamp_nanoseconds;
    /// An optional list of canister principals to restrict the scope of this delegation.
    final List<Principal>? target_canisters_ids;  
    /// The DER encoded public-key of the legator - the one delegating.
    final Uint8List legator_public_key_DER;
    /// The legator's signature on this [Legation].
    final Uint8List legator_signature; 

    Legation({required this.legatee_public_key_DER, required this.expiration_unix_timestamp_nanoseconds, this.target_canisters_ids, required this.legator_public_key_DER, required this.legator_signature}); 

    /// This function creates a Legation from one [Caller] onto a legatee's public-key.  
    static Future<Legation> create(Caller legator, Uint8List legatee_public_key_DER, BigInt expiration_unix_timestamp_nanoseconds, [List<Principal>? target_canisters_ids]) async {
        Uint8List legator_signature = await legator.authorize_legation_hash(icdatahash(Legation._create_legation_map(legatee_public_key_DER, expiration_unix_timestamp_nanoseconds, target_canisters_ids)));
        return Legation(
            legatee_public_key_DER: legatee_public_key_DER,
            expiration_unix_timestamp_nanoseconds: expiration_unix_timestamp_nanoseconds,
            target_canisters_ids: target_canisters_ids,
            legator_public_key_DER: legator.public_key_DER,
            legator_signature: legator_signature
        );
    }

    static Map _create_legation_map(Uint8List legatee_public_key_DER, BigInt expiration_unix_timestamp_nanoseconds, List<Principal>? target_canisters_ids) {
        return {
            'pubkey': legatee_public_key_DER,
            'expiration': expiration_unix_timestamp_nanoseconds,
            if (target_canisters_ids != null) 'targets': target_canisters_ids.map<Uint8List>((Principal canister_id)=>Uint8List.fromList(canister_id.bytes)).toList()
        };
    }

    Map _as_signed_legation_map() {
        return {
            'delegation' : Legation._create_legation_map(this.legatee_public_key_DER, this.expiration_unix_timestamp_nanoseconds, this.target_canisters_ids),
            'signature': this.legator_signature
        };
    }
    
    String toString() => 'Legation(\n\tlegatee_public_key_DER: ${this.legatee_public_key_DER},\n\texpiration_unix_timestamp_nanoseconds: ${this.expiration_unix_timestamp_nanoseconds},\n\ttarget_canisters_ids: ${this.target_canisters_ids},\n\tlegator_public_key_DER: ${this.legator_public_key_DER},\n\tlegator_signature: ${this.legator_signature}\n)';
}



enum CallType {
    /// An update call or a replicated query call.
    call,
    /// A non-replicated query call.
    query
}


/// The possible system errors when calling a [Canister].
class CallException implements Exception {
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#reject-codes>
    final BigInt reject_code;
    final String reject_message;
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#error-codes>
    final String? error_code;
    CallException({required this.reject_code, required this.reject_message, this.error_code});
    
    String toString() {
        return 'CallException: \nreject_code: ${reject_code}, ${system_call_reject_codes[reject_code]}\nreject_message: ${reject_message}${error_code != null ? '\nerror_code: ${error_code}' : ''}';    
    }
}

/// An implementation specific replica error when a replica processes a call.
class Http4xx5xxCallException implements Exception {
    final int http_status_code;
    final String response_body;
    Http4xx5xxCallException({required this.http_status_code, required this.response_body});
    
    String toString() {
        return 'HTTP status: ${http_status_code}\n${response_body}';
    }
}


/// A Canister on the internet-computer.
class Canister {
    static final List<String> _base_path_segments = ['api', 'v2', 'canister'];
    
    /// The [Principal] of this [Canister].
    final Principal principal; 

    Canister(this.principal);   

    /// Returns the hash of the module this canister is running. If the canister is empty returns null. 
    ///
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#state-tree-canister-information>
    Future<Uint8List?> module_hash() async {
        List<Uint8List?> paths_values = await _state(paths: [_pathbytes(['canister', this.principal.bytes, 'module_hash'])]);
        return paths_values[0];
    }
    /// Returns the controller [Principal]s of this Canister.
    ///
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#state-tree-canister-information>
    Future<List<Principal>> controllers() async {
        List<Uint8List?> paths_values = await _state(paths: [_pathbytes(['canister', this.principal.bytes, 'controllers'])]);
        List<dynamic> controllers_list = cbor_simple.cbor.decode(paths_values[0]!) as List<dynamic>;
        List<Uint8List> controllers_list_uint8list = controllers_list.map((controller_buffer)=>Uint8List.fromList(controller_buffer.toList())).toList();
        List<Principal> controllers_list_principals = controllers_list_uint8list.map((Uint8List controller_bytes)=>Principal.oftheBytes(controller_bytes)).toList();
        return controllers_list_principals;
    }
    /// The content of the canister's [custom-section](https://webassembly.github.io/spec/core/binary/modules.html#custom-section) called `icp:public [name]` or `icp:private [name]`.  
    /// 
    /// If the custom-section is in the `icp:private [name]` namespace, the [Caller] must be one of this [Canister]'s [controllers].
    ///
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#state-tree-canister-information>
    Future<Uint8List?> metadata(String name, {Caller? caller, List<Legation> legations = const []}) async {
        List<Uint8List?> paths_values = await _state(paths: [_pathbytes(['canister', this.principal.bytes, 'metadata', name])], caller:caller, legations:legations);
        return paths_values[0];
    }
    /// The metadata of the standardized `candid:service` custom section which holds a canister's can.did service definition file.
    Future<String?> candid_service_metadata() async {
        return (await this.metadata('candid:service')).nullmap(utf8.decode);
    }


    Future<List<Uint8List?>> _state({required List<List<Uint8List>> paths, http.Client? httpclient, Caller? caller, List<Legation> legations = const [], Principal? fective_canister_id}) async {        
        if (caller==null && legations.isNotEmpty) { throw Exception('legations can only be given with a current-caller that is the final legatee of the legations'); }
        fective_canister_id ??= this.principal;
        http.Request systemstatequest = http.Request('POST', 
            icbaseurl.replace(
                pathSegments: Canister._base_path_segments + [fective_canister_id.text, 'read_state']
            )
        );
        systemstatequest.headers['Content-Type'] = 'application/cbor';
                
        Map getstatequestbodymap = {
            "content": { 
                "request_type": 'read_state',
                "paths": paths,  
                "sender": legations.isNotEmpty ? Principal.ofthePublicKeyDER(legations[0].legator_public_key_DER).bytes : caller != null ? caller.principal.bytes : Uint8List.fromList([4]), 
                "nonce": createicquestnonce(),
                "ingress_expiry": createicquestingressexpiry()
            }
        };
        if (caller != null) {
            if (legations.isNotEmpty) {
                getstatequestbodymap['sender_pubkey'] = legations[0].legator_public_key_DER;
                getstatequestbodymap['sender_delegation'] = legations.map<Map>((Legation legation)=>legation._as_signed_legation_map()).toList();
            } else {
                getstatequestbodymap['sender_pubkey'] = caller.public_key_DER;
            }
            Uint8List questId = icdatahash(getstatequestbodymap['content']);
            getstatequestbodymap['sender_sig'] = await caller.authorize_call_quest_id(questId);
        }
        systemstatequest.bodyBytes = cbor.encode(CborMap(dart_value_as_a_cbor_value(getstatequestbodymap) as CborMap, tags: [CborTag.selfDescribeCbor]));
        bool need_close_httpclient = false;
        if (httpclient==null) {
            httpclient = http.Client();
            need_close_httpclient = true;
        }

        late List<Uint8List?> pathsvalues;
        int i = 4;
        while ( i > 0 ) {
            i -= 1;
            http.Response statesponse = await http.Response.fromStream(await httpclient.send(systemstatequest));
            if (statesponse.statusCode==200) {
                if (need_close_httpclient) { httpclient.close(); }
                Map systemstatesponsemap = cbor_simple.cbor.decode(statesponse.bodyBytes) as Map;
                Map certificate = cbor_simple.cbor.decode(Uint8List.fromList(systemstatesponsemap['certificate'].toList())) as Map;
                await verify_certificate(certificate);
                pathsvalues = paths.map((path)=>lookuppathvalueinaniccertificatetree(certificate['tree'], path)).toList();
                break;
            } else {
                print(':readstatesponse status-code: ${statesponse.statusCode}, body:\n${statesponse.body}');
                if ( i == 1 ) {
                    if (need_close_httpclient) { httpclient.close(); }
                    throw Exception('read_state calls unknown sponse');
                }
                
            } 
        }
        
        return pathsvalues;
    }

    

    /// Call a method on this Canister.
    /// 
    /// [put_bytes] is the argument to this call. When passing candid, this is the candid encoded bytes.
    /// [legations] are a list of possible [Legation]'s for the [caller] to use. If not empty, the [caller] will call as the [Principal] of the first of the [legations]. If empty the [caller] will call as the [caller]'s [Principal].
    /// [timeout_duration] is the amount of time to keep polling for the response. If the call response does not come back within this time, the function will throw an error. 
    Future<Uint8List> call({
        required CallType calltype, 
        required String method_name, 
        Uint8List? put_bytes, 
        Caller? caller, 
        List<Legation> legations = const [], 
        Duration timeout_duration = const Duration(minutes: 5) 
        /*, bool cold_storage_mode = false, Uint8List? call_with_cold_storage_bytes*/
    }) async {
        if (caller==null && legations.isNotEmpty) { throw Exception('legations can only be given with a current-caller that is the final legatee of the legations'); }
        Principal? fective_canister_id; // since fective_canister_id is not a per-canister thing it is a per-call-thing, the fective_canister_id in the url of a call is create on each call 
        if (this.principal.text == 'aaaaa-aa') { 
            try {
                Record put_record = c_backwards(put_bytes!)[0] as Record;
                PrincipalReference principalfer = put_record['canister_id'] as PrincipalReference;
                fective_canister_id = principalfer.principal!;
                // print('fective-cid as a PrincipalReference in a "canister_id" field');
            } catch(e) {
                throw Exception('Calls to the management-canister must contain a Record with a key: "canister_id" and a value of a PrincipalReference.');   
            }
        } else {
            fective_canister_id = this.principal;
        }
        var canistercallquest = http.Request('POST', 
            icbaseurl.replace(
                pathSegments: Canister._base_path_segments + [fective_canister_id.text, calltype.name]
            )
        );
        canistercallquest.headers['content-type'] = 'application/cbor';
        Map canistercallquestbodymap = {
            "content": {
                "request_type": calltype.name,
                "canister_id": this.principal.bytes,
                "method_name": method_name,
                "arg": put_bytes != null ? put_bytes : c_forwards([]), 
                "sender": legations.isNotEmpty ? Principal.ofthePublicKeyDER(legations[0].legator_public_key_DER).bytes : caller != null ? caller.principal.bytes : Uint8List.fromList([4]),
                "nonce": createicquestnonce(),  //(use when make same quest soon between but make sure system sees two seperate quests) 
                "ingress_expiry": createicquestingressexpiry()
            }
        };
        Uint8List questId = icdatahash(canistercallquestbodymap['content']);
        if (caller != null) {
            if (legations.isNotEmpty) {
                canistercallquestbodymap['sender_pubkey'] = legations[0].legator_public_key_DER;
                canistercallquestbodymap['sender_delegation'] = legations.map<Map>((Legation legation)=>legation._as_signed_legation_map()).toList();
            } else {
                canistercallquestbodymap['sender_pubkey'] = caller.public_key_DER;
            }
            canistercallquestbodymap['sender_sig'] = await caller.authorize_call_quest_id(questId);
        }
        Uint8List quest_bytes = Uint8List.fromList(cbor.encode(CborMap(dart_value_as_a_cbor_value(canistercallquestbodymap) as CborMap, tags: [CborTag.selfDescribeCbor])));
        /*
        if (cold_storage_mode == true) {
            return Uint8List.fromList([ ...questId, ...quest_bytes ]);
        }
        */
        canistercallquest.bodyBytes = quest_bytes;
        //print(bytesasahexstring(canistercallquest.bodyBytes));
        var httpclient = http.Client();
        BigInt certificate_time_check_nanoseconds = get_current_time_nanoseconds() - BigInt.from(Duration(seconds: 30).inMilliseconds * 1000000); // - 30 seconds brcause of the time-syncronization of the nodes. 
        http.Response canistercallsponse = await http.Response.fromStream(await httpclient.send(canistercallquest));
        String? callstatus;
        Uint8List? canistersponse;
        BigInt? reject_code;
        String? reject_message;
        String? error_code;
        if (calltype.name == 'call') {
            if (canistercallsponse.statusCode != 202) {
                if (canistercallsponse.statusCode == 200) {
                    Map bodymap = cbor_simple.cbor.decode(canistercallsponse.bodyBytes) as Map;
                    throw CallException(
                        reject_code: bodymap['reject_code'] is int ? BigInt.from(bodymap['reject_code']) : bodymap['reject_code'] as BigInt,
                        reject_message: bodymap['reject_message'] as String,
                        error_code: bodymap['error_code'] as String?
                    );
                } else {
                    throw Http4xx5xxCallException(
                        http_status_code: canistercallsponse.statusCode,
                        response_body: utf8.decode(canistercallsponse.bodyBytes)
                    );
                }
            }
            List<Uint8List?> pathsvalues = [];
            BigInt timeout_duration_check_nanoseconds = get_current_time_nanoseconds() + BigInt.from(timeout_duration.inMilliseconds * 1000000);
            while (!['replied','rejected','done'].contains(callstatus)) {
                
                if (get_current_time_nanoseconds() > timeout_duration_check_nanoseconds ) {
                    throw Exception('timeout duration time limit');
                }
                
                // print(':poll of the system-state.');
                await Future.delayed(Duration(seconds:2));
                pathsvalues = await _state( 
                    paths: [
                        ['time'],
                        ['request_status', questId, 'status'], 
                        ['request_status', questId, 'reply'],
                        ['request_status', questId, 'reject_code'],
                        ['request_status', questId, 'reject_message'],
                        ['request_status', questId, 'error_code'],
                    ].map(_pathbytes).toList(),
                    httpclient: httpclient,
                    caller: caller,
                    legations: legations,
                    fective_canister_id: fective_canister_id 
                ); 
                BigInt certificate_time_nanoseconds = leb128.decodeUnsigned(pathsvalues[0]!);
                if (certificate_time_nanoseconds < certificate_time_check_nanoseconds) { throw Exception('IC got back certificate that has an old timestamp: ${(certificate_time_check_nanoseconds - certificate_time_nanoseconds) / BigInt.from(1000000000) / 60} minutes ago.\ncertificate-timestamp: ${certificate_time_nanoseconds}'); } // // time-check,  
                
                callstatus = pathsvalues[1].nullmap(utf8.decode);
            }
            //print(pathsvalues);
            canistersponse = pathsvalues[2];
            reject_code = pathsvalues[3].nullmap(leb128.decodeUnsigned);
            reject_message = pathsvalues[4].nullmap(utf8.decode);
            error_code = pathsvalues[5].nullmap(utf8.decode);
        }
        else if (calltype.name == 'query') {
            if (canistercallsponse.statusCode != 200) {
                throw Http4xx5xxCallException(
                    http_status_code: canistercallsponse.statusCode,
                    response_body: utf8.decode(canistercallsponse.bodyBytes)
                );
            }
            Map canister_query_sponse_map = cbor_simple.cbor.decode(canistercallsponse.bodyBytes) as Map; 
            callstatus = canister_query_sponse_map['status'];
            canistersponse = canister_query_sponse_map.keys.toList().contains('reply') && canister_query_sponse_map['reply'].keys.toList().contains('arg') ? Uint8List.view(canister_query_sponse_map['reply']['arg'].buffer) : null;
            reject_code = canister_query_sponse_map['reject_code'] is int ? BigInt.from(canister_query_sponse_map['reject_code']) : canister_query_sponse_map['reject_code'] as BigInt;
            reject_message = canister_query_sponse_map['reject_message'];
            error_code = canister_query_sponse_map['error_code'];
        }
        
        httpclient.close();
        
        if (callstatus == 'replied') {
            return canistersponse!;
        } else if (callstatus=='rejected') {
            throw CallException(
                reject_code: reject_code!,
                reject_message: reject_message!,
                error_code: error_code
            );
        } else if (callstatus=='done') {
            throw Exception('call-status is "done", cannot see the canister-reply');
        } else {
            throw Exception('unknown call-status: ${callstatus}');
        }
    }
    
    
    
    @override
    bool operator ==(/*covariant Canister*/ other) => other is Canister && other.principal == this.principal;

    @override
    int get hashCode => this.principal.hashCode;    
    
    

    String toString() => 'Canister: ${this.principal.text}';

}



/// What each [CallException.reject_code] in a [CallException] represents.
///
/// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#reject-codes>
const Map<int, String> system_call_reject_codes = {
    1: 'SYS_FATAL', //, Fatal system error, retry unlikely to be useful.',
    2: 'SYS_TRANSIENT', //, Transient system error, retry might be possible.',
    3: 'DESTINATION_INVALID', //, Invalid destination (e.g. canister/account does not exist)',
    4: 'CANISTER_REJECT', // , Explicit reject by the canister.',
    5: 'CANISTER_ERROR', //, Canister error (e.g., trap, no response)' 
};



List<Uint8List> _pathbytes(List<dynamic> path) {
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


/// Computes the [representation-independent-hash](https://internetcomputer.org/docs/current/references/ic-interface-spec/#hash-of-map) of the data.
Uint8List icdatahash(dynamic datastructure) {
    //print(datastructure);
    //print(datastructure.runtimeType);
    var valueforthehash = <int>[];
    if (datastructure is String) {
        valueforthehash = utf8.encode(datastructure); }
    else if (datastructure is int || datastructure is BigInt) {
        valueforthehash = leb128.encodeUnsigned(datastructure); }
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
        }
        datafieldshashs.sort((a,b) => bytes_as_the_bitstring(a).compareTo(bytes_as_the_bitstring(b)));
        valueforthehash = datafieldshashs.fold(<int>[],(p,c)=>p+c); }
    else {
        throw Exception('icdatahash: check: type of the datastructure: ${datastructure.runtimeType}');    
    }
    return Uint8List.fromList(sha256.convert(valueforthehash).bytes);
}
 

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

BigInt createicquestingressexpiry([Duration? duration]) {
    if (duration==null) {
        duration = Duration(minutes: 4);
    }
    BigInt bigint = BigInt.from(DateTime.now().add(duration).millisecondsSinceEpoch) * BigInt.from(1000000); // microsecondsSinceEpoch*1000;
    return bigint;
}

Uint8List createdomainseparatorbytes(String domainsepstring) {
    return Uint8List.fromList([domainsepstring.length]..addAll(utf8.encode(domainsepstring)));
}

/// Constructs the root hash of a [HashTree](https://internetcomputer.org/docs/current/references/ic-interface-spec/#certificate) in a certificate returned by the network.
/// Useful when verifying a canister's [certified_data](https://internetcomputer.org/docs/current/references/ic-interface-spec/#system-api-certified-data).
/// 
/// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#certificate>
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


/// Verifies that a [certificate](https://internetcomputer.org/docs/current/references/ic-interface-spec/#certificate) is by the [icrootkey]. Throws an Exception if the certificate is invalid.
Future<void> verify_certificate(Map certificate) async {
    Uint8List treeroothash = constructicsystemstatetreeroothash(certificate['tree']);
    Uint8List derKey;
    if (certificate.containsKey('delegation')) {
        Map legation_certificate = cbor_simple.cbor.decode(Uint8List.fromList(certificate['delegation']['certificate'])) as Map;
        await verify_certificate(legation_certificate);
        derKey = lookuppathvalueinaniccertificatetree(legation_certificate['tree'], _pathbytes(['subnet', Uint8List.fromList(certificate['delegation']['subnet_id'].toList()), 'public_key']))!;
    } else {
        derKey = icrootkey; }
    Uint8List blskey = derkeyasablskey(derKey);
    bool certificatevalidity = await bls12381.verify(Uint8List.fromList(certificate['signature'].toList()), Uint8List.fromList(createdomainseparatorbytes('ic-state-root').toList()..addAll(treeroothash)), blskey);
    // print(certificatevalidity);
    if (certificatevalidity == false) { 
        throw Exception(':CERTIFICATE IS: VOID.'); 
    }
}



List flattentreeforks(List tree) {
    if (tree[0]==0) {
        return [];
    }
    else if (tree[0]==1) {
        return flattentreeforks(tree[1]) + flattentreeforks(tree[2]);
    }
    return [tree];
}


/// Looks up a path value in a certificate tree returned by the network.
/// if path doesn't exist, returns null.
/// Useful when verifying a canister's [certified_data](https://internetcomputer.org/docs/current/references/ic-interface-spec/#system-api-certified-data).
///
/// [tree] is a [HashTree](https://internetcomputer.org/docs/current/references/ic-interface-spec/#certificate).    
/// [path] is a path in the [HashTree](https://internetcomputer.org/docs/current/references/ic-interface-spec/#certificate) specified as a list of path-segments. Each path-segment is some bytes.
/// ```dart
/// path: [utf8.encode('canister'), common.SYSTEM_CANISTERS.cycles_mint.principal.bytes, utf8.encode('certified_data')]) 
/// ```
/// ```dart
/// path: [utf8.encode('time')] 
/// ```
Uint8List? lookuppathvalueinaniccertificatetree(
    List tree, 
    List<Uint8List> path
) {
    if (path.length > 0) {
        List flattrees = flattentreeforks(tree);
        for (List flattree in flattrees) {
            if (flattree[0]==2) {
                if (aresamebytes(flattree[1], path[0]) == true) {
                    return lookuppathvalueinaniccertificatetree(flattree[2], path.sublist(1));
                }
            }
        }
    }
    else {
        if (tree[0]==3) {
            return Uint8List.fromList(tree[1]);
        }
    }
    return null;
}







String icidbytesasatext(Uint8List idblob) {
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
    List<int> base32_decode = base32.decode(idbase32code);
    List<int> crc32checksum = base32_decode.sublist(0,4);
    List<int> principal_bytes = base32_decode.sublist(4);
    Crc32 crc32 = Crc32();
    crc32.add(principal_bytes);
    List<int> calculate_crc32 = crc32.close();
    if (aresamebytes(calculate_crc32, crc32checksum) == false) {
        throw Exception('crc32 checksum is invalid.');
    }
    return Uint8List.fromList(principal_bytes);
}


CborValue dart_value_as_a_cbor_value(dynamic dart_value) {
    if (dart_value is Map) {
        return CborMap((dart_value).map<CborValue, CborValue>((k,v)=>MapEntry(dart_value_as_a_cbor_value(k), dart_value_as_a_cbor_value(v))));
    }
    else if (dart_value is String) {
        return CborString(dart_value);
    }
    else if (dart_value is BigInt) {
        return CborInt(dart_value);
    }
    else if (dart_value is int) {
        return CborInt(BigInt.from(dart_value));
    }
    else if (dart_value is Uint8List) {
        return CborBytes(dart_value);
    }
    else if (dart_value is List) {
        return CborList((dart_value).map<CborValue>((item)=>dart_value_as_a_cbor_value(item)).toList());
    }
    else {
        throw Exception('unknown dart value type: ${dart_value.runtimeType}');
    }
}




