import 'dart:typed_data';
import 'dart:math';
import 'package:cbor/cbor.dart';
import 'tools.dart';
import 'ic_tools.dart';
import 'candid.dart';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed25519;
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'cross_platform_tools/cross_platform_tools.dart';
import 'package:leb128/leb128.dart';



Future<void> main() async {
    await ictest();    
}



Future<void> ictest() async {
    print('trying ic');
    Canister can = Canister(Principal('ryjl3-tyaaa-aaaaa-aaaba-cai'));
    Record record = Record.fromMap({'account': Text('c50accaa515fe677f04d6a608d306dce10ed0d46048aa5105cb549256f3c4433')});
    Uint8List sponse_bytes = await can.call(calltype: 'call', methodName: 'account_balance_dfx', put_bytes: c_forwards([record])); // List<CandidType>
    List<CandidType> candids = c_backwards(sponse_bytes);
    print(candids);
    Record rec = candids[0] as Record;
    // print(rec['e8s']);


// variant isTypeStance=falsec can  only contain one map item

    //leb128 test
    // BigInt bi = BigInt.parse('10010001010110', radix:2); // BigInt.parse('-6244888888885', radix: 10);
    // print(bi);
    // print(leb128flutter.encodeSigned(bi));
    // print(Leb128.encodeSigned(bi.toInt()));
    // Uint8List b_u8_l = Uint8List.fromList([214, 200, 0]);
    // print(leb128flutter.decodeSigned(b_u8_l));
    // print(Leb128.decodeSigned(b_u8_l));
    
    // print(leb128flutter.decodeSigned(Uint8List.fromList([181, 140, 137, 131, 224, 181, 1])));

    // test this number: BigInt.parse('-10010001010110', radix:2)



    // print(Leb128.encodeSigned(bi.toInt()))

    // print('\nparsing test candidbytes: ');
    // // Uint8List candidbytes = Uint8List.view(hexToBytes('4449444C016C01800175020071DEADBEEF03466F6F')!);
    // // Uint8List candidbytes = Uint8List.view(hexToBytes('4449444c046c04efd6e40271e1edeb4a71a2f5ed880401c6a4a19806026d7b6d036c02007101710100012f03474554001104686f7374276663686f732d65616161612d61616161652d6161616f712d6361692e7261772e6963302e61707009782d7265616c2d69700c3230392e362e36352e3130350f782d666f727761726465642d666f720c3230392e362e36352e31303511782d666f727761726465642d70726f746f0568747470730a636f6e6e656374696f6e05636c6f73650a757365722d6167656e74444d6f7a696c6c612f352e3020285831313b204c696e7578207838365f36343b2072763a39302e3029204765636b6f2f32303130303130312046697265666f782f39302e30066163636570744a746578742f68746d6c2c6170706c69636174696f6e2f7868746d6c2b786d6c2c6170706c69636174696f6e2f786d6c3b713d302e392c696d6167652f776562702c2a2f2a3b713d302e380f6163636570742d6c616e67756167650e656e2d55532c656e3b713d302e350f6163636570742d656e636f64696e6711677a69702c206465666c6174652c20627203646e74013107726566657265723068747470733a2f2f66786137372d66696161612d61616161652d6161616e612d6361692e7261772e6963302e6170702f19757067726164652d696e7365637572652d726571756573747301310e7365632d66657463682d6465737408646f63756d656e740e7365632d66657463682d6d6f6465086e617669676174650e7365632d66657463682d736974650973616d652d736974650e7365632d66657463682d75736572023f3106636f6f6b696583015f67615f33314c373544534e59433d4753312e312e313632353533343230352e34322e302e313632353533343230352e303b205f67613d4741312e312e3238333636313535342e313632313338303933383b205f67615f35504d56334b533330573d4753312e312e313632353433333032332e372e312e313632353433333432342e30')!);
    // Uint8List candidbytes = Uint8List.view(hexToBytes('4449444c016b04efd6e40271e1edeb4a72a2f5ed880473c6a4a1980674010000044449444c')!);
    // List candidsponse = candidsponsebytesasthedarttypes(candidbytes);
    // print(candidsponse);
    // print(candidsponse[0].runtimeType);

    // var keypair = ed25519.generateKey();
    // print('pr: ${keypair.privateKey.bytes}');
    // print('pub: ${keypair.publicKey.bytes}');

    // var principal = sha224.convert([45, 252, 83, 141, 240, 212, 250, 146, 217, 180, 96, 138, 121, 242, 236, 85, 211, 65, 239, 231, 172, 176, 160, 66, 21, 238, 13, 114, 136, 128, 208, 109]);
    // print(principal.bytes);
    // print(icidblobasatext(Uint8List.fromList([105, 189, 111, 216, 24, 77, 137, 202, 205, 121, 182, 162, 188, 175, 202, 246, 92, 113, 188, 5, 215, 151, 31, 87, 172, 217, 91, 26, 2])));


}


