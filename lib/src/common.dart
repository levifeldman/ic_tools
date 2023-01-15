import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

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





Future<IcpTokens> check_icp_balance(String icp_id, {CallType? calltype}) async {
    Uint8List sponse_bytes = await ledger.call(
        calltype: calltype ?? CallType.call,
        method_name: 'account_balance',
        put_bytes: c_forwards([
            Record.oftheMap({
                'account': Blob(hexstringasthebytes(icp_id))
            })
        ])
    );
    return IcpTokens.oftheRecord(c_backwards(sponse_bytes)[0] as Record);
}


Future<Variant> transfer_icp(Caller caller, String fortheicpid, IcpTokens mount, {IcpTokens? fee, Nat64? memo, List<int>? subaccount_bytes, List<Legation> legations = const [] } ) async {
    fee ??= IcpTokens.oftheDoubleString('0.0001');
    memo ??= Nat64(BigInt.from(0));
    subaccount_bytes ??= Uint8List(32);
    if (subaccount_bytes.length != 32) { throw Exception(': subaccount_bytes-parameter of this function is with the length-quirement: 32-bytes.'); }

    Record sendargs = Record.oftheMap({
        'to' : Blob(hexstringasthebytes(fortheicpid)),        
        'memo': memo,
        'amount': mount,
        'fee': fee,
        'from_subaccount': Option<Blob>(value: Blob(subaccount_bytes)),
        'created_at_time': Option<Record>(value: Record.oftheMap({
            'timestamp_nanos' : Nat64(get_current_time_nanoseconds())
        }))
    });
    Variant transfer_result = c_backwards(await ledger.call(calltype: CallType.call, method_name: 'transfer', put_bytes: c_forwards([sendargs]), caller: caller, legations: legations))[0] as Variant;
    return transfer_result;
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

Map<String, Never Function(CandidType)> transfer_error_match_map = {
    'TxTooOld' : (allowed_window_nanos_r) {
        throw Exception('TxTooOld');
    },
    'BadFee' : (expected_fee_r) {
        throw Exception('BadFee, expected_fee: ${IcpTokens.oftheRecord((expected_fee_r as Record)['expected_fee'] as Record)}');
    },
    'TxDuplicate' : (duplicate_of_r) {
        throw Exception('TxDuplicate, duplicate_of: ${((duplicate_of_r as Record)['duplicate_of'] as Nat64).value}');
    },
    'TxCreatedInFuture': (nul) {
        throw Exception('TxCreatedInFuture');
    },
    'InsufficientFunds' : (balance_r) {
        throw Exception('InsufficientFunds, balance: ${IcpTokens.oftheRecord((balance_r as Record)['balance'] as Record)}');
    }
};

Map<String, Never Function(CandidType)> cmc_notify_error_match_map = {
    'Refunded' : (refund_r) {
        Record r = refund_r as Record;
        throw Exception('Refunded, reason: ${(r['reason'] as Text).value}, block_index: ${r.find_option<Nat64>('block_index')}');
    },
    'InvalidTransaction' : (text) {
        throw Exception('InvalidTransaction, ${(text as Text).value}');
    },
    'Other' : (rc) {
        Record r = rc as Record;
        throw Exception('error_message: ${(r['error_message'] as Text).value}, error_code: ${(r['error_code'] as Nat64).value}');
    },
    'Processing': (nul) {
        throw Exception('Processing');
    },
    'TransactionTooOld' : (block) {
        throw Exception('TransactionTooOld, block: ${(block as Nat64).value}');
    }
};


Future<Principal> create_canister(Caller caller, IcpTokens icp_count, {Uint8List? from_subaccount_bytes, Nat64? block_height}) async {
    Uint8List to_subaccount_bytes = principal_as_an_icpsubaccountbytes(caller.principal);
    
    if (block_height == null) {
        block_height = match_variant<Nat64>(await transfer_icp(
            caller, 
            icp_id(cycles_mint.principal, subaccount_bytes: to_subaccount_bytes), 
            icp_count, 
            subaccount_bytes: from_subaccount_bytes,
            memo: MEMO_CREATE_CANISTER_nat64,
        ), {
            'Ok': (block_height) {
                return block_height as Nat64;
            },
            'Err': (transfer_error) {
                return match_variant<Never>(transfer_error as Variant, transfer_error_match_map);
            }
        });
        print('block_height: ${block_height.value}');
    } else {
        print('using given block_height: ${block_height.value}');
    }

    Record notifycanisterarg = Record.oftheMap({
        'controller' : caller.principal,
        'block_index' : block_height,
    });

    Variant notify_create_canister_result = c_backwards(await cycles_mint.call(
        calltype: CallType.call, 
        method_name: 'notify_create_canister', 
        put_bytes: c_forwards([notifycanisterarg]), 
        caller: caller
    ))[0] as Variant;
    
    return match_variant<Principal>(notify_create_canister_result, {
        'Ok': (p) {
            return p as Principal;
        },
        'Err': (notify_error) {
            return match_variant<Never>(notify_error as Variant, cmc_notify_error_match_map);
        } 
    });
}


Future<Nat> top_up_canister(Caller caller, IcpTokens icp_mount, Principal canister_id, {Uint8List? from_subaccount_bytes, Nat64? block_height}) async {
    Uint8List to_subaccount_bytes = principal_as_an_icpsubaccountbytes(canister_id);

    if (block_height == null) {
        block_height = match_variant<Nat64>(await transfer_icp(
            caller, 
            icp_id(cycles_mint.principal, subaccount_bytes: to_subaccount_bytes), 
            icp_mount, 
            subaccount_bytes: from_subaccount_bytes,
            memo: MEMO_TOP_UP_CANISTER_nat64,
        ), {
            'Ok': (block_height) {
                return block_height as Nat64;
            },
            'Err': (transfer_error) {
                return match_variant<Never>(transfer_error as Variant, transfer_error_match_map);
            }
        });
        print('block_height: ${block_height.value}');
    } else {
        print('using given block_height: ${block_height.value}');
    }

    Record notifytopupargs = Record.oftheMap({
        'block_index' : block_height,
        'canister_id' : canister_id,
    });

    Variant notify_top_up_result = c_backwards(await cycles_mint.call(
        calltype: CallType.call, 
        method_name: 'notify_top_up', 
        put_bytes: c_forwards([notifytopupargs]), 
        caller: caller
    ))[0] as Variant;
    
    return match_variant<Nat>(notify_top_up_result, {
        'Ok': (nat) {
            return nat as Nat;
        },
        'Err': (notify_error) {
            return match_variant<Never>(notify_error as Variant, cmc_notify_error_match_map);
        }
    });

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
        while (s[s.length - 1] == '0' && s[s.length - 2] != '.') { s = s.substring(0, s.length - 1); }
        return s;   
    }
    IcpTokens round_decimal_places(int round_decimal_places) {
        //print('icp without round: $this');
        List<String> icp_string_split = this.toString().split('.');
        if (icp_string_split.length <= 1) {
            return this;
        }
        String decimal_places_string = icp_string_split[1];
        if (round_decimal_places >= decimal_places_string.length) {
            return this;
        }
        String decimal_places_split_at_round = decimal_places_string.substring(0, round_decimal_places);
        return IcpTokens.oftheDoubleString('${icp_string_split[0]}.${BigInt.parse(decimal_places_split_at_round)+BigInt.from(1)}');
    }
    static IcpTokens oftheRecord(CandidType icptokensrecord) {
        Nat64 e8s_nat64 = (icptokensrecord as Record)['e8s'] as Nat64; 
        return IcpTokens(
            e8s: e8s_nat64.value
        );
    }
    static IcpTokens oftheDoubleString(String icp_string) {
        icp_string = icp_string.trim();
        if (icp_string == '') {
            throw Exception('must be a number');
        }
        List<String> icp_string_split = icp_string.split('.');
        if (icp_string_split.length > 2) {
            throw Exception('invalid number.');
        } 
        BigInt icp = BigInt.parse(icp_string_split[0]);
        BigInt icp_e8s_less_than_1 = BigInt.from(0);        
        if (icp_string_split.length == 2) {
            String decimal_places = icp_string_split[1];     
            if (decimal_places.length > IcpTokens.DECIMAL_PLACES) {
                throw Exception('Max ${IcpTokens.DECIMAL_PLACES} decimal places for the IcpTokens');
            }
            while (decimal_places.length < IcpTokens.DECIMAL_PLACES) {
                decimal_places = '${decimal_places}0';
            }
            icp_e8s_less_than_1 = BigInt.parse(decimal_places);
        }
        IcpTokens icptokens = IcpTokens(e8s: (icp * IcpTokens.DIVIDABLE_BY) + icp_e8s_less_than_1);
        return icptokens;
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




