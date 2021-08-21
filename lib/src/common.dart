import 'dart:typed_data';
import 'dart:convert';

import 'package:cryptography/dart.dart';
import 'package:archive/archive.dart';

import './ic_tools.dart';
import './candid.dart';
import './tools/tools.dart';





Canister management  = Canister(Principal('aaaaa-aa'));
Canister ledger      = Canister(Principal('ryjl3-tyaaa-aaaaa-aaaba-cai'));
Canister governance  = Canister(Principal('rrkah-fqaaa-aaaaa-aaaaq-cai'));
Canister cycles_mint = Canister(Principal('rkp4c-7iaaa-aaaaa-aaaca-cai'));








Future<double> check_icp_balance(String icp_id) async {
    Record record = Record.oftheMap({'account': Text(icp_id)});
    Uint8List sponse_bytes = await ledger.call(calltype: 'call', method_name: 'account_balance_dfx', put_bytes: c_forwards([record]));
    Record icpts_balance_record = c_backwards(sponse_bytes)[0] as Record;
    Nat64 e8s = icpts_balance_record['e8s'] as Nat64;
    return e8s.value / 100000000; 
}


Future<Nat64> send_dfx(Caller caller, String fortheicpid, double mount, {double? fee, Nat64? memo, List<int>? subaccount_bytes } ) async {
    fee ??= 0.0001; // what is the method for the calculation of this fee?
    memo ??= Nat64(123);
    if (check_double_decimal_point_places(mount) > 8 || check_double_decimal_point_places(fee) > 8) {
        throw Exception('mount and fee can have max: 8 decimal-point-number-places');
    }
    Record sendargs = Record.oftheMap({
        'memo': memo,
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






final Nat64 MEMO_CREATE_CANISTER_nat64 = Nat64(1095062083); // int.parse(bytesasabitstring(hexstringasthebytes('0x41455243')), radix: 2); // == 'CREA'
final Nat64 MEMO_TOP_UP_CANISTER_nat64 = Nat64(1347768404); // int.parse(bytesasabitstring(hexstringasthebytes('0x50555054')), radix: 2); // == 'TPUP'


Uint8List principal_as_a_subaccountbytes(Principal principal) {
    List<int> bytes = []; // an icp subaccount is 32 bytes
    bytes.add(principal.bytes.length);
    bytes.addAll(principal.bytes);
    while (bytes.length < 32) { bytes.add(0); }
    return Uint8List.fromList(bytes);
}
Principal subaccountbytes_as_a_principal(Uint8List subaccount_bytes) {
    int principal_bytes_len = subaccount_bytes[0];
    List<int> principal_bytes = subaccount_bytes.sublist(1, principal_bytes_len + 1);
    return Principal.oftheBytes(Uint8List.fromList(principal_bytes));
}


Future<Principal> create_canister(Caller caller, double icp_mount, {Uint8List? from_subaccount_bytes}) async {
    Uint8List to_subaccount_bytes = principal_as_a_subaccountbytes(caller.principal);
    
    Nat64 block_height = await send_dfx(
        caller, 
        principal_as_an_IcpCountId(cycles_mint.principal, subaccount_bytes: to_subaccount_bytes), 
        icp_mount, 
        subaccount_bytes: from_subaccount_bytes,
        memo: MEMO_CREATE_CANISTER_nat64,
    );
    print('block_height: ${block_height}');

    Record notifycanisterargs = Record.oftheMap({
        'block_height' : block_height,
        'max_fee'      : Record.oftheMap({'e8s': Nat64((0.0001 * 100000000).toInt())}),
        'to_canister'  : Blob(cycles_mint.principal.bytes),  //PrincipalReference(id:  // cycles-mint canister candid Principal
        'to_subaccount': Option(value: Blob( to_subaccount_bytes )) // controller of the canister to create 
    });
    if (from_subaccount_bytes != null ) {
        notifycanisterargs['from_subaccount'] = Option(value: Blob(from_subaccount_bytes));
    }

    Uint8List notify_sponse_bytes = await ledger.call(calltype: 'call', method_name: 'notify_dfx', put_bytes: c_forwards([notifycanisterargs]), caller: caller);
    // print('notify_sponse_bytes: ${notify_sponse_bytes}');
    List<CandidType> notify_sponse_candids = c_backwards(notify_sponse_bytes);
    Variant variant = notify_sponse_candids[0] as Variant;
    // print('notify_sponse_variant: ${variant}');
    if (variant.containsKey('CanisterCreated')) {
        PrincipalReference principal_fer = variant['CanisterCreated'] as PrincipalReference;
        Principal new_canister_principal = Principal.oftheBytes(principal_fer.id!.bytes);
        print(new_canister_principal);
        return new_canister_principal;
    } else if (variant.containsKey('Refunded')) {
        throw Exception('looks like the call was refunded for some reason. gave back this record: ${variant['Refunded']}');
    } else {
        throw Exception('notify_dfx gives-back this variant: ${variant}');
    }
}






