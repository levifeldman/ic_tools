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


const String Ok  = 'Ok';
const String Err = 'Err';





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
                'arg': canister_install_arg != null ? Blob(canister_install_arg) : Blob([])
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




class Icrc1Ledger {
    final Canister ledger;
    final String symbol;
    final String name;
    final int decimals;
    BigInt fee;
    Tokens get fee_tokens => Tokens(token_quantums: fee, decimal_places: decimals);
    final String? logo_data_url;
    final Canister? index;
    
    Icrc1Ledger({
        required this.ledger, 
        required this.symbol, 
        required this.name, 
        required this.decimals, 
        required this.fee, 
        this.logo_data_url,
        this.index
    });
    
    static Future<Icrc1Ledger> load(Principal icrc1_ledger_id) async {
        Canister icrc1_ledger = Canister(icrc1_ledger_id);
        Vector<Record> metadata = (c_backwards(await icrc1_ledger.call(
            method_name: 'icrc1_metadata',
            calltype: CallType.call,
        ))[0] as Vector).cast_vector<Record>();
        late final String symbol;
        late final String name;
        late final int decimals;
        late final BigInt fee;
        String? logo_data_url;
        for (Record r in metadata) {
            if ((r[0] as Text).value == 'icrc1:decimals') {
                decimals = ((r[1] as Variant)['Nat'] as Nat).value.toInt();
            } else if ((r[0] as Text).value == 'icrc1:name') {
                name = ((r[1] as Variant)['Text'] as Text).value;
            } else if ((r[0] as Text).value == 'icrc1:symbol') {
                symbol = ((r[1] as Variant)['Text'] as Text).value;
            } else if ((r[0] as Text).value == 'icrc1:fee') {
                fee = ((r[1] as Variant)['Nat'] as Nat).value;
            } else if ((r[0] as Text).value == 'icrc1:logo') {
                logo_data_url = ((r[1] as Variant)['Text'] as Text).value;
            }
        }
        // call icrc1_supported_standards and find the icrc building blocks
        return Icrc1Ledger(
            symbol: symbol,
            name:name,
            decimals:decimals,
            fee:fee,
            ledger: Canister(icrc1_ledger_id),
            logo_data_url: logo_data_url
        );
    }

    String toString() {
        return 'Icrc1Ledger: ${this.name}';
    }

    @override
    bool operator ==(/*covariant Icrc1Ledger*/ other) => other is Icrc1Ledger && other.ledger == this.ledger;

    @override
    int get hashCode => this.ledger.hashCode;
    
}    
class Icrc1Ledgers {
    static Icrc1Ledger ICP = _ICP;
    static Icrc1Ledger SNS1 = _SNS1;
    static Icrc1Ledger ckBTC = _ckBTC;
    static List<Icrc1Ledger> all = [ICP,SNS1,ckBTC];
}
final Icrc1Ledger _ICP = Icrc1Ledger(
    //logo_data_url: ,
    symbol: 'ICP',
    name:'Internet Computer',
    decimals:8,
    fee:BigInt.from(10000),
    ledger: ledger
);
final Icrc1Ledger _SNS1 = Icrc1Ledger(
    //logo_data_url: ,
    symbol: 'SNS1',
    name:'SNS-1',
    decimals:8,
    fee:BigInt.from(1000),
    ledger: Canister(Principal('zfcdd-tqaaa-aaaaq-aaaga-cai')),
    index: Canister(Principal('zlaol-iaaaa-aaaaq-aaaha-cai'))
    
);
final Icrc1Ledger _ckBTC = Icrc1Ledger(
    logo_data_url: "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTQ2IiBoZWlnaHQ9IjE0NiIgdmlld0JveD0iMCAwIDE0NiAxNDYiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIxNDYiIGhlaWdodD0iMTQ2IiByeD0iNzMiIGZpbGw9IiMzQjAwQjkiLz4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0xNi4zODM3IDc3LjIwNTJDMTguNDM0IDEwNS4yMDYgNDAuNzk0IDEyNy41NjYgNjguNzk0OSAxMjkuNjE2VjEzNS45MzlDMzcuMzA4NyAxMzMuODY3IDEyLjEzMyAxMDguNjkxIDEwLjA2MDUgNzcuMjA1MkgxNi4zODM3WiIgZmlsbD0idXJsKCNwYWludDBfbGluZWFyXzExMF81NzIpIi8+CjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNNjguNzY0NiAxNi4zNTM0QzQwLjc2MzggMTguNDAzNiAxOC40MDM3IDQwLjc2MzcgMTYuMzUzNSA2OC43NjQ2TDEwLjAzMDMgNjguNzY0NkMxMi4xMDI3IDM3LjI3ODQgMzcuMjc4NSAxMi4xMDI2IDY4Ljc2NDYgMTAuMDMwMkw2OC43NjQ2IDE2LjM1MzRaIiBmaWxsPSIjMjlBQkUyIi8+CjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNMTI5LjYxNiA2OC43MzQzQzEyNy41NjYgNDAuNzMzNSAxMDUuMjA2IDE4LjM3MzQgNzcuMjA1MSAxNi4zMjMyTDc3LjIwNTEgMTBDMTA4LjY5MSAxMi4wNzI0IDEzMy44NjcgMzcuMjQ4MiAxMzUuOTM5IDY4LjczNDNMMTI5LjYxNiA2OC43MzQzWiIgZmlsbD0idXJsKCNwYWludDFfbGluZWFyXzExMF81NzIpIi8+CjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNNzcuMjM1NCAxMjkuNTg2QzEwNS4yMzYgMTI3LjUzNiAxMjcuNTk2IDEwNS4xNzYgMTI5LjY0NyA3Ny4xNzQ5TDEzNS45NyA3Ny4xNzQ5QzEzMy44OTcgMTA4LjY2MSAxMDguNzIyIDEzMy44MzcgNzcuMjM1NCAxMzUuOTA5TDc3LjIzNTQgMTI5LjU4NloiIGZpbGw9IiMyOUFCRTIiLz4KPHBhdGggZD0iTTk5LjgyMTcgNjQuNzI0NUMxMDEuMDE0IDU2Ljc1MzggOTQuOTQ0NyA1Mi40Njg5IDg2LjY0NTUgNDkuNjEwNEw4OS4zMzc2IDM4LjgxM0w4Mi43NjQ1IDM3LjE3NUw4MC4xNDM1IDQ3LjY4NzlDNzguNDE1NSA0Ny4yNTczIDc2LjY0MDYgNDYuODUxMSA3NC44NzcxIDQ2LjQ0ODdMNzcuNTE2OCAzNS44NjY1TDcwLjk0NzQgMzQuMjI4NUw2OC4yNTM0IDQ1LjAyMjJDNjYuODIzIDQ0LjY5NjUgNjUuNDE4OSA0NC4zNzQ2IDY0LjA1NiA0NC4wMzU3TDY0LjA2MzUgNDQuMDAyTDU0Ljk5ODUgNDEuNzM4OEw1My4yNDk5IDQ4Ljc1ODZDNTMuMjQ5OSA0OC43NTg2IDU4LjEyNjkgNDkuODc2MiA1OC4wMjM5IDQ5Ljk0NTRDNjAuNjg2MSA1MC42MSA2MS4xNjcyIDUyLjM3MTUgNjEuMDg2NyA1My43NjhDNTguNjI3IDYzLjYzNDUgNTYuMTcyMSA3My40Nzg4IDUzLjcxMDQgODMuMzQ2N0M1My4zODQ3IDg0LjE1NTQgNTIuNTU5MSA4NS4zNjg0IDUwLjY5ODIgODQuOTA3OUM1MC43NjM3IDg1LjAwMzQgNDUuOTIwNCA4My43MTU1IDQ1LjkyMDQgODMuNzE1NUw0Mi42NTcyIDkxLjIzODlMNTEuMjExMSA5My4zNzFDNTIuODAyNSA5My43Njk3IDU0LjM2MTkgOTQuMTg3MiA1NS44OTcxIDk0LjU4MDNMNTMuMTc2OSAxMDUuNTAxTDU5Ljc0MjYgMTA3LjEzOUw2Mi40MzY2IDk2LjMzNDNDNjQuMjMwMSA5Ni44MjEgNjUuOTcxMiA5Ny4yNzAzIDY3LjY3NDkgOTcuNjkzNEw2NC45OTAyIDEwOC40NDhMNzEuNTYzNCAxMTAuMDg2TDc0LjI4MzYgOTkuMTg1M0M4NS40OTIyIDEwMS4zMDYgOTMuOTIwNyAxMDAuNDUxIDk3LjQ2ODQgOTAuMzE0MUMxMDAuMzI3IDgyLjE1MjQgOTcuMzI2MSA3Ny40NDQ1IDkxLjQyODggNzQuMzc0NUM5NS43MjM2IDczLjM4NDIgOTguOTU4NiA3MC41NTk0IDk5LjgyMTcgNjQuNzI0NVpNODQuODAzMiA4NS43ODIxQzgyLjc3MiA5My45NDM4IDY5LjAyODQgODkuNTMxNiA2NC41NzI3IDg4LjQyNTNMNjguMTgyMiA3My45NTdDNzIuNjM4IDc1LjA2ODkgODYuOTI2MyA3Ny4yNzA0IDg0LjgwMzIgODUuNzgyMVpNODYuODM2NCA2NC42MDY2Qzg0Ljk4MyA3Mi4wMzA3IDczLjU0NDEgNjguMjU4OCA2OS44MzM1IDY3LjMzNEw3My4xMDYgNTQuMjExN0M3Ni44MTY2IDU1LjEzNjQgODguNzY2NiA1Ni44NjIzIDg2LjgzNjQgNjQuNjA2NloiIGZpbGw9IndoaXRlIi8+CjxkZWZzPgo8bGluZWFyR3JhZGllbnQgaWQ9InBhaW50MF9saW5lYXJfMTEwXzU3MiIgeDE9IjUzLjQ3MzYiIHkxPSIxMjIuNzkiIHgyPSIxNC4wMzYyIiB5Mj0iODkuNTc4NiIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiPgo8c3RvcCBvZmZzZXQ9IjAuMjEiIHN0b3AtY29sb3I9IiNFRDFFNzkiLz4KPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjNTIyNzg1Ii8+CjwvbGluZWFyR3JhZGllbnQ+CjxsaW5lYXJHcmFkaWVudCBpZD0icGFpbnQxX2xpbmVhcl8xMTBfNTcyIiB4MT0iMTIwLjY1IiB5MT0iNTUuNjAyMSIgeDI9IjgxLjIxMyIgeTI9IjIyLjM5MTQiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4KPHN0b3Agb2Zmc2V0PSIwLjIxIiBzdG9wLWNvbG9yPSIjRjE1QTI0Ii8+CjxzdG9wIG9mZnNldD0iMC42ODQxIiBzdG9wLWNvbG9yPSIjRkJCMDNCIi8+CjwvbGluZWFyR3JhZGllbnQ+CjwvZGVmcz4KPC9zdmc+Cg==",
    symbol: 'ckBTC',
    name: 'ckBTC',
    decimals: 8,
    fee: BigInt.from(10),
    ledger: Canister(Principal('mxzaz-hqaaa-aaaar-qaada-cai')),
    index: Canister(Principal('n5wcd-faaaa-aaaar-qaaea-cai'))
);


class Tokens extends Nat {
    BigInt get token_quantums => super.value;
    final int decimal_places;
    Tokens({required BigInt token_quantums, required this.decimal_places}) : super(token_quantums);
    String toString() {
        String s = this.token_quantums.toRadixString(10);
        while (s.length < this.decimal_places + 1) { s = '0$s'; }
        int split_i = s.length - this.decimal_places;
        s = '${s.substring(0, split_i)}.${s.substring(split_i)}';
        while (s[s.length - 1] == '0' && s[s.length - 2] != '.') { s = s.substring(0, s.length - 1); }
        return s;   
    }
    Tokens round_decimal_places(int round_decimal_places) {
        List<String> tokens_string_split = this.toString().split('.');
        if (tokens_string_split.length <= 1) {
            return this;
        }
        String decimal_places_string = tokens_string_split[1];
        if (round_decimal_places >= decimal_places_string.length) {
            return this;
        }
        String decimal_places_split_at_round = decimal_places_string.substring(0, round_decimal_places);
        return Tokens.oftheDoubleString('${tokens_string_split[0]}.${BigInt.parse(decimal_places_split_at_round)+BigInt.from(1)}', decimal_places: this.decimal_places);
    }
    static Tokens oftheNat(CandidType tokens_nat, {required int decimal_places}) {
        return Tokens(token_quantums: (tokens_nat as Nat).value, decimal_places: decimal_places);
    }
    static Tokens oftheDoubleString(String token_string, {required int decimal_places}) {
        token_string = token_string.trim();
        if (token_string == '') {
            throw Exception('must be a number');
        }
        List<String> token_string_split = token_string.split('.');
        if (token_string_split.length > 2) {
            throw Exception('invalid number.');
        } 
        BigInt whole_tokens = BigInt.parse(token_string_split[0]);
        BigInt tokens_less_than_1 = BigInt.from(0);        
        if (token_string_split.length == 2) {
            String token_string_decimal_places = token_string_split[1];     
            if (token_string_decimal_places.length > IcpTokens.DECIMAL_PLACES) {
                throw Exception('Max ${IcpTokens.DECIMAL_PLACES} decimal places for the IcpTokens');
            }
            while (token_string_decimal_places.length < IcpTokens.DECIMAL_PLACES) {
                token_string_decimal_places = '${token_string_decimal_places}0';
            }
            tokens_less_than_1 = BigInt.parse(token_string_decimal_places);
        }
        Tokens tokens = Tokens(token_quantums: (whole_tokens * BigInt.from(pow(10, decimal_places))) + tokens_less_than_1, decimal_places: decimal_places);
        return tokens;
    }
    BigInt get dividable_by => BigInt.from(pow(10, this.decimal_places));

    @override
    bool operator ==(/*covariant */ other) => other is Tokens && other.decimal_places == this.decimal_places && other.token_quantums == this.token_quantums;

    @override
    int get hashCode => this.token_quantums.toInt() + this.decimal_places;

}



class Icrc1Account extends Record {
    final Principal owner;
    final Uint8List subaccount; // 32 bytes
    Icrc1Account({required this.owner, Uint8List? subaccount}) : subaccount = subaccount == null ? Uint8List(32) : subaccount {
        /*
        if (subaccount != null) { 
            this.subaccount = subaccount; 
        } else {
            this.subaccount = Uint8List(32);
        } 
        */
        if (this.subaccount.length != 32) { throw Exception('icrc1 subaccount must be 32-bytes'); }
        
        this['owner'] = this.owner;
        this['subaccount'] = Blob(this.subaccount);
    }
    static Icrc1Account oftheRecord(Record r) {
        //print(r['subaccount'].runtimeType);
        Blob? b = r.find_option<Blob>('subaccount');
        Uint8List? subaccount = b == null ? null : b.bytes; 
        return Icrc1Account(
            owner: r['owner'] as Principal,
            subaccount: subaccount
        );
    } 
    static Icrc1Account oftheId(String icrc1_id) {
        Uint8List b = Principal(icrc1_id).bytes;
        if (b.last != final_byte) {
            return Icrc1Account(
                owner: Principal.oftheBytes(b)
            );
        } else {
            b.removeLast();
            int subaccount_length = b.removeLast();
            if (subaccount_length > 32 || subaccount_length == 0) { throw Exception('invalid account id'); }
            Uint8List subaccount = b.sublist(b.length - subaccount_length, b.length);
            Uint8List owner_bytes = b.sublist(0, b.length - subaccount_length);
            if (subaccount.first == 0) { throw Exception('invalid account id'); }
            subaccount = Uint8List.fromList([...Uint8List(32 - subaccount_length), ...subaccount]);
            return Icrc1Account(
                owner: Principal.oftheBytes(owner_bytes),
                subaccount: subaccount
            );
        }
    }
    String id() {
        if (aresamebytes(this.subaccount, Uint8List(32))) {
            return this.owner.text;
        }
        Uint8List subaccount_shrink = Uint8List.fromList(this.subaccount.toList());
        while (subaccount_shrink[0] == 0) { 
            subaccount_shrink.removeAt(0); 
        }
        Uint8List id_bytes = Uint8List.fromList([...this.owner.bytes, ...subaccount_shrink, subaccount_shrink.length, final_byte]);
        return Principal.oftheBytes(id_bytes).text;   
    }
    
    static const final_byte = 127; 
    
    @override
    bool operator ==(/*covariant */ other) => other is Icrc1Account && other.owner == this.owner && aresamebytes(other.subaccount, this.subaccount);

    @override
    int get hashCode => this.owner.hashCode + this.subaccount.hashCode;
    
}

