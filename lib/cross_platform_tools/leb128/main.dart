import 'dart:typed_data';
import 'package:leb128/leb128.dart';
import '../../tools.dart';

import 'stub.dart'
    if (dart.library.io) 'leb128_dart.dart'
    if (dart.library.js) 'leb128_js.dart';




abstract class Leb128Flutter {

    Uint8List encodeUnsigned(x) {
        if (!(x is int) && !(x is BigInt)) {
            throw Exception('leb128 encodeunsigned have either an int or a BigInt.');
        }
        if (!(x is BigInt)) { x = BigInt.from(x); }
        if (x < BigInt.from(0)) {
            throw Exception('leb128 encode unsigned variable must be >= 0');
        }
        String bitstring = x.toRadixString(2);
        while (bitstring.length % 7 != 0) {
            bitstring = '0' + bitstring;
        }
        List<String> bit_groups_7 = [];
        for (int i=0;i<bitstring.length / 7; i++) {
            String bit_group_7 = bitstring.substring(i*7, i*7+7);
            
            String put_high_bit = i==0 ? '0' : '1';  
            bit_groups_7.add(put_high_bit + bit_group_7);
        }
        List<int> leb128_bytes = [];
        for (String bit_group_7 in bit_groups_7.reversed) {
            leb128_bytes.add(int.parse(bit_group_7, radix:2));
        }
        return Uint8List.fromList(leb128_bytes);
    }

    // :give-back: BigInt or int
    dynamic decodeUnsigned(List<int> bytes) {
        String bitstring = '';
        bitstring += bytes[bytes.length-1].toRadixString(2);
        for (int byte in bytes.reversed.toList().sublist(1)) {
            String bitstring_7_part = byte.toRadixString(2).substring(1);
            if (bitstring_7_part.length != 7) { throw Exception('look at this, seems leb128 byte is with the wrong-code?'); }
            bitstring = bitstring + bitstring_7_part;
        }
        dynamic givebackvaluebigint = BigInt.parse(bitstring, radix: 2);
        return givebackvaluebigint.isValidInt ? givebackvaluebigint.toInt() : givebackvaluebigint;
    }

    // Uint8List encodeSigned(x);

    Uint8List encodeSigned(x) {
        if (!(x is int) && !(x is BigInt)) {
            throw Exception('leb128 encodesigned have either an int or a BigInt.');
        }
        if (!(x is BigInt)) { x = BigInt.from(x); }

        late String tc_bitstring;
        if (x < BigInt.from(0)) {
            int bit_size = x.abs().toRadixString(2).length + 1; // + 1 for the sign-bit
            while (bit_size % 7 != 0) { bit_size += 1; }
            tc_bitstring = integers_as_the_twos_compliment_bitstring(x, bit_size: bit_size);
        }
        else if (x >= BigInt.from(0)) {
            tc_bitstring = '0' + x.toRadixString(2); // '0' +  for the sign-bit
        }
        while (tc_bitstring.length % 7 != 0) { tc_bitstring = '0' + tc_bitstring; }
        List<String> bytes_bitstrings = [];
        for (int i=0; i < tc_bitstring.length / 7;i++) {
            String put_high_bit = i==0 ? '0' : '1';  
            bytes_bitstrings.add( put_high_bit + tc_bitstring.substring(i*7, i*7+7));
        }
        List<int> bytes = bytes_bitstrings.map((String byte_bitstring)=>int.parse(byte_bitstring, radix:2)).toList();
        return Uint8List.fromList(bytes.reversed.toList());        
    }

    dynamic decodeSigned(bytes) {
        String bitstring = '';
        bitstring += bytes[bytes.length-1].toRadixString(2);
        for (int byte in bytes.reversed.toList().sublist(1)) {
            String bitstring_7_part = byte.toRadixString(2).substring(1);
            bitstring = bitstring + bitstring_7_part;
        }


        dynamic givebackvaluebigint = BigInt.parse(bitstring, radix: 2);
        
        
        // return tc_int.isValidInt ? tc_int.toInt() : tc_int;
    }
    
}


Leb128Flutter leb128flutter = getLeb128Lib(); 

