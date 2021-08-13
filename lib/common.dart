import 'dart:typed_data';
import 'dart:convert';

import 'package:cryptography/dart.dart';
import 'package:archive/archive.dart';

import 'ic_tools.dart';
import 'candid.dart';
import 'tools/tools.dart';





Canister management  = Canister(Principal('aaaaa-aa'));
Canister cycles_mint = Canister(Principal('rkp4c-7iaaa-aaaaa-aaaca-cai'));
Canister ledger      = Canister(Principal('ryjl3-tyaaa-aaaaa-aaaba-cai'));
Canister governance  = Canister(Principal('rrkah-fqaaa-aaaaa-aaaaq-cai'));




String principal_as_an_IcpCountId(Principal principal, {List<int>? subaccount_bytes }) {
    subaccount_bytes ??= Uint8List(32);
    if (subaccount_bytes.length != 32) { throw Exception(': subaccount_bytes-parameter of this function is with the length-quirement: 32-bytes.'); }
    List<int> blobl = [];
    blobl.addAll(utf8.encode('\x0Aaccount-id'));
    blobl.addAll(principal.bytes);
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


Future<double> check_icp_balance(String icp_id) async {
    Record record = Record.oftheMap({'account': Text(icp_id)});
    Uint8List sponse_bytes = await ledger.call(calltype: 'call', method_name: 'account_balance_dfx', put_bytes: c_forwards([record]));
    Record icpts_balance_record = c_backwards(sponse_bytes)[0] as Record;
    Nat64 e8s = icpts_balance_record['e8s'] as Nat64;
    return e8s.value / 100000000; 
}


Future<Nat64> send_dfx(Caller caller, String fortheicpid, double mount, {double? fee, List<int>? subaccount_bytes } ) async {
    fee ??= 0.0001; // what is the method for the calculation of this fee?
    if (check_double_decimal_point_places(mount) > 8 || check_double_decimal_point_places(fee) > 8) {
        throw Exception('mount and fee can have max: 8 decimal-point-number-places');
    }
    Record sendargs = Record.oftheMap({
        'memo': Nat64(123),
        'amount': Record.oftheMap({'e8s': Nat64((mount * 100000000).toInt())}), // maybe needs Nat64(BigInt)
        'fee': Record.oftheMap({'e8s': Nat64((fee * 100000000).toInt())}),      // maybe needs Nat64(BigInt)
        'to': Text(fortheicpid),
        // 'created_at_time': Option()
    });
    if (subaccount_bytes != null) {
        sendargs['from_subaccount'] = Option(value: Blob(subaccount_bytes));
    }    
    Nat64 block_height = c_backwards(await ledger.call(calltype: 'call', method_name: 'send_dfx', put_bytes: c_forwards([sendargs]), caller: caller))[0] as Nat64;
    return block_height;
}








// double tcycles_for_the_icp_conversion_rate(double tcycles) {
//     // gives-back: icp for the cycles
//     throw Exception();
//     return 1.0;
// }


// Principal create_canister(Caller caller) {
//     Record new_canister_id_record = c_backwards(await management.call(calltype: 'call', method_name: 'create_canister', caller: caller))[0] as Record;
    
//     Principal new_canister_principal = Principal.oftheBytes(new_canister_id_record['canister_id']);
//     return new_canister_principal;
// }


// Future<Variant> mint_cycles({required Caller caller, required double tcycles_mount, required String create_or_tpup, Principal? tpup_canister_principal, double? max_fee, List<int>? from_subaccount_bytes }) async {
//     max_fee ??= 0.0001;
//     double tcycles_icp_mount = 

//     Nat64 block_height = send_dfx(caller, principal_as_an_IcpCountId(cycles_mint.principal), )
    
//     Record notifycanisterargs = Record.fromMap({
//         'block_height' : block_height,
//         'max_fee': ICPTs(max_fee),
//         'to_canister': PrincipalReference(id: Blob(cycles_mint.principal.bytes)) // cycles-mint canister candid Principal
//     });
//     if (from_subaccount_bytes != null ) {
//         notifycanisterargs['from_subaccount'] = Option(value: Blob(from_subaccount_bytes)),
//     }
//     if (create_or_tpup == 'create') {
//         if (tpup_canister_principal != null) {
//             throw Exception('if creating a new canister, leave tpup_canister_principal as a null.');
//         }
//         notifycanisterargs['to_subaccount'] = Option(value: Blob(caller.principal.bytes)); // controller of the canister to create , or canister to top-up // make this controller of the create an optional name-parameter
//     } 
//     else if (create_or_tpup == 'tpup') {
//         if (tpup_canister_principal == null) {
//             throw Exception('if tpup (top-up) of a canister, set tpup_canister_principal as the canister\'s-principal');
//         }
//         notifycanisterargs['to_subaccount'] = Option(value: Blob(tpup_canister_principal.bytes));
//     }
//     await ledger.call(calltype: 'call', method_name: 'notify_dfx', put_bytes: c_forward([notifycanisterargs]), caller: caller);

    
// }

// CyclesResponse variant.
// type CyclesResponse = variant {
//   Refunded : record { text; opt nat64 };
//   CanisterCreated : principal;
//   ToppedUp;
// };

