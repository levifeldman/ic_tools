import 'dart:typed_data';
import 'dart:convert';

import 'package:cryptography/dart.dart';
import 'package:archive/archive.dart';

import 'ic_tools.dart';
import 'candid.dart';
import 'tools.dart';


int check_double_decimal_point_places(double d) => d.toString().substring(d.toString().indexOf('.') + 1).length;




Canister ledger = Canister(Principal('ryjl3-tyaaa-aaaaa-aaaba-cai'));


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

Future<double> check_icp_balance(String ICPID) async {
    Record record = Record.fromMap({'account': Text(ICPID)});
    Uint8List sponse_bytes = await ledger.call(calltype: 'call', methodName: 'account_balance_dfx', put_bytes: c_forwards([record]));
    Record icp_balance_record = c_backwards(sponse_bytes)[0] as Record;
    Nat64 e8s_nat64 = icp_balance_record['e8s'] as Nat64;
    return e8s_nat64.value / 100000000;
 
}

Future<CandidType> send_icp(Caller caller, String fortheicpid, double send_mount, {double? fee, List<int>? subaccount_bytes } ) async {
    fee ??= 0.0001; // what is the method for the calculation of this fee?
    if (check_double_decimal_point_places(send_mount) > 8 || check_double_decimal_point_places(fee) > 8) {
        throw Exception('send_mount and fee can have max: 8 decimal-point-number-places');
    }
    Record sendargs = Record.fromMap({
        'memo': Nat64(123),
        'amount': Record.fromMap({
            'e8s': Nat64( (send_mount * 100000000).toInt() ) // e8s is a nat64 number that needs to be divided by 100000000
        }),
        'fee': Record.fromMap({
            'e8s': Nat64( (fee * 100000000).toInt() )
        }),
        // 'from_subaccount': Option(),
        'to': Text(fortheicpid),
        // 'created_at_time': Option()
    });    
    return c_backwards(await ledger.call(calltype: 'call', methodName: 'send_dfx', put_bytes: c_forwards([sendargs]), caller: caller))[0]; 
}
