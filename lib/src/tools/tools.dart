import 'dart:typed_data';

export './leb128.dart';
export './cross_platform_tools/onthewebcheck/main.dart' show isontheweb;
export './cross_platform_tools/bls12381/main.dart' show bls12381;


Uint8List hexstringasthebytes(String hex) {
    List<int> bytes = [];
    if (hex.substring(0,2)=='0x' || hex.substring(0,2)=='\\x') {
        hex = hex.substring(2);
    }
    if (hex.length % 2 != 0) {
        throw Exception('hex string must be divisable by 2');
    }
    for (int i=0;i<hex.length/2;i++) {
        bytes.add(int.parse(hex.substring(i*2,i*2+2), radix: 16));
    }
    return Uint8List.fromList(bytes);
}

String bytesasahexstring(List<int> bytes) {
    String s = '';
    for (int i in bytes) {
        String st = i.toRadixString(16);
        if (st.length == 1) { st = '0'+st; }
        s += st;
    }
    return s;
}


bool aresamebytes(List<int> b1, List<int> b2) {
    if (b1.length != b2.length) {
        return false;
    }
    bool isqual = true;
    for (int i=0;i<b1.length; i++) {
        if (b1[i] != b2[i]) {
            isqual = false;
            break;
        }
    }
    return isqual;
}




String bigint_as_the_twos_compliment_bitstring(BigInt x, {required int bit_size}) { // bit_size can technically be BigInt or Int
    final BigInt max_size = BigInt.from(2).pow(bit_size-1)-BigInt.from(1);
    final BigInt min_size = -BigInt.from(2).pow(bit_size-1);
    if (x > max_size || x < min_size) {
        throw Exception('value must be >= ${min_size} and value <= ${max_size} for a ${bit_size} bit integers. ');
    }
    String bitstring = '';
    if (x >= BigInt.from(0)) {
        bitstring = x.toRadixString(2);
        while (bitstring.length < bit_size) { bitstring = '0' + bitstring; }
    }
    else if (x < BigInt.from(0)) {
        bitstring = '1';
        String bitstring_part2  =  (min_size.abs() - x.abs()).toRadixString(2);
        while (bitstring_part2.length < bit_size-1) { bitstring_part2 = '0' + bitstring_part2; }
        bitstring += bitstring_part2;
    }
    if (bitstring.length < bit_size) {
        throw Exception('something happen');
    }
    return bitstring;
}


BigInt twos_compliment_bitstring_as_the_bigint(String bit_string, {required int bit_size}) {
    final BigInt max_size = BigInt.from(2).pow(bit_size-1) - BigInt.from(1);
    final BigInt min_size = -BigInt.from(2).pow(bit_size-1);
    BigInt bit_string_number = BigInt.parse(bit_string, radix: 2);
    late BigInt bi;
    if (bit_string_number > max_size ) {
        bi = min_size + BigInt.parse(bit_string.substring(1), radix: 2);
    }
    else if (bit_string_number <= max_size ) {
        bi = bit_string_number;
    }
    if (bi > max_size || bi < min_size) {
        throw Exception(' value must be >= ${min_size} and value <= ${max_size} for a ${bit_size} bit integers. ');
    }
    return bi;
}

Uint8List bitstring_as_the_bytes(String bitstring) {
    if (bitstring.length % 8 != 0) {
        throw Exception('bitstring.length must be a multiple of 8 in this funcion');
    }
    List<int> bytes = [];
    for (int i=0;i<bitstring.length/8;i++) {
        bytes.add(int.parse(bitstring.substring(i*8,i*8+8), radix:2));
    }
    return Uint8List.fromList(bytes);
}


String bytes_as_the_bitstring(Iterable<int> bytes) {
    String bitstring = '';
    for (int byte in bytes) {
        String byte_bitstring = byte.toRadixString(2);
        while (byte_bitstring.length < 8) { byte_bitstring = '0' + byte_bitstring; }
        bitstring = bitstring + byte_bitstring;
    }
    return bitstring;
}


String bytesasabitstring(List<int> bytes) => bytes_as_the_bitstring(bytes); 





String get_typename_ofthe_toString(String str) => str.substring(13, str.length-1);



BigInt get_current_time_nanoseconds() {
    return BigInt.from(DateTime.now().millisecondsSinceEpoch) * BigInt.from(1000000);
}

BigInt get_current_time_seconds() {
    return BigInt.parse((BigInt.from(DateTime.now().millisecondsSinceEpoch) / BigInt.from(1000)).toString().split('.').first);
}

BigInt seconds_of_the_nanos(BigInt nanos) {
    return BigInt.parse((nanos / BigInt.from(1000000000)).toString().split('.').first);
}







extension NullMap<T> on T? {
    F? nullmap<F>(F Function(T) f) {
        if (this != null) {
            return f(this!);
        } else {
            return null;
        }
    }
}













