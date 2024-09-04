import 'dart:core';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:archive/archive.dart';
import 'package:base32/base32.dart';
import './cbor/cbor.dart';
import './cbor/simple.dart' as cbor_simple;

import './tools/tools.dart';
import './candid.dart';

export './candid.dart' show Principal;


/// The gateway url that this agent will use to connect to the network. 
/// 
/// This can be set to localhost in a development environment.
Uri ic_base_url = Uri.parse('https://icp-api.io');

/// The root key of the IC network that is the root of the trust for the verification of the communications.
///
/// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#root-of-trust>
Uint8List ic_root_key = Uint8List.fromList([48, 129, 130, 48, 29, 6, 13, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 1, 2, 1, 6, 12, 43, 6, 1, 4, 1, 130, 220, 124, 5, 3, 2, 1, 3, 97, 0, 129, 76, 14, 110, 199, 31, 171, 88, 59, 8, 189, 129, 55, 60, 37, 92, 60, 55, 27, 46, 132, 134, 60, 152, 164, 241, 224, 139, 116, 35, 93, 20, 251, 93, 156, 12, 213, 70, 217, 104, 95, 145, 58, 12, 11, 44, 197, 52, 21, 131, 191, 75, 67, 146, 228, 103, 219, 150, 214, 91, 155, 180, 203, 113, 113, 18, 248, 71, 46, 13, 90, 77, 20, 80, 95, 253, 116, 132, 176, 18, 145, 9, 28, 95, 135, 185, 136, 131, 70, 63, 152, 9, 26, 11, 170, 174]);


/// Returns various status information about the network.
/// 
/// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#api-status> 
Future<Map> ic_status() async {
    http.Response statussponse = await http.get(ic_base_url.replace(pathSegments: ['api', 'v2', 'status']));
    Object? r = cbor_simple.cbor.decode(statussponse.bodyBytes);
    return r as Map;
}

/// For use in a local environment.
/// This function fetches and sets the [ic_root_key] from the local replica. 
///
/// The [ic_base_url] host must be set to either `127.0.0.1` or `localhost`, otherwise this function throws an error. 
Future<void> fetch_root_key() async {
    if (['localhost', '127.0.0.1'].contains(ic_base_url.host)) {
        Map m = await ic_status();
        ic_root_key = Uint8List.fromList(m['root_key']);
    } else {
        throw Exception('fetch_root_key can be called when the ic_base_url.host is set to 127.0.0.1 or localhost.');
    }
}



/// A key-pair that can sign messages.
abstract class Keys {
    
    /// The DER encoded public-key of these [Keys].
    final Uint8List public_key_DER;
    
    Keys({required this.public_key_DER});      
    
    /// Signs a message using the private-key of these Keys. Returns a signature on the message.
    Future<Uint8List> authorize(Uint8List message);
    
}




Future<Uint8List> keys_authorize_call_quest_id(Keys keys, Uint8List quest_id) async {
    List<int> message = []; 
    message.addAll(utf8.encode('\x0Aic-request'));
    message.addAll(quest_id);
    return await keys.authorize(Uint8List.fromList(message));
}
    
Future<Uint8List> keys_authorize_legation_hash(Keys keys, Uint8List legation_hash) async {
    List<int> message = []; 
    message.addAll(utf8.encode('\x1Aic-request-auth-delegation'));
    message.addAll(legation_hash);
    return await keys.authorize(Uint8List.fromList(message));
}



/// [Keys] using the [Ed25519](https://ed25519.cr.yp.to/index.html) signature scheme.
class Ed25519Keys extends Keys {
    /// The DER prefix for the DER encoding of the ed25519 [public_key].
    static Uint8List DER_public_key_start = Uint8List.fromList([48, 42, 48, 5, 6, 3, 43, 101, 112, 3, 33, 0]);

    /// The ed25519 public-key of these keys without the DER prefix. 
    Uint8List get public_key => this.public_key_DER.sublist(Ed25519Keys.DER_public_key_start.length);
    /// The ed25519 private-key of these keys.
    final Uint8List private_key;

    Ed25519Keys({required Uint8List public_key, required this.private_key}) 
    : super(public_key_DER: Uint8List.fromList([ ...DER_public_key_start, ...public_key])) {
        if (public_key.length != 32 || private_key.length != 32) {
            throw Exception('Ed25519 Public-key and Private-key both must be 32 bytes');
        }
    }
    /// Generates a new pair of ed25519 keys.
    static Future<Ed25519Keys> new_keys() async {
        cryptography.Ed25519 ed = cryptography.Ed25519(); 
        cryptography.SimpleKeyPairData keypair = await (await ed.newKeyPair()).extract();
        Uint8List private_key = Uint8List.fromList(await keypair.extractPrivateKeyBytes());
        Uint8List public_key = Uint8List.fromList((await keypair.extractPublicKey()).bytes);
        return Ed25519Keys(
            public_key  : public_key, 
            private_key : private_key
        );
    }
    
    Future<Uint8List> authorize(Uint8List message) async {
        cryptography.Ed25519 ed = cryptography.Ed25519(); 
        return Uint8List.fromList((await ed.sign(
            message,
            keyPair: cryptography.SimpleKeyPairData(
                this.private_key, 
                publicKey: cryptography.SimplePublicKey(
                    this.public_key,
                    type: cryptography.KeyPairType.ed25519,
                ),
                type: cryptography.KeyPairType.ed25519,
            ) 
        )).bytes);
    }

    /// Verifies a message signed by an Ed25519 key-pair.
    static Future<bool> verify({ required Uint8List message, required Uint8List signature, required Uint8List pubkey}) async {
        cryptography.Ed25519 ed = cryptography.Ed25519(); 
        return await ed.verify(
            message,
            signature: cryptography.Signature(
                signature,
                publicKey: cryptography.SimplePublicKey(
                    pubkey,
                    type: cryptography.KeyPairType.ed25519
                )
            )
        );
    }
}


/// This class is used to delegate an authorization from one public-key to another.
/// The [Internet-Identity](https://identity.ic0.app) canister signs a delegation for a user's session-key letting the session-key call on the user's behalf. 
class Legation {
    /// The DER encoded public-key of the legatee - the receiver of the delegation.
    final Uint8List legatee_public_key_DER;
    /// The expiration for this delegation.
    final BigInt expiration_timestamp_nanoseconds;
    /// An optional list of canister principals to restrict the scope of this delegation.
    final List<Principal>? target_canisters_ids;  
    /// The DER encoded public-key of the legator - the one delegating.
    final Uint8List legator_public_key_DER;
    /// The legator's signature on this [Legation].
    final Uint8List legator_signature; 

    Legation({required this.legatee_public_key_DER, required this.expiration_timestamp_nanoseconds, this.target_canisters_ids, required this.legator_public_key_DER, required this.legator_signature}); 

    /// This function creates a [Legation] by the [legator_keys] onto the [legatee_public_key_DER].  
    static Future<Legation> create(Keys legator_keys, Uint8List legatee_public_key_DER, BigInt expiration_timestamp_nanoseconds, [List<Principal>? target_canisters_ids]) async {
        Uint8List legator_signature = await keys_authorize_legation_hash(legator_keys, ic_data_hash(Legation._create_legation_map(legatee_public_key_DER, expiration_timestamp_nanoseconds, target_canisters_ids)));
        return Legation(
            legatee_public_key_DER: legatee_public_key_DER,
            expiration_timestamp_nanoseconds: expiration_timestamp_nanoseconds,
            target_canisters_ids: target_canisters_ids,
            legator_public_key_DER: legator_keys.public_key_DER,
            legator_signature: legator_signature
        );
    }

    static Map _create_legation_map(Uint8List legatee_public_key_DER, BigInt expiration_timestamp_nanoseconds, List<Principal>? target_canisters_ids) {
        return {
            'pubkey': legatee_public_key_DER,
            'expiration': expiration_timestamp_nanoseconds,
            if (target_canisters_ids != null) 'targets': target_canisters_ids.map<Uint8List>((Principal canister_id)=>Uint8List.fromList(canister_id.bytes)).toList()
        };
    }

    Map _as_signed_legation_map() {
        return {
            'delegation' : Legation._create_legation_map(this.legatee_public_key_DER, this.expiration_timestamp_nanoseconds, this.target_canisters_ids),
            'signature': this.legator_signature
        };
    }
    
    String toString() => 'Legation(\n\tlegatee_public_key_DER: ${this.legatee_public_key_DER},\n\texpiration_timestamp_nanoseconds: ${this.expiration_timestamp_nanoseconds},\n\ttarget_canisters_ids: ${this.target_canisters_ids},\n\tlegator_public_key_DER: ${this.legator_public_key_DER},\n\tlegator_signature: ${this.legator_signature}\n)';
}



extension LegationsMethods on List<Legation> {
    /// The expiration of the user's delegations. Returns `null` if the list is empty.
    BigInt? get expiration_timestamp_nanoseconds => this.isEmpty ? null : this.map((l)=>l.expiration_timestamp_nanoseconds).toList().reduce((current, next) => current <= next ? current : next);
    /// Whether the user's delegations are expired. Returns `false` if the list is empty.
    bool is_expired() {
        return this.isEmpty ? false : get_current_time_nanoseconds() >= expiration_timestamp_nanoseconds!;
    }
    /// Returns the remaining [Duration] of this user's delegation. Returns [Duration.zero] if the delegation is expired;
    /// Returns `null` if the list empty. 
    Duration? duration_to_expiration() {
        if (this.isEmpty) {
            return null;
        }
        BigInt duration_remaining = expiration_timestamp_nanoseconds! - get_current_time_nanoseconds();
        if (duration_remaining <= BigInt.from(0)) {
            return Duration.zero;
        }
        return Duration(milliseconds: milliseconds_of_the_nanos(duration_remaining).toInt());         
    }
        
}

class Caller {
    final Keys keys;
    final List<Legation> legations;
    
    final Uint8List public_key_DER;
    late final Principal principal;
    
    Caller({required this.keys, this.legations = const []}) 
    : public_key_DER = legations.length == 0 ? keys.public_key_DER : legations.first.legator_public_key_DER {
        principal = Principal.of_the_public_key_DER(public_key_DER);
    }
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
        return 'CallException: \nreject_code: ${reject_code}, ${system_call_reject_codes[reject_code.toInt()]}\nreject_message: ${reject_message}${error_code != null ? '\nerror_code: ${error_code}' : ''}';    
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
    
    /// The [Principal] of this [Canister].
    final Principal principal; 

    Canister(this.principal);   

    /// Returns the hash of the module this canister is running. If the canister is empty returns null. 
    ///
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#state-tree-canister-information>
    Future<Uint8List?> module_hash() async {
        List<Uint8List?> paths_values = await read_state_return_paths_values(
            subnet_or_canister: SubnetOrCanister.canister,    
            url_id: this.principal, 
            paths: [pathbytes(['canister', this.principal.bytes, 'module_hash'])]
        );
        return paths_values[0];
    }
    /// Returns the controller [Principal]s of this Canister.
    ///
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#state-tree-canister-information>
    Future<List<Principal>> controllers() async {
        List<Uint8List?> paths_values = await read_state_return_paths_values(
            subnet_or_canister: SubnetOrCanister.canister,    
            url_id: this.principal, 
            paths: [pathbytes(['canister', this.principal.bytes, 'controllers'])]
        );
        List<dynamic> controllers_list = cbor_simple.cbor.decode(paths_values[0]!) as List<dynamic>;
        List<Uint8List> controllers_list_uint8list = controllers_list.map((controller_buffer)=>Uint8List.fromList(controller_buffer.toList())).toList();
        List<Principal> controllers_list_principals = controllers_list_uint8list.map((Uint8List controller_bytes)=>Principal.bytes(controller_bytes)).toList();
        return controllers_list_principals;
    }
    /// The content of the canister's [custom-section](https://webassembly.github.io/spec/core/binary/modules.html#custom-section) called `icp:public [name]` or `icp:private [name]`.  
    /// 
    /// If the custom-section is in the `icp:private [name]` namespace, the [Caller] must be one of this [Canister]'s [controllers].
    ///
    /// <https://internetcomputer.org/docs/current/references/ic-interface-spec/#state-tree-canister-information>
    Future<Uint8List?> metadata(String name, {Caller? caller}) async {
        List<Uint8List?> paths_values = await read_state_return_paths_values(
            subnet_or_canister: SubnetOrCanister.canister, 
            url_id: this.principal, 
            paths: [pathbytes(['canister', this.principal.bytes, 'metadata', name])], 
            caller:caller
        );
        return paths_values[0];
    }
    /// The metadata of the standardized `candid:service` custom section which holds a canister's can.did service definition file.
    Future<String?> candid_service_metadata({Caller? caller}) async {
        return (await this.metadata('candid:service', caller:caller)).nullmap(utf8.decode);
    }

    /// Call a method on this Canister.
    /// 
    /// [put_bytes] is the argument to this call. When passing candid, this is the candid encoded bytes.
    /// [timeout_duration] is the amount of time to keep polling for the response. If the call response does not come back within this time, the function will throw an error. 
    Future<Uint8List> call({
        required CallType calltype, 
        required String method_name, 
        Uint8List? put_bytes, 
        Caller? caller, 
        Duration timeout_duration = const Duration(minutes: 5),
        /*, bool cold_storage_mode = false, Uint8List? call_with_cold_storage_bytes*/
    }) async {
        Principal? fective_canister_id; // since fective_canister_id is not a per-canister thing it is a per-call-thing, the fective_canister_id in the url of a call is create on each call 
        if (this.principal.text == 'aaaaa-aa') { 
            if (method_name == 'provisional_create_canister_with_cycles') {
                fective_canister_id = Principal.text('aaaaa-aa');
            } else {
                try {
                    Record put_record = c_backwards(put_bytes!)[0] as Record;
                    fective_canister_id = put_record['canister_id'] as Principal;
                } catch(e) {
                    throw Exception('Calls to the management-canister must contain a Record with a key: "canister_id" and a value of a Principal.');   
                }
            }
        } else {
            fective_canister_id = this.principal;
        }
        var canistercallquest = http.Request('POST', 
            ic_base_url.replace(
                pathSegments: ['api', 'v2', 'canister', fective_canister_id.text, calltype.name]
            )
        );
        canistercallquest.headers['content-type'] = 'application/cbor';
        Map canistercallquestbodymap = {
            "content": {
                "request_type": calltype.name,
                "canister_id": this.principal.bytes,
                "method_name": method_name,
                "arg": put_bytes != null ? put_bytes : c_forwards([]), 
                "sender": caller != null ? caller.principal.bytes : Uint8List.fromList([4]),
                "nonce": createicquestnonce(),  //(use when make same quest soon between but make sure system sees two seperate quests) 
                "ingress_expiry": createicquestingressexpiry()
            }
        };
        Uint8List questId = ic_data_hash(canistercallquestbodymap['content']);
        if (caller != null) {
            canistercallquestbodymap['sender_pubkey'] = caller.public_key_DER;
            if (caller.legations.length > 0) {
                canistercallquestbodymap['sender_delegation'] = caller.legations.map<Map>((Legation legation)=>legation._as_signed_legation_map()).toList();
            }
            canistercallquestbodymap['sender_sig'] = await keys_authorize_call_quest_id(caller.keys, questId);
        }
        Uint8List quest_bytes = Uint8List.fromList(cbor.encode(CborMap(dart_value_as_a_cbor_value(canistercallquestbodymap) as CborMap, tags: [CborTag.selfDescribeCbor])));
        
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
                await Future.delayed(const Duration(seconds: 1));
                pathsvalues = await read_state_return_paths_values( 
                    subnet_or_canister: SubnetOrCanister.canister,
                    url_id: fective_canister_id, 
                    paths: [
                        ['time'],
                        ['request_status', questId, 'status'], 
                        ['request_status', questId, 'reply'],
                        ['request_status', questId, 'reject_code'],
                        ['request_status', questId, 'reject_message'],
                        ['request_status', questId, 'error_code'],
                    ].map(pathbytes).toList(),
                    httpclient: httpclient,
                    caller: caller,
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
            if (ic_base_url.host != '127.0.0.1' && ic_base_url.host != 'localhost') {
                await verify_query_signatures(fective_canister_id, questId, canister_query_sponse_map);
            }
            callstatus = canister_query_sponse_map['status'];
            if (callstatus == 'replied') { 
                canistersponse = Uint8List.view(canister_query_sponse_map['reply']['arg'].buffer);
            } else if (callstatus == 'rejected') {
                reject_code = canister_query_sponse_map['reject_code'] is int ? BigInt.from(canister_query_sponse_map['reject_code']) : canister_query_sponse_map['reject_code'] as BigInt;
                reject_message = canister_query_sponse_map['reject_message'];
                error_code = canister_query_sponse_map['error_code'];
            }
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

// --- read_state ---
enum SubnetOrCanister {
    subnet,
    canister,
}

Future<List<Uint8List?>> read_state_return_paths_values({required List<List<Uint8List>> paths, http.Client? httpclient, Caller? caller, required SubnetOrCanister subnet_or_canister, required Principal url_id}) async {        
    var certificate_tree = await read_state_return_certificate_tree(paths: paths, httpclient: httpclient, caller: caller, subnet_or_canister: subnet_or_canister, url_id: url_id);   
    return paths.map((path)=>lookup_path_value_in_an_ic_certificate_tree(certificate_tree, path)).toList();
}

Future<List> read_state_return_certificate_tree({required List<List<Uint8List>> paths, http.Client? httpclient, Caller? caller, required SubnetOrCanister subnet_or_canister, required Principal url_id}) async {        
    http.Request systemstatequest = http.Request('POST', 
        ic_base_url.replace(
            pathSegments: ['api', 'v2', subnet_or_canister.name, url_id.text, 'read_state']
        )
    );
    systemstatequest.headers['Content-Type'] = 'application/cbor';
            
    Map getstatequestbodymap = {
        "content": { 
            "request_type": 'read_state',
            "paths": paths,  
            "sender": caller != null ? caller.principal.bytes : Uint8List.fromList([4]), 
            "nonce": createicquestnonce(),
            "ingress_expiry": createicquestingressexpiry()
        }
    };
    if (caller != null) {
        getstatequestbodymap['sender_pubkey'] = caller.public_key_DER;
        if (caller.legations.length > 0) {
            getstatequestbodymap['sender_delegation'] = caller.legations.map<Map>((Legation legation)=>legation._as_signed_legation_map()).toList();
        }
        Uint8List questId = ic_data_hash(getstatequestbodymap['content']);
        getstatequestbodymap['sender_sig'] = await keys_authorize_call_quest_id(caller.keys, questId);
    }
    systemstatequest.bodyBytes = cbor.encode(CborMap(dart_value_as_a_cbor_value(getstatequestbodymap) as CborMap, tags: [CborTag.selfDescribeCbor]));
    bool need_close_httpclient = false;
    if (httpclient==null) {
        httpclient = http.Client();
        need_close_httpclient = true;
    }

    int i = 4;
    while ( i > 0 ) {
        i -= 1;
        http.Response statesponse = await http.Response.fromStream(await httpclient.send(systemstatequest));
        if (statesponse.statusCode==200) {
            Map systemstatesponsemap = cbor_simple.cbor.decode(statesponse.bodyBytes) as Map;
            Map certificate = cbor_simple.cbor.decode(Uint8List.fromList(systemstatesponsemap['certificate'].toList())) as Map;
            try {
                await verify_certificate(certificate, subnet_or_canister, url_id);
            } catch(e) {
                print('Error verifying certificate: ${e}. Will maybe try again.');
                continue;
            }
            if (need_close_httpclient) { httpclient.close(); }
            return certificate['tree'];
        } else {
            print(':readstatesponse status-code: ${statesponse.statusCode}, body:\n${statesponse.body}');
        } 
    }    
    if (need_close_httpclient) { httpclient.close(); }
    throw Exception('read_state calls unknown sponse');
}







// --- query signatures ---

final Principal root_subnet_id = Principal.text('tdb26-jop6k-aogll-7ltgs-eruif-6kk7m-qpktf-gdiqx-mxtrf-vb5e6-eqe');

class SubnetData {
    final Principal subnet_id;    
    final Uint8List public_key_DER;
    final List<(Principal, Principal)> canister_ranges;
    final List<NodeData> nodes;
    
    SubnetData({
        required this.subnet_id,
        required this.public_key_DER,
        required this.canister_ranges,
        required this.nodes,
    });
}

class NodeData {
    final Principal node_id;
    final Uint8List public_key_DER;
    NodeData({
        required this.node_id,
        required this.public_key_DER,
    });
}

extension IsCanisterWithinRanges on List<(Principal, Principal)> {
    bool is_canister_here(Principal canister_id) {
        String canister_id_bitstring = bytes_as_the_bitstring(canister_id.bytes);
        for (var (Principal start, Principal end) in this) {
            String start_bitstring = bytes_as_the_bitstring(start.bytes);
            String end_bitstring = bytes_as_the_bitstring(end.bytes);
            if (start_bitstring.compareTo(canister_id_bitstring) <= 0
            && end_bitstring.compareTo(canister_id_bitstring) >= 0) {
                return true;    
            }
        }
        return false;
    }
}

List<(Principal, Principal)> decode_canister_ranges(Uint8List canister_ranges_raw) {
    return (cbor_simple.cbor.decode(canister_ranges_raw) as List) 
        .map((range)=>(Principal.bytes(Uint8List.fromList(range[0])), Principal.bytes(Uint8List.fromList(range[1]))))
        .toList();
}

Map<Principal, SubnetData> subnets_cache = {};

// will use a cache // will throw if not found
Future<SubnetData> get_subnet_data_for_canister(Principal canister_id) async {
    // check cache
    if (subnets_cache.isEmpty) {
        // call root subnet and get the ranges of every subnet
        List certificate_tree = await read_state_return_certificate_tree(
            subnet_or_canister: SubnetOrCanister.subnet,      
            url_id: root_subnet_id,
            paths: [
                ['time'],
                ['subnet'],
            ].map(pathbytes).toList(),
        );
        check_time_is_less_than_5_minutes_old_in_certificate_tree(certificate_tree);
        
        List<Principal> subnet_ids = lookup_path_branches_in_an_ic_certificate_tree(certificate_tree, [utf8.encode('subnet')])  
        .map(Principal.bytes).toList();
        
        for (Principal subnet_id in subnet_ids) {
            // the subnets besidses the root subnet don't contain the data for their nodes but they do for the canister-ranges.
            subnets_cache[subnet_id] = parse_certificate_tree_for_subnet_data(certificate_tree, subnet_id);
        }
    }
    
    Principal? read_state_of_subnet_id;
    
    for (SubnetData subnet_data in subnets_cache.values) {
        if (subnet_data.canister_ranges.is_canister_here(canister_id)) {
            if (subnet_data.nodes.isNotEmpty) {
                return subnet_data;
            } else {
                read_state_of_subnet_id = subnet_data.subnet_id;
                break;
            }
        }
    }
    
    if (read_state_of_subnet_id == null) {
        throw Exception('Error verifying query signature. Canister not found within subnets\' ranges.');
    }
    
    List certificate_tree = await read_state_return_certificate_tree(
        subnet_or_canister: SubnetOrCanister.subnet,      
        url_id: read_state_of_subnet_id,
        paths: [
            ['time'],
            ['subnet'],
        ].map(pathbytes).toList(),
    );
    check_time_is_less_than_5_minutes_old_in_certificate_tree(certificate_tree);
        
    SubnetData subnet_data = parse_certificate_tree_for_subnet_data(certificate_tree, read_state_of_subnet_id);
    subnets_cache[read_state_of_subnet_id] = subnet_data;
    return subnet_data;
}

// helper
SubnetData parse_certificate_tree_for_subnet_data(List certificate_tree, Principal subnet_id) {
    return SubnetData(
        subnet_id: subnet_id,
        public_key_DER: lookup_path_value_in_an_ic_certificate_tree(certificate_tree, pathbytes(['subnet', subnet_id.bytes, 'public_key']))!,    
        canister_ranges: decode_canister_ranges(lookup_path_value_in_an_ic_certificate_tree(certificate_tree, pathbytes(['subnet', subnet_id.bytes, 'canister_ranges']))!),
        nodes: lookup_path_branches_in_an_ic_certificate_tree(
            certificate_tree, 
            pathbytes(['subnet', subnet_id.bytes, 'node']),
        )
        .map(Principal.bytes)
        .map((node_id){
            return NodeData(
                node_id: node_id,    
                public_key_DER: lookup_path_value_in_an_ic_certificate_tree(certificate_tree, pathbytes(['subnet', subnet_id.bytes, 'node', node_id.bytes, 'public_key']))!,
            );
        }).toList(),
    );
}

// helper
// will throw if more than 5 minutes old.
check_time_is_less_than_5_minutes_old_in_certificate_tree(List certificate_tree) {
    BigInt time = leb128.decodeUnsigned(lookup_path_value_in_an_ic_certificate_tree(certificate_tree, pathbytes(['time']))!);   
    if (time < get_current_time_nanoseconds() - BigInt.from(NANOS_IN_A_SECOND * 60 * 5)) {
        throw Exception('Timestamp too old on the certificate.');
    }
}


// will throw if signature is invalid
Future<void> verify_query_signatures(Principal fective_canister_id, Uint8List quest_id, Map sponse) async {
    if ((sponse['signatures'] as List).isEmpty) {
        throw Exception('There must be at least 1 query response signature.');
    }
    for (Map node_signature in sponse['signatures'] as List) {
        BigInt timestamp = node_signature['timestamp'] is BigInt ? node_signature['timestamp'] as BigInt : BigInt.from(node_signature['timestamp'] as int);
        Uint8List signature = Uint8List.fromList(node_signature['signature']);
        Principal node_id = Principal.bytes(Uint8List.fromList(node_signature['identity']));
        
        if (timestamp < get_current_time_nanoseconds() - BigInt.from(NANOS_IN_A_SECOND * 60 * 5)) {
            throw Exception('Node signature timestamp too old.');
        }
        
        Uint8List? node_public_key_DER;
        for (NodeData node_data in (await get_subnet_data_for_canister(fective_canister_id)).nodes) {
            if (node_data.node_id == node_id) {
                node_public_key_DER = node_data.public_key_DER;
                break;
            }
        }
        if (node_public_key_DER == null) {
            throw Exception('Error verifying query signature. Did not find node-signature-identity in the system-state-tree.');
        }
        
        String callstatus = sponse['status']!;
        Map m = {
            'status': callstatus,
            'timestamp': timestamp,
            'request_id': quest_id,
        };
        if (callstatus == 'replied') { 
            m['reply'] = { 'arg': Uint8List.view(sponse['reply']['arg'].buffer) };
        } else if (callstatus == 'rejected') {
            m['reject_code'] = sponse['reject_code'] is int ? BigInt.from(sponse['reject_code']) : sponse['reject_code'] as BigInt;  
            m['reject_message'] = sponse['reject_message'] as String;
            m['error_code'] = sponse['error_code'] as String;
        }
                
        Uint8List message = Uint8List.fromList([
            ...utf8.encode('\x0Bic-response'),
            ...ic_data_hash(m)
        ]);
        
        bool verify_result = await Ed25519Keys.verify(
            message: message,
            signature: signature,
            pubkey: node_public_key_DER.sublist(Ed25519Keys.DER_public_key_start.length),
        );         
        if (verify_result == false) {
            throw Exception('Node signature verification failed.');
        }
    }
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


/// A path is a list of labels. This function converts string labels to utf8 blobs in a new list for the convenience. 
List<Uint8List> pathbytes(List<dynamic> path) {
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
Uint8List ic_data_hash(dynamic datastructure) {
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
        valueforthehash= datastructure.fold(<int>[], (p,c)=> p + ic_data_hash(c)); }
    else if (datastructure is Map) {
        List<List<int>> datafieldshashs = [];
        for (String key in datastructure.keys) {
            List<int> fieldhash = [];
            fieldhash.addAll(sha256.convert(ascii.encode(key)).bytes);
            fieldhash.addAll(ic_data_hash(datastructure[key]));
            datafieldshashs.add(fieldhash);
        }
        datafieldshashs.sort((a,b) => bytes_as_the_bitstring(a).compareTo(bytes_as_the_bitstring(b)));
        valueforthehash = datafieldshashs.fold(<int>[],(p,c)=>p+c); }
    else {
        throw Exception('ic_data_hash: check: type of the datastructure: ${datastructure.runtimeType}');    
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
Uint8List construct_ic_system_state_tree_root_hash(List tree) {
    List<int> v;
    if (tree[0] == 0) {
        assert(tree.length==1); 
        v = sha256.convert(createdomainseparatorbytes("ic-hashtree-empty")).bytes;
    } 
    if (tree[0] == 1) {
        assert(tree.length==3);
        v = sha256.convert(createdomainseparatorbytes("ic-hashtree-fork") + construct_ic_system_state_tree_root_hash(tree[1]) + construct_ic_system_state_tree_root_hash(tree[2])).bytes;
    }
    else if (tree[0] == 2) {
        assert(tree.length==3);
        v = sha256.convert(createdomainseparatorbytes("ic-hashtree-labeled") + tree[1] + construct_ic_system_state_tree_root_hash(tree[2])).bytes;
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


/// Verifies that a [certificate](https://internetcomputer.org/docs/current/references/ic-interface-spec/#certificate) is by the [ic_root_key]. Throws an Exception if the certificate is invalid.
Future<void> verify_certificate(Map certificate, SubnetOrCanister subnet_or_canister, Principal url_id) async {
    Uint8List treeroothash = construct_ic_system_state_tree_root_hash(certificate['tree']);
    Uint8List derKey;
    if (certificate.containsKey('delegation')) {
        Map legation_certificate = cbor_simple.cbor.decode(Uint8List.fromList(certificate['delegation']['certificate'])) as Map;
        Uint8List legationtreeroothash = construct_ic_system_state_tree_root_hash(legation_certificate['tree']);
        bool legationcertificatevalidity = await bls12381.verify(Uint8List.fromList(legation_certificate['signature'].toList()), Uint8List.fromList(createdomainseparatorbytes('ic-state-root').toList()..addAll(legationtreeroothash)), derkeyasablskey(ic_root_key));
        if (legationcertificatevalidity == false) { 
            throw Exception('CERTIFICATE IS VOID.'); 
        }
        Uint8List legation_subnet_id_bytes = Uint8List.fromList(certificate['delegation']['subnet_id'].toList());
        switch (subnet_or_canister) {
            case SubnetOrCanister.subnet: 
                if (aresamebytes(url_id.bytes, legation_subnet_id_bytes) == false) {
                    throw Exception('CERTIFICATE IS VOID. Target subnet-id does not match the delegation');
                }
            case SubnetOrCanister.canister:
                List<(Principal, Principal)> canister_ranges = decode_canister_ranges(lookup_path_value_in_an_ic_certificate_tree(legation_certificate['tree'], pathbytes(['subnet', legation_subnet_id_bytes, 'canister_ranges']))!);  
                if (canister_ranges.is_canister_here(url_id) == false) {
                    throw Exception('CERTIFICATE IS VOID. Target canister-id is not within the delegated canister-ranges.');
                }
        }
        derKey = lookup_path_value_in_an_ic_certificate_tree(legation_certificate['tree'], pathbytes(['subnet', legation_subnet_id_bytes, 'public_key']))!;
    } else {
        derKey = ic_root_key; 
    }
    Uint8List blskey = derkeyasablskey(derKey);
    bool certificatevalidity = await bls12381.verify(Uint8List.fromList(certificate['signature'].toList()), Uint8List.fromList(createdomainseparatorbytes('ic-state-root').toList()..addAll(treeroothash)), blskey);
    if (certificatevalidity == false) { 
        throw Exception('CERTIFICATE IS VOID.');
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
Uint8List? lookup_path_value_in_an_ic_certificate_tree(
    List tree, 
    List<Uint8List> path
) {
    if (path.length > 0) {
        List flattrees = flattentreeforks(tree);
        for (List flattree in flattrees) {
            if (flattree[0]==2) {
                if (aresamebytes(flattree[1], path[0]) == true) {
                    return lookup_path_value_in_an_ic_certificate_tree(flattree[2], path.sublist(1));
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


List<Uint8List> lookup_path_branches_in_an_ic_certificate_tree(
    List tree,
    List<Uint8List> path,
) {
    List<Uint8List> list = [];
    if (path.length > 0) {
        List flattrees = flattentreeforks(tree);
        for (List flattree in flattrees) {
            if (flattree[0]==2) {
                if (aresamebytes(flattree[1], path[0]) == true) {
                    return lookup_path_branches_in_an_ic_certificate_tree(flattree[2], path.sublist(1));
                }
            }
        }
    }
    else {
        List flattrees = flattentreeforks(tree);
        for (List flattree in flattrees) {
            if (flattree[0]==2) {
                list.add(Uint8List.fromList(flattree[1]));    
            }
        }
    }
    return list;
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
