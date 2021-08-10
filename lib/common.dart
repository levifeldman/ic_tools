import 'dart:typed_data';

import 'package:cryptography/dart.dart';
import 'package:archive/archive.dart';

import 'ic_tools.dart';
import 'candid.dart';
import 'tools.dart';
import 'icp.dart';


Canister ledger = Canister(Principal('ryjl3-tyaaa-aaaaa-aaaba-cai'));
Canister management = Canister('aaaaa-aa');
Canister cycles_mint = Canister('rkp4c-7iaaa-aaaaa-aaaca-cai');


class ICPTs extends Record {
    get double icp {
        Nat64 nat64e8s = this['e8s'] as Nat64;
        return nat64e8s.value / 100000000;
    }
    ICPTs(double icp_value) {
        if (check_double_decimal_point_places(icp_value) > 8) {
            throw Exception('icp can be with a max: 8 decimal-point-places');
        }
        this['e8s'] = Nat64((icp_value * 100000000).toInt());
    }
    void operator []=(dynamic key, CandidType value) { // key can be String or a nat(int). if key is String it gets hashed with the candid-hash for the lookup which is: nat. 
        int k = key is int ? key : candid_text_hash(key);
        if (k != candid_text_hash('e8s')) {
            throw Exception('ICPTs-Record class has one field: "e8s"');
        }
        super[key] = value;
    }

    static int check_double_decimal_point_places(double d) => d.toString().substring(d.toString().indexOf('.') + 1).length;
}




String principal_as_an_IcpCountId(Principal principal, {List<int>? subaccount_bytes }) {
    subaccount_bytes ??= Uint8List(32);
    if (subaccount_bytes.length != 32) { throw Exception(': subaccount_bytes-parameter of this function is with the length-quirement: 32-bytes.'); }
    List<int> blobl = [];
    blobl.addAll(utf8.encode('\x0Aaccount-id'));
    blobl.addAll(principal.blob);
    blobl.addAll(subaccount_bytes);
    DartSha224 sha224 = DartSha224();
    Uint8List blob = Uint8List.fromList(sha224.hashSync(blobl).bytes);
    Crc32 crc32 = Crc32();
    crc32.add(blob);
    List<int> text_format_bytes = [];
    text_format_bytes.addAll(crc32.close());
    text_format_bytes.addAll(blob);
    String text_format = bytesasahexstring(text_format_bytes);
    return text_format;
}

Future<ICPTs> check_icp_balance(String ICPID) async {
    Record record = Record.fromMap({'account': Text(ICPID)});
    Uint8List sponse_bytes = await ledger.call(calltype: 'call', methodName: 'account_balance_dfx', put_bytes: c_forwards([record]));
    ICPTs icpts_balance_record = c_backwards(sponse_bytes)[0] as ICPTs;
    return icpts;
   
 
}

Future<Nat64> send_dfx(Caller caller, String fortheicpid, double mount, {double? fee, List<int>? subaccount_bytes } ) async {
    fee ??= 0.0001; // what is the method for the calculation of this fee?
    if (check_double_decimal_point_places(mount) > 8 || check_double_decimal_point_places(fee) > 8) {
        throw Exception('mount and fee can have max: 8 decimal-point-number-places');
    }
    Record sendargs = Record.fromMap({
        'memo': Nat64(123),
        'amount': ICPTs(mount),
        'fee': ICPTs(fee),
        'to': Text(fortheicpid),
        // 'created_at_time': Option()
    });
    if (subaccount_bytes != null) {
        sendargs['from_subaccount'] = Option(value: Vector.fromList(subaccount_bytes.map((int byte)=>Nat8(byte)).toList())),
    }    
    return c_backwards(await ledger.call(calltype: 'call', methodName: 'send_dfx', put_bytes: c_forwards([sendargs]), caller: caller))[0] as Nat64; 
}





Principal create_canister(Caller caller) {
    Record new_canister_id_record = c_backwards(await management.call(calltype: 'call', methodName: 'create_canister', caller: caller))[0] as Record;
    
    Principal new_canister_principal = Principal.ofBlob(new_canister_id_record['canister_id']);
    return new_canister_principal;
}


// CyclesResponse variant.
// type CyclesResponse = variant {
//   Refunded : record { text; opt nat64 };
//   CanisterCreated : principal;
//   ToppedUp;
// };
Future<Variant> mint_cycles(Caller caller, {required Principal canister, double? max_fee, List<int>? from_subaccount_bytes }) async {
    max_fee ??= 0.0001;

    Nat64 block_height = send_dfx(caller, )
    Record notifycanisterargs = Record.fromMap({
        'block_height' : block_height,
        'max_fee': ICPTs(max_fee),
        'to_canister': Principal; // ledger canister candid Principal
        'to_subaccount': Option(value: Vector.Blob(caller)) , // controller of the canister to create , or canister to top-up
    });
    if (from_subaccount_bytes != null ) {
        notifycanisterargs['from_subaccount'] = Option(value: Vector.Blob(from_subaccount_bytes)),
    }
}


