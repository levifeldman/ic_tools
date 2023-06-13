import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:base32/base32.dart';

import './ic_tools.dart';
import './candid.dart';
import './tools/tools.dart';

/// Common NNS canisters.
class SYSTEM_CANISTERS {
    /// The system root canister.
    static final Canister root        = Canister(Principal('r7inp-6aaaa-aaaaa-aaabq-cai'));
    /// The management canister.
    static final Canister management  = Canister(Principal('aaaaa-aa'));
    /// The ICP ledger canister.
    static final Canister ledger      = Canister(Principal('ryjl3-tyaaa-aaaaa-aaaba-cai'));
    /// The NNS governance canister.
    static final Canister governance  = Canister(Principal('rrkah-fqaaa-aaaaa-aaaaq-cai'));
    /// The cycles-minter-canister.
    ///
    /// Known for minting cycles and keeping the current ICP/XDR exchange rate.
    static final Canister cycles_mint = Canister(Principal('rkp4c-7iaaa-aaaaa-aaaca-cai'));
    /// The [Internet-Identity](https://identity.ic0.app) canister.
    static final Canister ii          = Canister(Principal('rdmx6-jaaaa-aaaaa-aaadq-cai'));
}


/// Convenient variable for the `Ok` variant when handling `Result<Ok,Err>` [Variant]s.
const String Ok  = 'Ok';
/// Convenient variable for the `Err` variant when handling `Result<Ok,Err>` [Variant]s.
const String Err = 'Err';





Future<IcpTokens> check_icp_balance(String icp_id, {CallType? calltype}) async {
    Uint8List sponse_bytes = await SYSTEM_CANISTERS.ledger.call(
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

/// Returns the [Variant] response of this call - the `Result<Ok, Err>` variant. Check the ICP ledger's candid service file for the specific structure of this variant response to this call.
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
    Variant transfer_result = c_backwards(await SYSTEM_CANISTERS.ledger.call(calltype: CallType.call, method_name: 'transfer', put_bytes: c_forwards([sendargs]), caller: caller, legations: legations))[0] as Variant;
    return transfer_result;
}



/// This function computes the textual ICP-account-identifier of a [Principal] account owner and an optional 32-bytes subaccount. 
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

/// Creates a canister using the NNS ledger and the cycles-minting-canister.
///
/// Returns the new canister's [Principal].
/// 
/// Transforms the [icp_tokens] into cycles for the canister.
/// 
/// Use an optional [from_subaccount_bytes] to use ICP in a subaccount of the [caller].
///
/// This function makes two calls. One for the ICP ledger to transfer ICP-tokens to the cycles-minter-canister's account, 
/// and one for the cycles-minter-canister to trigger it to use that ICP to create a canister with cycles.
/// A scenario can occur where the first call to transfer ICP-tokens can succeed but the second call to notify the cycles-minter-canister can fail (due to network load or similar).     
/// In this scenario, this function will print the `Nat64(block_height)` of the first ICP-transfer call.
/// Use the [block_height] of the first call to complete this canister-creation by calling this function again with the same [caller] and [from_subaccount_bytes] and with the [block_height] parameter.
/// 
/// When the [block_height] is not given, this function will make a new icp-transfer.
/// When the [block_height] is given, this function will skip the first icp-transfer call, and will call the cycles-minter-canister with the given [block_height]. 
Future<Principal> create_canister(Caller caller, IcpTokens icp_tokens, {Uint8List? from_subaccount_bytes, Nat64? block_height}) async {
    Uint8List to_subaccount_bytes = principal_as_an_icpsubaccountbytes(caller.principal);
    
    if (block_height == null) {
        block_height = match_variant<Nat64>(await transfer_icp(
            caller, 
            icp_id(SYSTEM_CANISTERS.cycles_mint.principal, subaccount_bytes: to_subaccount_bytes), 
            icp_tokens, 
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

    Variant notify_create_canister_result = c_backwards(await SYSTEM_CANISTERS.cycles_mint.call(
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


/// Top-up the cycles on a canister with some ICP using the NNS ledger and the cycles-minting-canister.
///
/// Returns the amount of the cycles that the canister is topped up with.
/// 
/// Transforms the [icp_tokens] into cycles for the canister.
/// 
/// Use an optional [from_subaccount_bytes] to use ICP in a subaccount of the [caller].
///
/// The [block_height] parameter has the same usage as in the [create_canister] function. 
/// Check the documentation for the [create_canister] function about the [block_height] parameter.
Future<Nat> top_up_canister(Caller caller, IcpTokens icp_tokens, Principal canister_id, {Uint8List? from_subaccount_bytes, Nat64? block_height}) async {
    Uint8List to_subaccount_bytes = principal_as_an_icpsubaccountbytes(canister_id);

    if (block_height == null) {
        block_height = match_variant<Nat64>(await transfer_icp(
            caller, 
            icp_id(SYSTEM_CANISTERS.cycles_mint.principal, subaccount_bytes: to_subaccount_bytes), 
            icp_tokens, 
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

    Variant notify_top_up_result = c_backwards(await SYSTEM_CANISTERS.cycles_mint.call(
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


/// Returns a status map for the convenience using the `canister_status` method on the management canister.
/// 
/// The [caller] must be a controller of the [canister_id].
Future<Map> check_canister_status(Caller caller, Principal canister_id) async {
    Uint8List canister_status_sponse_bytes = await SYSTEM_CANISTERS.management.call(
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


enum CanisterInstallMode {
    install,
    reinstall,
    upgrade
}

/// Installs the [wasm_module] onto the [canister_id] using the management canister's `install_code` method.
/// WARNING: This function does not stop or start the canister. If your canister needs to be stopped before upgrading, 
/// make sure to call the management canister's `stop_canister` method before calling this function.
///
/// The [caller] must be a controller of the [canister_id].
Future<void> put_code_on_the_canister(Caller caller, Principal canister_id, Uint8List wasm_module, CanisterInstallMode mode, [Uint8List? canister_install_arg]) async {
    await SYSTEM_CANISTERS.management.call(
        caller: caller,
        calltype: CallType.call,
        method_name: 'install_code',
        put_bytes: c_forwards([
            Record.oftheMap({
                'mode': Variant.oftheMap({mode.name: Null()}),
                'canister_id': canister_id.candid,
                'wasm_module': Blob(wasm_module),
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
    static Icrc1Ledger CHAT = _CHAT;
    static List<Icrc1Ledger> all = [ICP,SNS1,ckBTC,CHAT];
}
final Icrc1Ledger _ICP = Icrc1Ledger(
    //logo_data_url: ,
    symbol: 'ICP',
    name:'Internet Computer',
    decimals:8,
    fee:BigInt.from(10000),
    ledger: SYSTEM_CANISTERS.ledger
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
final Icrc1Ledger _CHAT = Icrc1Ledger(
    logo_data_url: "data:image/png;base64,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",
    symbol: 'CHAT',
    name: 'CHAT',
    decimals: 8,
    fee: BigInt.from(100000),
    ledger: Canister(Principal('2ouva-viaaa-aaaaq-aaamq-cai')),
    index: Canister(Principal('2awyi-oyaaa-aaaaq-aaanq-cai'))
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
            if (token_string_decimal_places.length > decimal_places) {
                throw Exception('Max ${decimal_places} decimal places');
            }
            while (token_string_decimal_places.length < decimal_places) {
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
        
        if (this.subaccount.length != 32) { throw Exception('icrc1 subaccount must be 32-bytes'); }
        
        this['owner'] = this.owner;
        this['subaccount'] = Blob(this.subaccount);
    }
    static Icrc1Account oftheRecord(Record r) {
        Blob? blob = r.find_option<Blob>('subaccount');
        Uint8List? subaccount = blob.nullmap((b)=>b.bytes); 
        return Icrc1Account(
            owner: r['owner'] as Principal,
            subaccount: subaccount
        );
    } 
    static Icrc1Account oftheId(String icrc1_id) {
        
        if (icrc1_id.contains('.') == false) {
            return Icrc1Account(owner: Principal(icrc1_id));
        }
        List<String> id_split_period = icrc1_id.split('.');
        if (id_split_period.length > 2) {
            throw Exception('invalid icrc1-id.');
        }
        
        String subaccount_hex = id_split_period.last;
        while (subaccount_hex.length < 64) { subaccount_hex = '0' + subaccount_hex; } 
        Uint8List subaccount = hexstringasthebytes(subaccount_hex);
        
        String principal_and_checksum = id_split_period.first;
        Principal principal = Principal(principal_and_checksum.substring(0, principal_and_checksum.lastIndexOf('-')));
        String checksum_base32 = principal_and_checksum.substring(principal_and_checksum.lastIndexOf('-')+1);
        if (checksum_base32.length%2!=0) { checksum_base32+='='; } // add padding for the decode function
        List<int> checksum = base32.decode(checksum_base32);
        
        Crc32 crc32 = Crc32();
        crc32.add(principal.bytes);
        crc32.add(subaccount);
        List<int> calculate_crc32 = crc32.close();
        if (aresamebytes(checksum, calculate_crc32) == false) {
            throw Exception('crc32 checksum is invalid.');
        }
        
        return Icrc1Account(
            owner: principal,
            subaccount: subaccount
        );
    }
    
    String id() {
        if (aresamebytes(this.subaccount, Uint8List(32))) {
            return this.owner.text;
        }
        
        Crc32 crc32 = Crc32();
        crc32.add(this.owner.bytes);
        crc32.add(this.subaccount);
        Uint8List calculate_crc32 = Uint8List.fromList(crc32.close());
        String checksum_fmt = base32.encode(calculate_crc32);
        if (checksum_fmt.contains('=')) { checksum_fmt = checksum_fmt.substring(0, checksum_fmt.indexOf('=')); } // remove padding
        
        String subaccount_fmt = bytesasahexstring(this.subaccount);
        while (subaccount_fmt[0] == '0') { subaccount_fmt = subaccount_fmt.substring(1); }
        
        return '${owner.text}-${checksum_fmt}.${subaccount_fmt}'.toLowerCase();
    }
    
    String toString() => this.id();
    
    @override
    bool operator ==(/*covariant */ other) => other is Icrc1Account && other.owner == this.owner && aresamebytes(other.subaccount, this.subaccount);

    @override
    int get hashCode => this.owner.hashCode + this.subaccount.hashCode;
    
}

Future<BigInt> check_icrc1_balance({required Principal ledger_canister_id, required Icrc1Account account, required CallType calltype}) async {
    BigInt balance = (c_backwards(await Canister(ledger_canister_id).call(
        method_name: 'icrc1_balance_of',
        put_bytes: c_forwards([account]),
        calltype: calltype
    )).first as Nat).value;
    return balance;
}


