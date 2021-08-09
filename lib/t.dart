import 'dart:typed_data';
import 'dart:math';
import 'package:cbor/cbor.dart';
import 'tools.dart';
import 'ic_tools.dart';
import 'candid.dart';
import 'dart:convert';
import 'cross_platform_tools/cross_platform_tools.dart';
import 'package:cryptography/dart.dart';
import 'package:archive/archive.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

import 'icp.dart';



Future<void> main() async {
    await ictest();    
}



Future<void> ictest() async {
    print('trying ic');
    
    // Uint8List subaccount_bytes = Uint8List(32);


    CallerEd25519 caller = CallerEd25519(public_key: Uint8List.fromList([45, 252, 83, 141, 240, 212, 250, 146, 217, 180, 96, 138, 121, 242, 236, 85, 211, 65, 239, 231, 172, 176, 160, 66, 21, 238, 13, 114, 136, 128, 208, 109]), private_key: Uint8List.fromList([169, 212, 147, 120, 21, 161, 122, 213, 23, 151, 91, 115, 66, 204, 230, 203, 139, 12, 241, 243, 74, 195, 172, 239, 7, 6, 244, 68, 51, 72, 114, 7]));
    String icp_count_id = principal_as_an_IcpCountId(caller.principal);
    print(icp_count_id);
    print(await check_icp_balance(icp_count_id));
    print(await send_icp(caller, '1df5c5b4f8042c2748238f6fa841b9d743f982691f6c3e84454288a8586804f5', 0.0098));
    print(await check_icp_balance(icp_count_id));


    // var keypair = ed25519.generateKey();
    // print('pr: ${keypair.privateKey.bytes}');
    // print('pub: ${keypair.publicKey.bytes}');

    // var principal = sha224.convert([45, 252, 83, 141, 240, 212, 250, 146, 217, 180, 96, 138, 121, 242, 236, 85, 211, 65, 239, 231, 172, 176, 160, 66, 21, 238, 13, 114, 136, 128, 208, 109]);
    // print(principal.bytes);
    // print(icidblobasatext(Uint8List.fromList([105, 189, 111, 216, 24, 77, 137, 202, 205, 121, 182, 162, 188, 175, 202, 246, 92, 113, 188, 5, 215, 151, 31, 87, 172, 217, 91, 26, 2])));

}


