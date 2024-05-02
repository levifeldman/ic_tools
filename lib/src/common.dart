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
    static final Canister root        = Canister(Principal.text('r7inp-6aaaa-aaaaa-aaabq-cai'));
    /// The management canister.
    static final Canister management  = Canister(Principal.text('aaaaa-aa'));
    /// The ICP ledger canister.
    static final Canister ledger      = Canister(Principal.text('ryjl3-tyaaa-aaaaa-aaaba-cai'));
    /// The NNS governance canister.
    static final Canister governance  = Canister(Principal.text('rrkah-fqaaa-aaaaa-aaaaq-cai'));
    /// The cycles-minter-canister.
    ///
    /// Known for minting cycles and keeping the current ICP/XDR exchange rate.
    static final Canister cycles_mint = Canister(Principal.text('rkp4c-7iaaa-aaaaa-aaaca-cai'));
    /// The [Internet-Identity](https://identity.ic0.app) canister.
    static final Canister ii          = Canister(Principal.text('rdmx6-jaaaa-aaaaa-aaadq-cai'));
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
            Record.of_the_map({
                'account': Blob(hexstringasthebytes(icp_id))
            })
        ])
    );
    return IcpTokens.of_the_record(c_backwards(sponse_bytes)[0] as Record);
}

/// Returns the [Variant] response of this call - the `Result<Ok, Err>` variant. Check the ICP ledger's candid service file for the specific structure of this variant response to this call.
Future<Variant> transfer_icp(Caller caller, String fortheicpid, IcpTokens mount, {IcpTokens? fee, Nat64? memo, List<int>? subaccount_bytes}) async {
    fee ??= IcpTokens.of_the_double_string('0.0001');
    memo ??= Nat64(BigInt.from(0));
    subaccount_bytes ??= Uint8List(32);
    if (subaccount_bytes.length != 32) { throw Exception(': subaccount_bytes-parameter of this function is with the length-quirement: 32-bytes.'); }

    Record sendargs = Record.of_the_map({
        'to' : Blob(hexstringasthebytes(fortheicpid)),        
        'memo': memo,
        'amount': mount,
        'fee': fee,
        'from_subaccount': Option<Blob>(value: Blob(subaccount_bytes)),
        'created_at_time': Option<Record>(value: Record.of_the_map({
            'timestamp_nanos' : Nat64(get_current_time_nanoseconds())
        }))
    });
    Variant transfer_result = c_backwards(await SYSTEM_CANISTERS.ledger.call(calltype: CallType.call, method_name: 'transfer', put_bytes: c_forwards([sendargs]), caller: caller))[0] as Variant;
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
    return Principal.bytes(Uint8List.fromList(principal_bytes));
}

Map<String, Never Function(CandidType)> transfer_error_match_map = {
    'TxTooOld' : (allowed_window_nanos_r) {
        throw Exception('TxTooOld');
    },
    'BadFee' : (expected_fee_r) {
        throw Exception('BadFee, expected_fee: ${IcpTokens.of_the_record((expected_fee_r as Record)['expected_fee'] as Record)}');
    },
    'TxDuplicate' : (duplicate_of_r) {
        throw Exception('TxDuplicate, duplicate_of: ${((duplicate_of_r as Record)['duplicate_of'] as Nat64).value}');
    },
    'TxCreatedInFuture': (nul) {
        throw Exception('TxCreatedInFuture');
    },
    'InsufficientFunds' : (balance_r) {
        throw Exception('InsufficientFunds, balance: ${IcpTokens.of_the_record((balance_r as Record)['balance'] as Record)}');
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
Future<Principal> create_canister(Caller caller, IcpTokens icp_tokens, {Uint8List? from_subaccount_bytes, Nat64? block_height, String? subnet_type}) async {
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

    Record notifycanisterarg = Record.of_the_map({
        'controller' : caller.principal,
        'block_index' : block_height,
        'subnet_type': Option<Text>(value: subnet_type.nullmap((st)=>Text(st)), value_type: Text()) 
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

    Record notifytopupargs = Record.of_the_map({
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
            Record.of_the_map({
                'canister_id': canister_id }) ]) 
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
    canister_status_map['settings']['controllers'] = (settings_record['controllers'] as Vector).cast<Principal>();
    canister_status_map['settings']['compute_allocation'] = (settings_record['compute_allocation'] as Nat).value;
    canister_status_map['settings']['memory_allocation'] = (settings_record['memory_allocation'] as Nat).value;
    canister_status_map['settings']['freezing_threshold'] = (settings_record['freezing_threshold'] as Nat).value;
    // module_hash
    Option optional_module_hash = canister_status_record['module_hash'] as Option;
    canister_status_map['module_hash'] = optional_module_hash.value != null ? Blob.of_the_vector_nat8((optional_module_hash.value as Vector).cast_vector<Nat8>()).bytes : null;
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
            Record.of_the_map({
                'mode': Variant.of_the_map({mode.name: Null()}),
                'canister_id': canister_id,
                'wasm_module': Blob(wasm_module),
                'arg': canister_install_arg != null ? Blob(canister_install_arg) : Blob([])
            })
        ])
    );
}




/// Create a canister in the local environment.
///
/// https://internetcomputer.org/docs/current/references/ic-interface-spec/#ic-provisional_create_canister_with_cycles
Future<Principal> provisional_create_canister_with_cycles({required Caller caller, BigInt? cycles, Record? canister_settings, Principal? specified_id}) async {
    return (c_backwards_one(await SYSTEM_CANISTERS.management.call(
        method_name: 'provisional_create_canister_with_cycles',
        caller: caller,
        calltype: CallType.call,
        put_bytes: c_forwards_one(
            Record.of_the_map({
                if (cycles != null) 'amount': Option(value: Nat(cycles)),
                if (canister_settings != null) 'settings': Option(value: canister_settings),
                if (specified_id != null) 'specified_id': Option(value: specified_id),
            })
        ),
    )) as Record)['canister_id'] as Principal;
}

/// Top up the cycles of a canister in the local environment.
///
/// https://internetcomputer.org/docs/current/references/ic-interface-spec/#ic-provisional_top_up_canister 
Future<void> provisional_top_up_canister(Principal canister_id, BigInt cycles) async {
    await SYSTEM_CANISTERS.management.call(
        method_name: 'provisional_top_up_canister',
        calltype: CallType.call,
        put_bytes: c_forwards_one(
            Record.of_the_map({
                'canister_id': canister_id,
                'amount': Nat(cycles),
            })
        ),
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
        return IcpTokens.of_the_double_string('${icp_string_split[0]}.${decimal_places_split_at_round}');
    }
    static IcpTokens of_the_record(CandidType icptokensrecord) {
        Nat64 e8s_nat64 = (icptokensrecord as Record)['e8s'] as Nat64; 
        return IcpTokens(
            e8s: e8s_nat64.value
        );
    }
    static IcpTokens of_the_double_string(String icp_string) {
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
    Tokens get fee_tokens => Tokens(quantums: fee, decimal_places: decimals);
    final String? logo_data_url;
    
    Icrc1Ledger({
        required this.ledger, 
        required this.symbol, 
        required this.name, 
        required this.decimals, 
        required this.fee, 
        this.logo_data_url,
    });
    
    static Future<Icrc1Ledger> load(Principal icrc1_ledger_id, [CallType calltype = CallType.query]) async {
        Canister icrc1_ledger = Canister(icrc1_ledger_id);
        Vector<Record> metadata = (c_backwards(await icrc1_ledger.call(
            method_name: 'icrc1_metadata',
            calltype: calltype,
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
    static List<Icrc1Ledger> all = [ICP];    
}
final Icrc1Ledger _ICP = Icrc1Ledger(
    //logo_data_url: ,
    symbol: 'ICP',
    name:'Internet Computer',
    decimals:8,
    fee:BigInt.from(10000),
    ledger: SYSTEM_CANISTERS.ledger
);


class Tokens extends Nat {
    BigInt get quantums => super.value;
    final int decimal_places;
    Tokens({required BigInt quantums, required this.decimal_places}) : super(quantums);
    String toString() {
        String s = this.quantums.toRadixString(10);
        while (s.length < this.decimal_places + 1) { s = '0$s'; }
        int split_i = s.length - this.decimal_places;
        s = '${s.substring(0, split_i)}.${s.substring(split_i)}';
        //while (s[s.length - 1] == '0' && s[s.length - 2] != '.') { s = s.substring(0, s.length - 1); }
        while (['0','.'].contains(s[s.length - 1])) { 
            bool brk = false;
            if (s[s.length - 1] == '.') { brk = true; }
            s = s.substring(0, s.length - 1);
            if (brk) { break; }
        }
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
        return Tokens.of_the_double_string('${tokens_string_split[0]}.${decimal_places_split_at_round}', decimal_places: this.decimal_places);
    }
    Tokens add_quantums(BigInt add_quantums) {
        return Tokens(quantums: this.quantums + add_quantums, decimal_places: this.decimal_places);
    }
    static Tokens of_the_nat(CandidType tokens_nat, {required int decimal_places}) {
        return Tokens(quantums: (tokens_nat as Nat).value, decimal_places: decimal_places);
    }
    static Tokens of_the_double_string(String token_string, {required int decimal_places}) {
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
        Tokens tokens = Tokens(quantums: (whole_tokens * BigInt.from(pow(10, decimal_places))) + tokens_less_than_1, decimal_places: decimal_places);
        return tokens;
    }
    BigInt get dividable_by => BigInt.from(pow(10, this.decimal_places));

    @override
    bool operator ==(/*covariant */ other) => other is Tokens && other.decimal_places == this.decimal_places && other.quantums == this.quantums;

    @override
    int get hashCode => this.quantums.toInt() + this.decimal_places;
    
    // comparison and arithmetic operators are no good bc decimal places can be different for different Tokens
}



class Icrc1Account extends Record {
    final Principal owner;
    final Uint8List subaccount; // 32 bytes
    Icrc1Account({required this.owner, Uint8List? subaccount}) : subaccount = subaccount == null ? Uint8List(32) : subaccount {
        
        if (this.subaccount.length != 32) { throw Exception('icrc1 subaccount must be 32-bytes'); }
        
        this['owner'] = this.owner;
        this['subaccount'] = Blob(this.subaccount);
    }
    static Icrc1Account of_the_record(Record r) {
        Vector? blob = r.find_option<Vector>('subaccount');
        Uint8List? subaccount = blob.nullmap((v)=>Blob.of_the_vector_nat8(v.cast_vector<Nat8>()).bytes); 
        return Icrc1Account(
            owner: r['owner'] as Principal,
            subaccount: subaccount
        );
    }
    static Icrc1Account of_the_id(String icrc1_id) {
        
        if (icrc1_id.contains('.') == false) {
            return Icrc1Account(owner: Principal.text(icrc1_id));
        }
        List<String> id_split_period = icrc1_id.split('.');
        if (id_split_period.length > 2) {
            throw Exception('invalid icrc1-id.');
        }
        
        String subaccount_hex = id_split_period.last;
        while (subaccount_hex.length < 64) { subaccount_hex = '0' + subaccount_hex; } 
        Uint8List subaccount = hexstringasthebytes(subaccount_hex);
        
        String principal_and_checksum = id_split_period.first;
        Principal principal = Principal.text(principal_and_checksum.substring(0, principal_and_checksum.lastIndexOf('-')));
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


