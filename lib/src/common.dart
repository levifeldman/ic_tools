import 'dart:typed_data';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';

import './ic_tools.dart';
import './candid.dart';
import './tools/tools.dart';



final Canister root        = Canister(Principal('r7inp-6aaaa-aaaaa-aaabq-cai'));
final Canister management  = Canister(Principal('aaaaa-aa'));
final Canister ledger      = Canister(Principal('ryjl3-tyaaa-aaaaa-aaaba-cai'));
final Canister governance  = Canister(Principal('rrkah-fqaaa-aaaaa-aaaaq-cai'));
final Canister cycles_mint = Canister(Principal('rkp4c-7iaaa-aaaaa-aaaca-cai'));
final Canister ii          = Canister(Principal('rdmx6-jaaaa-aaaaa-aaadq-cai'));





Future<double> check_icp_balance(String icp_id) async {
    //Record record = Record.oftheMap({'account': Text(icp_id)});
    //Uint8List sponse_bytes = await ledger.call(calltype: CallType.call, method_name: 'account_balance_dfx', put_bytes: c_forwards([record]));
    Uint8List sponse_bytes = await ledger.call(
        calltype: CallType.call,
        method_name: 'account_balance',
        put_bytes: c_forwards([
            Record.oftheMap({
                'account': Blob(hexstringasthebytes(icp_id))
            })
        ])
    );
    Record icpts_balance_record = c_backwards(sponse_bytes)[0] as Record;
    Nat64 e8s = icpts_balance_record['e8s'] as Nat64;
    return e8s.value / BigInt.from(100000000); 
}


Future<Nat64> transfer_icp(Caller caller, String fortheicpid, double mount, {double? fee, Nat64? memo, List<int>? subaccount_bytes, List<Legation> legations = const [] } ) async {
    fee ??= 0.0001;
    memo ??= Nat64(BigInt.from(0));
    subaccount_bytes ??= Uint8List(32);
    if (subaccount_bytes.length != 32) { throw Exception(': subaccount_bytes-parameter of this function is with the length-quirement: 32-bytes.'); }
    if (check_double_decimal_point_places(mount) > 8 || check_double_decimal_point_places(fee) > 8) {
        throw Exception('mount and fee can have max: 8 decimal-point-number-places');
    }
    Record sendargs = Record.oftheMap({
        'memo': memo,
        'amount': Record.oftheMap({'e8s': Nat64(BigInt.from((mount * 100000000).toInt()))}),
        'fee': Record.oftheMap({'e8s': Nat64(BigInt.from((fee * 100000000).toInt()))}),
        'to': Text(fortheicpid),
        'from_subaccount': Option(value: Blob(subaccount_bytes)),
        // 'created_at_time': Option()
    });
    Nat64 block_height = c_backwards(await ledger.call(calltype: CallType.call, method_name: 'send_dfx', put_bytes: c_forwards([sendargs]), caller: caller, legations: legations))[0] as Nat64;
    return block_height;
}




String icp_id(Principal principal, {List<int>? subaccount_bytes}) {
    subaccount_bytes ??= Uint8List(32);
    if (subaccount_bytes.length != 32) { throw Exception(': subaccount_bytes-parameter of this function is with the length-quirement: 32-bytes.'); }
    List<int> blobl = [];
    blobl.addAll(utf8.encode('\x0Aaccount-id'));
    blobl.addAll(principal.bytes);
    blobl.addAll(subaccount_bytes);
    Uint8List blob = Uint8List.fromList(sha224.convert(blobl).bytes);
    Crc32 crc32 = Crc32();
    crc32.add(blob);
    List<int> text_format_bytes = [];
    text_format_bytes.addAll(crc32.close());
    text_format_bytes.addAll(blob);
    String text_format = bytesasahexstring(text_format_bytes);
    return text_format;
}

extension PrincipalIcpId on Principal {
    String icp_id({List<int>? subaccount_bytes}) {
        subaccount_bytes ??= Uint8List(32);
        if (subaccount_bytes.length != 32) { throw Exception(': subaccount_bytes-parameter of this function is with the length-quirement: 32-bytes.'); }
        List<int> blobl = [];
        blobl.addAll(utf8.encode('\x0Aaccount-id'));
        blobl.addAll(this.bytes);
        blobl.addAll(subaccount_bytes);
        Uint8List blob = Uint8List.fromList(sha224.convert(blobl).bytes);
        Crc32 crc32 = Crc32();
        crc32.add(blob);
        List<int> text_format_bytes = [];
        text_format_bytes.addAll(crc32.close());
        text_format_bytes.addAll(blob);
        String text_format = bytesasahexstring(text_format_bytes);
        return text_format;
    }

}





final Nat64 MEMO_CREATE_CANISTER_nat64 = Nat64(BigInt.from(1095062083)); // int.parse(bytesasabitstring(hexstringasthebytes('0x41455243')), radix: 2); // == 'CREA'
final Nat64 MEMO_TOP_UP_CANISTER_nat64 = Nat64(BigInt.from(1347768404)); // int.parse(bytesasabitstring(hexstringasthebytes('0x50555054')), radix: 2); // == 'TPUP'

Uint8List principal_as_an_icpsubaccountbytes(Principal principal) {
    List<int> bytes = []; // an icp subaccount is 32 bytes
    bytes.add(principal.bytes.length);
    bytes.addAll(principal.bytes);
    while (bytes.length < 32) { bytes.add(0); }
    return Uint8List.fromList(bytes);
}
Principal icpsubaccountbytes_as_a_principal(Uint8List subaccount_bytes) {
    int principal_bytes_len = subaccount_bytes[0];
    List<int> principal_bytes = subaccount_bytes.sublist(1, principal_bytes_len + 1);
    return Principal.oftheBytes(Uint8List.fromList(principal_bytes));
}


Future<Principal> create_canister(Caller caller, double icp_count, {Uint8List? from_subaccount_bytes, Nat64? block_height}) async {
    Uint8List to_subaccount_bytes = principal_as_an_icpsubaccountbytes(caller.principal);
    
    if (block_height == null) {
        block_height = await transfer_icp(
            caller, 
            cycles_mint.principal.icp_id(subaccount_bytes: to_subaccount_bytes), 
            icp_count, 
            subaccount_bytes: from_subaccount_bytes,
            memo: MEMO_CREATE_CANISTER_nat64,
        );
        print('block_height: ${block_height}');
    } else {
        print('using given block_height: $block_height');
    }

    Record notifycanisterargs = Record.oftheMap({
        'block_height' : block_height,
        'max_fee'      : Record.oftheMap({'e8s': Nat64(BigInt.from((0.0001 * 100000000).toInt()))}),
        'to_canister'  : cycles_mint.principal.candid,
        'to_subaccount': Option(value: Blob( to_subaccount_bytes )) 
    });
    if (from_subaccount_bytes != null ) {
        notifycanisterargs['from_subaccount'] = Option(value: Blob(from_subaccount_bytes));
    }

    Uint8List notify_sponse_bytes = await ledger.call(calltype: CallType.call, method_name: 'notify_dfx', put_bytes: c_forwards([notifycanisterargs]), caller: caller);
    List<CandidType> notify_sponse_candids = c_backwards(notify_sponse_bytes);
    Variant variant = notify_sponse_candids[0] as Variant;
    if (variant.containsKey('CanisterCreated')) {
        PrincipalReference principal_fer = variant['CanisterCreated'] as PrincipalReference;
        Principal new_canister_principal = principal_fer.principal!;
        print(new_canister_principal);
        return new_canister_principal;
    } else if (variant.containsKey('Refunded')) {
        throw Exception('looks like the call was refunded for some reason. gave back this record: ${variant['Refunded']}');
    } else {
        throw Exception('notify_dfx gives-back this variant: ${variant}');
    }
}


Future<void> top_up_canister(Caller caller, double icp_mount, Principal canister_id, {Uint8List? from_subaccount_bytes, Nat64? block_height}) async {
    Uint8List to_subaccount_bytes = principal_as_an_icpsubaccountbytes(canister_id);

    if (block_height == null) {
        block_height = await transfer_icp(
            caller, 
            cycles_mint.principal.icp_id(subaccount_bytes: to_subaccount_bytes), 
            icp_mount, 
            subaccount_bytes: from_subaccount_bytes,
            memo: MEMO_TOP_UP_CANISTER_nat64,
        );
        print('block_height: ${block_height}');
    } else {
        print('using given block_height: $block_height');
    }

    Record notifycanisterargs = Record.oftheMap({
        'block_height' : block_height,
        'max_fee'      : Record.oftheMap({'e8s': Nat64(BigInt.from((0.0001 * 100000000).toInt()))}),
        'to_canister'  : cycles_mint.principal.candid, 
        'to_subaccount': Option(value: Blob( to_subaccount_bytes )) 
    });
    if (from_subaccount_bytes != null ) {
        notifycanisterargs['from_subaccount'] = Option(value: Blob(from_subaccount_bytes));
    }

    Variant variant = c_backwards(await ledger.call(calltype: CallType.call, method_name: 'notify_dfx', put_bytes: c_forwards([notifycanisterargs]), caller: caller))[0] as Variant;
    if (variant.containsKey('ToppedUp')) {
        return;
    } else if (variant.containsKey('Refunded')) {
        throw Exception('looks like the call was refunded for some reason. gave back this record: ${variant['Refunded']}');
    } else {
        throw Exception('notify_dfx gives-back this variant: ${variant}');
    }
}



Future<Map> check_canister_status(Caller caller, Principal canister_id) async {
    Uint8List canister_status_sponse_bytes = await management.call(
        caller: caller,
        calltype: CallType.call,
        method_name: 'canister_status',
        put_bytes: c_forwards([
            Record.oftheMap({
                'canister_id': canister_id.candid }) ]) 
    );
    Record canister_status_record = c_backwards(canister_status_sponse_bytes)[0] as Record;
    Map canister_status_map = {};
    // status
    Variant status_variant = canister_status_record['status'] as Variant;
    ['running', 'stopping', 'stopped'].forEach((status_possibility) {
        if (status_variant.containsKey(status_possibility)) { 
            canister_status_map['status'] = status_possibility; } 
    });
    // settings    
    Record settings_record = canister_status_record['settings'] as Record;
    canister_status_map['settings'] = {};
    canister_status_map['settings']['controllers'] = (settings_record['controllers'] as Vector).cast<PrincipalReference>().map<Principal>((pr)=>pr.principal!).toList();
    canister_status_map['settings']['compute_allocation'] = (settings_record['compute_allocation'] as Nat).value;
    canister_status_map['settings']['memory_allocation'] = (settings_record['memory_allocation'] as Nat).value;
    canister_status_map['settings']['freezing_threshold'] = (settings_record['freezing_threshold'] as Nat).value;
    // module_hash
    Option optional_module_hash = canister_status_record['module_hash'] as Option;
    canister_status_map['module_hash'] = optional_module_hash.value != null ? Blob.oftheVector((optional_module_hash.value as Vector).cast_vector<Nat8>()).bytes : null;
    // memory_size
    canister_status_map['memory_size'] = (canister_status_record['memory_size'] as Nat).value;
    // cycles
    canister_status_map['cycles'] = (canister_status_record['cycles'] as Nat).value;
    return canister_status_map;
}


Future<void> put_code_on_the_canister(Caller caller, Principal canister_id, Uint8List wasm_canister_bytes, String mode, [Uint8List? canister_install_arg]) async {
    Uint8List put_code_sponse_bytes = await management.call(
        caller: caller,
        calltype: CallType.call,
        method_name: 'install_code',
        put_bytes: c_forwards([
            Record.oftheMap({
                'mode': Variant.oftheMap({mode: Null()}),
                'canister_id': canister_id.candid,
                'wasm_module': Blob(wasm_canister_bytes),
                'arg': canister_install_arg != null ? Blob(canister_install_arg) : Blob()
            })
        ])
    );
}




class IcpTokens extends Record {
    final BigInt e8s;
    IcpTokens({required this.e8s}) { 
        super['e8s'] = Nat64(this.e8s);
    }
    String toString() {
        String s = this.e8s.toRadixString(10);
        while (s.length < IcpTokens.DECIMAL_PLACES + 1) { s = '0$s'; }
        int split_i = s.length - IcpTokens.DECIMAL_PLACES;
        s = '${s.substring(0, split_i)}.${s.substring(split_i)}';
        while (s[s.length - 1] == '0' && s.length > 3/*minimum '0.0'*/) { s = s.substring(0, s.length - 1); }
        return s;   
    }
    static IcpTokens oftheRecord(CandidType icptokensrecord) {
        Nat64 e8s_nat64 = (icptokensrecord as Record)['e8s'] as Nat64; 
        return IcpTokens(
            e8s: e8s_nat64.value
        );
    }
    static IcpTokens oftheDouble(double icp) {
        if (check_double_decimal_point_places(icp) > IcpTokens.DECIMAL_PLACES) {
            throw Exception('max ${IcpTokens.DECIMAL_PLACES} decimal places for the icp');
        }
        return IcpTokens(
            e8s: BigInt.parse((icp * IcpTokens.DIVIDABLE_BY.toDouble()).toString().split('.')[0])
        );
    }
    static int DECIMAL_PLACES = 8;    
    static BigInt DIVIDABLE_BY = BigInt.from(pow(10, IcpTokens.DECIMAL_PLACES));
    
    IcpTokens operator + (IcpTokens t) {
        return IcpTokens(e8s: this.e8s + t.e8s);
    }    
    IcpTokens operator - (IcpTokens t) {
        return IcpTokens(e8s: this.e8s - t.e8s);
    } 
    IcpTokens operator * (IcpTokens t) {
        return IcpTokens(e8s: this.e8s * t.e8s);
    } 
    IcpTokens operator ~/ (IcpTokens t) {
        return IcpTokens(e8s: this.e8s ~/ t.e8s);
    } 
    bool operator > (IcpTokens t) {
        return this.e8s > t.e8s;
    } 
    bool operator < (IcpTokens t) {
        return this.e8s < t.e8s;
    } 
    bool operator >= (IcpTokens t) {
        return this.e8s >= t.e8s;
    } 
    bool operator <= (IcpTokens t) {
        return this.e8s <= t.e8s;
    } 
    

}




