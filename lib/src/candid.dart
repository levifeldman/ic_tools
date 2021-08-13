
// We assume that the fields in a record or variant type are sorted by increasing id and the methods in a service are sorted by name.

import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';
import 'dart:math';

import 'package:tuple/tuple.dart';

import './tools/tools.dart';



final Uint8List magic_bytes = Uint8List.fromList(utf8.encode('DIDL')); //0x4449444C



typedef CandidBytes_i = int;     
typedef TfuncTuple = Tuple2<CandidType,CandidBytes_i>; // T_backward gives back a CandidType-stance with isTypeStance=true for the M_backwards-function. and a Candidbytes_i for non-primitive-types
typedef MfuncTuple = Tuple2<CandidType,CandidBytes_i>; // M_backward gives back a CandidType-stance with the values and a Candidbytes_i




final Map<int, PrimitiveCandidType> backwards_primtypes_opcodes_for_the_primtype_type_stances = { //PrimitiveCandidType is with isTypeStance = true; 
    Null.type_code     : Null(),
    Bool.type_code     : Bool(),
    Nat.type_code      : Nat(),
    Int.type_code      : Int(),
    Nat8.type_code     : Nat8(),
    Nat16.type_code    : Nat16(),
    Nat32.type_code    : Nat32(),
    Nat64.type_code    : Nat64(),
    Int8.type_code     : Int8(),
    Int16.type_code    : Int16(),
    Int32.type_code    : Int32(),
    Int64.type_code    : Int64(),
    Float32.type_code  : Float32(),
    Float64.type_code  : Float64(),
    Text.type_code     : Text(),
    Reserved.type_code : Reserved(),
    Empty.type_code    : Empty(),
};

// static T_backwards functions start_i starts after the type_code-signed-leb128bytes

final Map<int, TfuncTuple Function(Uint8List candidbytes, CandidBytes_i start_i)> constypes_and_reftypes_opcodes_for_the_static_T_backwards_function = {
    Option.type_code  : Option.T_backward,
    Vector.type_code  : Vector.T_backward,
    Record.type_code  : Record.T_backward,
    Variant.type_code : Variant.T_backward,
    FunctionReference.type_code : FunctionReference.T_backward,
    ServiceReference.type_code  : ServiceReference.T_backward,
    PrincipalReference.type_code: PrincipalReference.T_backward
};

bool isPrimTypeCode(int type_code) => backwards_primtypes_opcodes_for_the_primtype_type_stances.keys.contains(type_code);
bool isConsOrRefTypeCode(int type_code) => constypes_and_reftypes_opcodes_for_the_static_T_backwards_function.keys.contains(type_code);




int candid_text_hash(String text) { 
    // hash(id) = ( Sum_(i=0..k) utf8(id)[i] * 223^(k-i) ) mod 2^32 where k = |utf8(id)|-1
    int hash = 0;
    for (int b in utf8.encode(text)) {
        hash = (hash * 223 + b) % pow(2, 32) as int;  
    }
    return hash as int;
}




// backwards

List<CandidType> type_table = []; 

class TypeTableReference extends CandidType { 
    final bool isTypeStance = true;
    int type_table_i; 
    late MfuncTuple Function(Uint8List candidbytes, CandidBytes_i start_i) m;
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) => m(candidbytes, start_i);
    TypeTableReference(this.type_table_i) {
        m = (Uint8List candidbytes, CandidBytes_i start_i) => type_table[type_table_i].M(candidbytes, start_i);
    }

    Uint8List T_forward() => throw Exception('shouldnt be calle');
    Uint8List M_forward() => throw Exception('shouldnt-call');
}

TfuncTuple crawl_type_table_whirlpool(Uint8List candidbytes, CandidBytes_i type_code_start_candidbytes_i) {
    FindLeb128BytesTuple type_code_sleb128bytes_tuple = find_leb128bytes(candidbytes, type_code_start_candidbytes_i);
    int type_code = leb128flutter.decodeSigned(type_code_sleb128bytes_tuple.item1) as int;
    late TfuncTuple t_func_tuple;
    if (type_code >= 0) {
        t_func_tuple = TfuncTuple(TypeTableReference(type_code), type_code_sleb128bytes_tuple.item2);
    } 
    else if (isPrimTypeCode(type_code)) { 
        t_func_tuple = TfuncTuple(backwards_primtypes_opcodes_for_the_primtype_type_stances[type_code]!, type_code_sleb128bytes_tuple.item2);
    } 
    else if (isConsOrRefTypeCode(type_code)) { 
        t_func_tuple = constypes_and_reftypes_opcodes_for_the_static_T_backwards_function[type_code]!(candidbytes, type_code_sleb128bytes_tuple.item2);
    }
    else {
        throw Exception('unknown candid type_code ');
    }
    
    if (t_func_tuple.item1.isTypeStance==false) { throw Exception('T_backwards functions need to return a CandidType with an isTypeStance=true'); }
    return t_func_tuple;
}

CandidBytes_i crawl_type_table(Uint8List candidbytes) {
    type_table.clear();
    FindLeb128BytesTuple type_table_length_leb128bytes_tuple = find_leb128bytes(candidbytes, 4);
    dynamic type_table_length = leb128flutter.decodeUnsigned(type_table_length_leb128bytes_tuple.item1);
    if (type_table_length is int) { type_table_length = BigInt.from(type_table_length); } 
    CandidBytes_i next_type_start_candidbytes_i = type_table_length_leb128bytes_tuple.item2;
    for (BigInt t=BigInt.from(0);t<type_table_length;t=t+BigInt.one) {
        TfuncTuple t_func_tuple = crawl_type_table_whirlpool(candidbytes, next_type_start_candidbytes_i); // first layer should never be a type_table_reference
        CandidType ctype = t_func_tuple.item1;
        if (ctype.isTypeStance==false) { throw Exception('T functions need to return a ctype with an isTypeStance=true'); }
        if (ctype is TypeTableReference) { throw Exception('first level type_table type cannot be a typetablereference'); }
        type_table.add(ctype);
        next_type_start_candidbytes_i = t_func_tuple.item2;
    }
    return next_type_start_candidbytes_i;
}

List<CandidType> crawl_memory_bytes(Uint8List candidbytes, CandidBytes_i param_count_start_i) {
    List<CandidType> candids = [];
    FindLeb128BytesTuple param_count_leb128bytes_tuple = find_leb128bytes(candidbytes, param_count_start_i);
    dynamic param_count = leb128flutter.decodeUnsigned(param_count_leb128bytes_tuple.item1);   
    if (param_count is int) { param_count = BigInt.from(param_count); }
    CandidBytes_i params_types_next_i = param_count_leb128bytes_tuple.item2;
    List<int> params_type_codes = [];
    for (BigInt i=BigInt.from(0);i<param_count;i=i+BigInt.one) {
        FindLeb128BytesTuple type_code_sleb128bytes_tuple = find_leb128bytes(candidbytes, params_types_next_i);
        int type_code = leb128flutter.decodeSigned(type_code_sleb128bytes_tuple.item1) as int;
        params_type_codes.add(type_code);
        params_types_next_i = type_code_sleb128bytes_tuple.item2;
    }
    CandidBytes_i next_param_value_start_i = params_types_next_i;
    for (int type_code in params_type_codes) {
        late CandidType ctype;
        if (type_code >= 0) {
            ctype = type_table[type_code];
        } else if (isPrimTypeCode(type_code)) {
            ctype = backwards_primtypes_opcodes_for_the_primtype_type_stances[type_code]!;
        } else {
            throw Exception('params_list_types codes can either be a type_table_i or a primtypecode'); // even for a principal?
        }

        MfuncTuple ctype_m_func_tuple = ctype.M(candidbytes, next_param_value_start_i);
        CandidType cvalue = ctype_m_func_tuple.item1;
        if (cvalue.isTypeStance==true) { throw Exception('M functions need to return a CandidType with an isTypeStance=false'); }
        candids.add(cvalue);
        next_param_value_start_i = ctype_m_func_tuple.item2;
    }
    type_table.clear();
    return candids;
}


// backwards
List<CandidType> c_backwards(Uint8List candidbytes) {
    // print(bytesasahexstring(candidbytes));
    if (!(aresamebytes(candidbytes.sublist(0, 4), magic_bytes))) { throw Exception(':void: magic-bytes.'); }
    CandidBytes_i param_count_i = crawl_type_table(candidbytes);
    List<CandidType> candids = crawl_memory_bytes(candidbytes, param_count_i);
    return candids;
}



// forwards
List<List<int>> type_table_forward = []; // each [inner] list is a candid(cons)types.T_forward() 

int put_t_in_the_type_table_forward(List<int> t_bytes) {
    int? same_type_i;
    for (int i=0; i < type_table_forward.length;i++) {
        if (aresamebytes(t_bytes, type_table_forward[i])) {
            same_type_i = i;
        }
    }
    if (same_type_i != null) {
        return same_type_i; 
    } else {
        type_table_forward.add(t_bytes);
        return type_table_forward.length - 1;
    }
}

// forwards
Uint8List c_forwards(List<CandidType> candids) {
    candids.forEach((CandidType c){ if (c.isTypeStance==true) { throw Exception('c_forwards must be with the candids of the isTypeStance=false'); }});
    List<int> candidbytes = magic_bytes.toList();
    List<int> params_list_types_bytes_section = [];
    List<int> params_list_values_bytes_section = [];
    for (CandidType candid in candids) {
        params_list_types_bytes_section.addAll(candid.T_forward()); // sleb128-bytes() of either primtype -opcode or type_table_i    // constypes use the type_table_forward list for the T function to put the types and gives back the type_table_i-leb128-code-bytes. 
        params_list_values_bytes_section.addAll(candid.M_forward()); 
    }
    candidbytes.addAll(leb128flutter.encodeUnsigned(type_table_forward.length));
    for (List<int> type_bytes in type_table_forward) { candidbytes.addAll(type_bytes); }
    candidbytes.addAll(leb128flutter.encodeUnsigned(candids.length));
    candidbytes.addAll(params_list_types_bytes_section);
    candidbytes.addAll(params_list_values_bytes_section);
    type_table_forward.clear(); // we'll see
    return Uint8List.fromList(candidbytes);
}



// is the type_table length in the code in the leb128-Unsigned?
// is the parameter-length in the code as the leb128-Unsigned?



abstract class CandidType {
    bool get isTypeStance;
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i);
    
    Uint8List T_forward();
    Uint8List M_forward();
}


abstract class PrimitiveCandidType extends CandidType {
    final value = null;
    bool get isTypeStance => this.value == null;
    
    Uint8List T_forward() {
        for (MapEntry me in backwards_primtypes_opcodes_for_the_primtype_type_stances.entries) {
            if (this.runtimeType == me.value.runtimeType) {
                return leb128flutter.encodeSigned(me.key);
            } 
        }
        throw Exception('should be a type_code of this static class in the backwards_primtypes map');
    }

    @override
    String toString() {
        String s = 'CandidType: ' + super.toString().substring(13,super.toString().length-1);
        return this.value != null ? s + ': ${this.value}' : s;
    }

}




class Null extends PrimitiveCandidType {
    static const int type_code = -1;
    get value => throw Exception('CandidType: Null is with the lack of a value.'); 
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        return MfuncTuple(Null(), start_i);
    }

    Uint8List M_forward() {
        return Uint8List(0);
    }
}


class Bool extends PrimitiveCandidType {
    static const int type_code = -2;
    final bool? value;
    Bool([this.value]);
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        return MfuncTuple(Bool(candidbytes[start_i]==1), start_i + 1);
    }

    Uint8List M_forward() {
        Uint8List l = Uint8List(1);
        l[0] = this.value==true ? 1 : 0;
        return l;
    }
}


class Nat extends PrimitiveCandidType {
    static const int type_code = -3;
    final dynamic? value;// can be int or BigInt
    Nat([this.value]) {
        if (value is! BigInt && value is! int && value!=null) {
            throw Exception('CandidType: Nat value must be either a dart-int or a dart-BigInt.');
        }
        if (value !=null && value<0) {
            throw Exception('CandidType: Nat can only hold a value >=0 ');
        }
    }

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        FindLeb128BytesTuple leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic leb128_nat = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1); // can be int or BigInt
        return MfuncTuple(Nat(leb128_nat), leb128_bytes_tuple.item2);
    }

    Uint8List M_forward() {
        return leb128flutter.encodeUnsigned(this.value);
    }

} 

class Int extends PrimitiveCandidType {
    static const int type_code = -4;
    final dynamic? value;// can be int or BigInt
    Int([this.value]) {
        if (!(value is BigInt) && !(value is int) && value!=null) {
            throw Exception('CandidType: Int value must be either a dart-int or a dart-BigInt.');
        }
    }

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        FindLeb128BytesTuple sleb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic sleb128_int = leb128flutter.decodeSigned(sleb128_bytes_tuple.item1); // can be int or BigInt
        return MfuncTuple(Int(sleb128_int), sleb128_bytes_tuple.item2);
    }
    
    Uint8List M_forward() {
        return leb128flutter.encodeSigned(this.value);
    }

} 

class Nat8 extends PrimitiveCandidType {
    static const int type_code = -5;
    final int? value;
    Nat8([this.value]) {
        if (value != null) {
            if (value! < 0 || value! > pow(2, 8)-1 ) {
                throw Exception('CandidType: Nat8 value can be between 0<=value && value <= 255 ');
            }
        }
    }
 
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // String nat8_asabitstring = '';
        // for (CandidBytes_i nat8_byte_i=start_i;nat8_byte_i<start_i+1;nat8_byte_i++) {
        //     nat8_asabitstring += candidbytes[nat8_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat8_asabitstring, radix: 2);

        int value = ByteData.sublistView(candidbytes, start_i, start_i+1).getUint8(0);
        MfuncTuple m_func_tuple = MfuncTuple(Nat8(value), start_i+1);
        return m_func_tuple;    
    }
    
    Uint8List M_forward() {
        return Uint8List.fromList([this.value!]);
    }

} 

class Nat16 extends PrimitiveCandidType {
    static const int type_code = -6;
    final int? value;
    Nat16([this.value]) {
        if (value!=null) {
            if (value! < 0 || value! > pow(2, 16)-1 ) {
                throw Exception('CandidType: Nat16 value can be between 0<=value && value <= ${pow(2, 16)-1} ');            
            }
        }    
    }
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // String nat16_asabitstring = '';
        // for (CandidBytes_i nat16_byte_i=start_i;nat16_byte_i<start_i+2;nat16_byte_i++) {
        //     nat16_asabitstring += candidbytes[nat16_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat16_asabitstring, radix: 2);
        
        int value = ByteData.sublistView(candidbytes, start_i, start_i+2).getUint16(0, Endian.little);
        MfuncTuple m_func_tuple = MfuncTuple(Nat16(value), start_i+2);
        return m_func_tuple;          
    }

    Uint8List M_forward() {
        String rstr = this.value!.toRadixString(2);
        List<String> bytes_bitstrings = [];
        while (rstr.length<16) {
            rstr = '0' + rstr;
        }
        List<int> bytes = [];
        for (int i=0;i<2;i++) {
            bytes.add(int.parse(rstr.substring(i*8, i*8+8), radix: 2));   
        }
        return Uint8List.fromList(bytes.reversed.toList());// as Uint8List;
    }


} 

class Nat32 extends PrimitiveCandidType {
    static const int type_code = -7;
    final int? value;
    Nat32([this.value]) {
        if (value!=null) {
            if (value! < 0 || value! > pow(2, 32)-1 ) {
                throw Exception('CandidType: Nat32 value can be between 0<=value && value <= ${pow(2, 32)-1} ');
            }
        }
    }
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // String nat32_asabitstring = '';
        // for (CandidBytes_i nat32_byte_i=start_i;nat32_byte_i<start_i+4;nat32_byte_i++) {
        //     nat32_asabitstring += candidbytes[nat32_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat32_asabitstring, radix: 2);
        
        int value = ByteData.sublistView(candidbytes, start_i, start_i+4).getUint32(0, Endian.little);
        MfuncTuple m_func_tuple = MfuncTuple(Nat32(value), start_i+4);
        return m_func_tuple;                 
    }

    Uint8List M_forward() {
        String rstr = this.value!.toRadixString(2);
        List<String> bytes_bitstrings = [];
        while (rstr.length<32) {
            rstr = '0' + rstr;
        }
        List<int> bytes = [];
        for (int i=0;i<4;i++) {
            bytes.add(int.parse(rstr.substring(i*8, i*8+8), radix: 2));   
        }
        return Uint8List.fromList(bytes.reversed.toList());
    }
} 



class Nat64 extends PrimitiveCandidType {
    static const int type_code = -8;
    final dynamic? value; // can be int or BigInt bc of the dart on the web is with the int-max-size: 2^53
    Nat64([this.value]) {
        if (!(value is BigInt) && !(value is int) && value!=null) {
            throw Exception('CandidType: Nat64 value must be either a dart-int or a dart-BigInt.');
        }
        if (value != null) {
            late BigInt bigintvalue;
            if (value is int) { bigintvalue = BigInt.from(value); } else { bigintvalue = value; }
            if (bigintvalue < BigInt.from(0) || bigintvalue > BigInt.from(2).pow(64)-BigInt.from(1)) {
                throw Exception('CandidType: Nat64 value can be between 0<=value && value <= ${BigInt.from(2).pow(64)-BigInt.from(1)} ');
            }
        }
    }
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // get BigInt/int of the candid_nat64 
        String nat64_asabitstring = bytes_as_the_bitstring(Uint8List.fromList(candidbytes.sublist(start_i, start_i + 8).reversed.toList()));
        BigInt va = BigInt.parse(nat64_asabitstring, radix: 2);
        MfuncTuple m_func_tuple = MfuncTuple(Nat64(va.isValidInt ? va.toInt() : va), start_i+8);
        return m_func_tuple;                 
    }

    Uint8List M_forward() {
        String rstr = this.value!.toRadixString(2);
        List<String> bytes_bitstrings = [];
        while (rstr.length<64) {
            rstr = '0' + rstr;
        }
        List<int> bytes = [];
        for (int i=0;i<8;i++) {
            bytes.add(int.parse(rstr.substring(i*8, i*8+8), radix: 2));   
        }
        return Uint8List.fromList(bytes.reversed.toList());
    }

} 

class Int8 extends PrimitiveCandidType {
    static const int type_code = -9;
    final int? value;
    Int8([this.value]) {
        if (value!=null) {
            if ( value! < -128 || value! > 127 ) {
                throw Exception('CandidType: Int8 value must be between -128<=value && value <=127');
            }
        } 
    }
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+1).getInt8(0);
        MfuncTuple m_func_tuple = MfuncTuple(Int8(value), start_i+1);
        return m_func_tuple;                  
    }

    Uint8List M_forward() {
        ByteData bytedata = ByteData(1);
        bytedata.setInt8(0, this.value!);
        return Uint8List.view(bytedata.buffer);
    }

} 

class Int16 extends PrimitiveCandidType {
    static const int type_code = -10;
    final int? value;
    Int16([this.value]) {
        if (value!=null) {
            if (value! < pow(-2,15) || value! > pow(2,15)-1 ) {
                throw Exception('CandidType: Int16 value must be between ${pow(-2,15)} <= value && value <= ${pow(2,15)-1}');
            }
        }
    }
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+2).getInt16(0, Endian.little);
        MfuncTuple m_func_tuple = MfuncTuple(Int16(value), start_i+2);
        return m_func_tuple;           
    }

    Uint8List M_forward() {
        ByteData bytedata = ByteData(2);
        bytedata.setInt16(0, this.value!, Endian.little);
        return Uint8List.view(bytedata.buffer);
    }
} 

class Int32 extends PrimitiveCandidType {
    static const int type_code = -11;
    final int? value;
    Int32([this.value]) {
        if (value!=null) { 
            if (value! < pow(-2,31) || value! > pow(2,31)-1 ) {
                throw Exception('CandidType: Int32 value must be between ${pow(-2,31)} <= value && value <= ${pow(2,31)-1}');
            }
        }
    }
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+4).getInt32(0, Endian.little);
        MfuncTuple m_func_tuple = MfuncTuple(Int32(value), start_i+4);
        return m_func_tuple;            
    }

    Uint8List M_forward() {
        ByteData bytedata = ByteData(4);
        bytedata.setInt32(0, this.value!, Endian.little);
        return Uint8List.view(bytedata.buffer);
    }
} 

class Int64 extends PrimitiveCandidType {
    static const int type_code = -12;
    final dynamic? value;
    Int64([this.value]) {
        if (!(value is BigInt) && !(value is int) && value!=null) {
            throw Exception('CandidType: Int64 value must be either a dart-int or a dart-BigInt.');
        }
        if (value != null) {
            late BigInt bigintvalue;
            if (value is int) { bigintvalue = BigInt.from(value); } else { bigintvalue = value; }
            if (bigintvalue < BigInt.from(-2).pow(63) || bigintvalue > BigInt.from(2).pow(63)-BigInt.from(1)) {
                throw Exception('CandidType: Int64 value can be between ${BigInt.from(-2).pow(63)}<=value && value <= ${BigInt.from(2).pow(63)-BigInt.from(1)} ');
            }
        }
    }
    
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        String int64_asabitstring = bytes_as_the_bitstring(Uint8List.fromList(candidbytes.sublist(start_i, start_i + 8).reversed.toList())); // .reverse for the little-endian
        dynamic v = twos_compliment_bitstring_as_the_integer(int64_asabitstring, bit_size: 64); // int or BigInt
        return MfuncTuple(Int64(v), start_i+8);
    }

    Uint8List M_forward() {
        String tc_bitstring = integers_as_the_twos_compliment_bitstring(this.value, bit_size: 64);
        Uint8List bytes = bitstring_as_the_bytes(tc_bitstring);
        return Uint8List.fromList(bytes.reversed.toList());        
    }
} 

class Float32 extends PrimitiveCandidType {
    static const int type_code = -13;
    final double? value;
    Float32([this.value]) {
        // :do: make this limit the range of the values for the single-presscission
    }

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        double value = ByteData.sublistView(candidbytes, start_i, start_i+4).getFloat32(0, Endian.little);
        return MfuncTuple(Float32(value), start_i+4);     
    }

    Uint8List M_forward() {
        ByteData bytedata = ByteData(4);
        bytedata.setFloat32(0, this.value!, Endian.little);
        return Uint8List.view(bytedata.buffer);
    }

} 


// : DO. [ make sure the floats can handle js and linux the same ]
class Float64 extends PrimitiveCandidType {
    static const int type_code = -14;
    final double? value;
    Float64([this.value]);

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        double value = ByteData.sublistView(candidbytes, start_i, start_i+8).getFloat64(0, Endian.little); // is for the js double the same as the linux-double
        return MfuncTuple(Float64(value), start_i+8);    
    }

    Uint8List M_forward() {
        ByteData bytedata = ByteData(8);
        bytedata.setFloat64(0, this.value!, Endian.little);
        return Uint8List.view(bytedata.buffer);
    }

} 

class Text extends PrimitiveCandidType {
    static const int type_code = -15;
    final String? value;
    Text([this.value]);

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        Tuple2<Uint8List,CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int len_utf8_bytes = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1) as int; // candidbytes list can only index 2^64 ?? w
        CandidBytes_i next_i = leb128_bytes_tuple.item2 + len_utf8_bytes;
        Uint8List utf8_bytes = candidbytes.sublist(leb128_bytes_tuple.item2, next_i);
        return MfuncTuple(Text(utf8.decode(utf8_bytes)), next_i);
    }

    Uint8List M_forward() {
        List<int> bytes = [];
        bytes.addAll(leb128flutter.encodeUnsigned(this.value!.length));
        bytes.addAll(utf8.encode(this.value!));
        return Uint8List.fromList(bytes);
    }
} 

class Reserved extends PrimitiveCandidType {
    static const int type_code = -16;
    get value => throw Exception('CandidType: Reserved is with the lack of a value.');

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        return MfuncTuple(Reserved(), start_i);      
    }
    
    Uint8List M_forward() {
        return Uint8List(0);
    }
} 

class Empty extends PrimitiveCandidType {
    static const int type_code = -17;
    get value => throw Exception('CandidType: Empty is with the lack of a value.');

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        throw Exception('M(_ : empty) will never be called.');    // NB: M(_ : empty) will never be called. 
    }

    Uint8List M_forward () {
        throw Exception('M(_ : empty) will never be called.');    // NB: M(_ : empty) will never be called. 
    }
} 

// ------------------------------------

// M_backward-functions must give-back a new stance.



abstract class ConstructType extends CandidType {}




class Option extends ConstructType {
    static const int type_code = -18;
    late final CandidType? value; 
    late final CandidType? value_type;
    late final bool isTypeStance;
    Option({this.value, this.value_type, this.isTypeStance=false}) { 
        if (isTypeStance==true) {
            if (value_type==null) {
                throw Exception('for an Option as a type-stance is with the value_type-parameter-quirement by the class-rules.');
            }
            if (value!=null) {
                throw Exception('for an Option as a type-stance is with the value-parameter-null-quirement by the class-rules.');
            }
        } else {
            if (value==null && value_type==null) {
                throw Exception('an Option needs either a CandidType value, or if the value is null: an Option needs the value_type-parameter set to a CandidType-[in]stance with the isTypeStance=true');
            }
        }
        if (value_type!=null) {
            if (value_type!.isTypeStance==false) {
                throw Exception('The value_type CandidType must have .isTypeStance == true');
            }           
        }
    }

    static TfuncTuple T_backward(Uint8List candidbytes, CandidBytes_i start_i) { 
        // type_code-cursion
        TfuncTuple value_t_func_tuple = crawl_type_table_whirlpool(candidbytes, start_i);
        Option opt_type = Option(value_type: value_t_func_tuple.item1, isTypeStance: true);
        return TfuncTuple(opt_type, value_t_func_tuple.item2);
    }
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        int opt_first_byte = candidbytes[start_i];
        late CandidBytes_i next_i;
        late CandidType? val; 
        if (opt_first_byte==0) {
            val = null;
            next_i = start_i + 1;
        } else if (opt_first_byte==1) {
            MfuncTuple value_type_m_func_tuple = this.value_type!.M(candidbytes, start_i + 1);
            val = value_type_m_func_tuple.item1;
            next_i = value_type_m_func_tuple.item2;
        }
        else {
            throw Exception('candid Option M bytes must start with a 0 or 1 byte.');
        }
        Option opt = Option(value: val, value_type: this.value_type);
        return MfuncTuple(opt, next_i);
    }

    Uint8List T_forward() {
        // is with the give-back of a sleb128-bytes of a type-table-i
        Uint8List t_bytes = leb128flutter.encodeSigned(Option.type_code);
        Uint8List value_type_t_forward_bytes = this.value != null ? this.value!.T_forward() : this.value_type!.T_forward();
        t_bytes.addAll(value_type_t_forward_bytes);
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128flutter.encodeSigned(type_table_i); 
    }

    Uint8List M_forward() {
        List<int> bytes = [];
        if (this.value == null) {
            bytes.add(0);
        } else if (this.value != null) {
            bytes.add(1);
            bytes.addAll(this.value!.M_forward());
        }
        return Uint8List.fromList(bytes);
    }
}


class Vector<T extends CandidType> extends ConstructType with ListMixin<T> {         
    static const int type_code = -19;
    final CandidType? values_type; // use if want to serialize an empty vector or when creating a type-finition/type-stance/isTypeStance=true
    final bool isTypeStance;
    Vector({this.values_type, this.isTypeStance= false}) {
        if (values_type!=null) {
            if (values_type!.isTypeStance==false) {
                throw Exception('The Vector values_type CandidType must have .isTypeStance == true');
            }
        } 
    }
    static Vector<T> oftheList<T extends CandidType>(Iterable<T> list ) {
        Vector<T> vec = Vector<T>();
        vec.addAll(list);
        return vec;
    }

    List<T> _list = <T>[];
    _canputinthevectortypecheck(CandidType new_c) {
        if (this.isTypeStance == true) { // test this throw 
            throw Exception('a Vector with a isTypeStance=true is a vector-[in]stance of a vector-type(the type of the vectors values), if you want to put CandidType values in a vector, create a new Vector().');
        }
        if (this.values_type != null) {
            if (this.values_type.runtimeType != new_c.runtimeType) {
                throw Exception('if the Vector has a values_type-field , the candidtype of the vector-values must match the candidtype of the values_type-field');
            }
        }
        if (_list.length > 0) { // dp i need this now that i have the Vector<T extends CandidType> ? i think yes because when Vector() without a <SomeCandidType> it still must be the same specific candidtype
            _list.forEach((CandidType list_c) { 
                // test this if
                if (list_c.runtimeType != new_c.runtimeType) { throw Exception(':CandidType-values in a Vector-list are with the quirement of the same-specific-candidtype-type. :type of the vector-values-now: ${this[0].runtimeType}.'); }
            });
        }
    }
    int get length => _list.length;
    set length(int l) => throw Exception('why are you setting the length of the vector here?');
    T operator [](int i) => _list[i];
    void operator []=(int i, T v) { 
        _canputinthevectortypecheck(v);
        _list[i] = v;
    }
    void add(T c) { 
        _canputinthevectortypecheck(c);
        _list.add(c);
    }
    void addAll(Iterable<T> candids) {    
        candids.forEach((T c){
            if (c.runtimeType != candids.first.runtimeType) {
                throw Exception('each list-value in an addAll of a Vector must be the same type');
            }
            _canputinthevectortypecheck(c);
        });
        _list.addAll(candids);
    } 


    static TfuncTuple T_backward(Uint8List candidbytes, CandidBytes_i start_i) {
        TfuncTuple values_type_t_func_tuple = crawl_type_table_whirlpool(candidbytes, start_i);
        Vector vec = Vector(values_type: values_type_t_func_tuple.item1);
        return TfuncTuple(vec, values_type_t_func_tuple.item2);
    } 
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        Tuple2<Uint8List,CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic vec_len = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1);
        if (vec_len is int) { vec_len = BigInt.from(vec_len); }
        CandidBytes_i next_vec_item_start_i = leb128_bytes_tuple.item2;
        Vector vec = Vector();
        for (BigInt i=BigInt.from(0);i<vec_len;i=i+BigInt.one) {
            MfuncTuple m_func_tuple = this.values_type!.M(candidbytes, next_vec_item_start_i);
            vec.add(m_func_tuple.item1);
            next_vec_item_start_i = m_func_tuple.item2;
        }
        return MfuncTuple(vec, next_vec_item_start_i);
    }

    Uint8List T_forward() {
        Uint8List t_bytes = leb128flutter.encodeSigned(Vector.type_code);
        if (this.values_type == null && this.length == 0) {
            throw Exception('candid cannot conclude the type of the items in this vector. candid c_forward needs a vector-values-type to serialize a Vector. either put a candidtype in this vector .add(Nat(548)) .  or if you want the vector to be empty, give a values_type-param when creating this vector. Vector(values_type: Int64()/Text()/...)');
        }
        Uint8List values_type_t_forward_bytes = this.values_type != null ? this.values_type!.T_forward() : this[0].T_forward();
        t_bytes.addAll(values_type_t_forward_bytes);
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128flutter.encodeSigned(type_table_i);
    }

    Uint8List M_forward() {
        Uint8List m_bytes = Uint8List(0);
        m_bytes.addAll(leb128flutter.encodeUnsigned(this.length));
        for (CandidType c in this) {
            m_bytes.addAll(c.M_forward());
        }
        return m_bytes;
    }
}


class Blob extends Vector<Nat8> { 
    Blob(Iterable<int> bytes_list) {
        this.addAll_bytes(bytes_list);
    }
    static Blob oftheVector(Vector<Nat8> vecnat8) {
        return Blob(vecnat8.map<int>((Nat8 nat8byte)=>nat8byte.value!).toList());
    }
    Uint8List get bytes => Uint8List.fromList(this.map((Nat8 nat8byte)=>nat8byte.value!).toList());
    void add_byte(int byte) { 
        super.add(Nat8(byte));
    }
    void addAll_bytes(Iterable<int> bytes_list) {  
        List<Nat8> nat8list = bytes_list.map((int byte)=>Nat8(byte)).toList();
        super.addAll(nat8list);
    }
    int get_byte_i(int i) {
        Nat8 nat8byte = this[i] as Nat8;
        return nat8byte.value!;
    }
}





abstract class RecordAndVariantMap extends ConstructType with MapMixin<int, CandidType> {
    final bool isTypeStance;
    RecordAndVariantMap({this.isTypeStance=false});
    Map<int, CandidType> _map = {}; // values are CandidTypes with a isTypeStance=true when this is a record_type of a type_table with an isTypeStance=true
    Iterable<int> get keys => _map.keys.toList()..sort();
    Iterable<CandidType> get values => this.keys.map((int k)=>this[k]!);
    CandidType? operator [](dynamic key) { // String or int
        late int k;
        if (key is String) {
            k = candid_text_hash(key);
        } else 
        if (key is int) {
            k = key;
        } else {
            throw Exception('must pass in either a String or an int to a fieldtype lookup');
        }
        return _map[k];
    }
    void operator []=(dynamic key, CandidType value) { // key can be String or a nat(int). if key is String it gets hashed with the candid-hash for the lookup which is: nat. 
        late int k;
        if (key is String) {
            k = candid_text_hash(key);
        } else 
        if (key is int) {
            if (key >= pow(2,32)) {
                throw Exception('candid fieldtype-id as an int needs to be < 2^32. "An id value must be smaller than 2^32 and no id may occur twice in the same record type." ');
            }
            k = key;
        }
        else {
            throw Exception('must pass in a String or an int as a fieldtype-id');
        }
        if (isTypeStance != value.isTypeStance) {
            throw Exception('A Record or Variant with an isTypeStance=${isTypeStance} can only set map-key-values that are with an isTypeStance=${isTypeStance}. You tried to set a CandidType-value with a isTypeStance=${value.isTypeStance} to the value of a Record/Variant with an isTypeStance=${isTypeStance}.');
        }
        _map[k] = value;
    }
    CandidType? remove(Object? key) {
        late int k;
        if (key is String) {
            k = candid_text_hash(key);
        } else 
        if (key is int) {
            if (key >= pow(2,32)) {
                throw Exception('candid fieldtype-id as an int needs to be < 2^32. "An id value must be smaller than 2^32 and no id may occur twice in the same record type." ');
            }
            k = key;
        }
        else {
            throw Exception('must pass in a String or an int as a fieldtype-id');
        }
        return _map.remove(k);
    }
    void clear() {
        return _map.clear();
    }
}


class Record extends RecordAndVariantMap {
    static const int type_code = -20;
    Record({isTypeStance=false}) : super(isTypeStance: isTypeStance);
    
    static oftheMap(Map<dynamic, CandidType> record_map, {isTypeStance=false}) { // Map<String or int, CandidType>
        Record record = Record(isTypeStance: isTypeStance);
        for (MapEntry mkv in record_map.entries) { record[mkv.key] = mkv.value; }
        return record;
    }
    
    static TfuncTuple T_backward(Uint8List candidbytes, CandidBytes_i start_i) { 
        Record record_type = Record(isTypeStance: true);
        FindLeb128BytesTuple record_len_find_leb128bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic record_len = leb128flutter.decodeUnsigned(record_len_find_leb128bytes_tuple.item1);
        if (record_len is int) { record_len = BigInt.from(record_len); }
        CandidBytes_i next_field_start_candidbytes_i = record_len_find_leb128bytes_tuple.item2;
        for (BigInt i=BigInt.from(0);i<record_len;i=i+BigInt.one) {
            FindLeb128BytesTuple leb128_bytes_tuple = find_leb128bytes(candidbytes, next_field_start_candidbytes_i);
            Uint8List field_id_hash_leb128_bytes = leb128_bytes_tuple.item1;
            int field_id_hash = leb128flutter.decodeUnsigned(field_id_hash_leb128_bytes) as int;
            // throw here and in variant fieldtypes if field-id-hash is less than any of the field hashes already in the record_types
            CandidBytes_i field_type_code_byte_candidbytes_i = leb128_bytes_tuple.item2;
            TfuncTuple t_func_tuple = crawl_type_table_whirlpool(candidbytes, field_type_code_byte_candidbytes_i);
            CandidType ctype = t_func_tuple.item1;
            next_field_start_candidbytes_i = t_func_tuple.item2;
            record_type[field_id_hash] = ctype; 
        }
        return TfuncTuple(record_type, next_field_start_candidbytes_i);
    }

    MfuncTuple M(Uint8List candidbytes, int start_i) {
        Record record = Record();
        CandidBytes_i next_i = start_i;
        for (int hash_key in this.keys) { //  is with the sort on the keys property
            CandidType ctype = this[hash_key]!;
            MfuncTuple ctype_m_func_tuple = ctype.M(candidbytes, next_i);
            record[hash_key]= ctype_m_func_tuple.item1;
            next_i =        ctype_m_func_tuple.item2;
        }
        return MfuncTuple(record, next_i);            
    }

    Uint8List T_forward() {
        List<int> t_bytes = [];
        t_bytes.addAll(leb128flutter.encodeSigned(Record.type_code));
        Iterable<int> hash_keys = this.keys;
        t_bytes.addAll(leb128flutter.encodeUnsigned(hash_keys.length));
        for (int hash_key in hash_keys) {
            t_bytes.addAll(leb128flutter.encodeUnsigned(hash_key));
            t_bytes.addAll(this[hash_key]!.T_forward());
        }
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128flutter.encodeSigned(type_table_i);
    }

    Uint8List M_forward() {
        List<int> m_bytes = [];
        for (int hashkey in this.keys) {
            m_bytes.addAll(this[hashkey]!.M_forward());
        } 
        return Uint8List.fromList(m_bytes);
    }

}



class Variant extends RecordAndVariantMap {
    static const int type_code = -21;
    Variant({isTypeStance=false}) : super(isTypeStance: isTypeStance);
    void operator []=(dynamic key, CandidType value) {
        if (this.isTypeStance==false && this.keys.length > 0) {
            throw Exception('A Variant can only hold one key-value. if this is a type-finition/type-stance, create the Variant(isTypeStance: true)');
        }
        super[key] = value;
    }
    static oftheMap(Map<dynamic, CandidType> variant_map, {isTypeStance=false}) { // Map<String or int, CandidType>
        Variant variant = Variant(isTypeStance: isTypeStance);
        for (MapEntry mkv in variant_map.entries) { variant[mkv.key] = mkv.value; }
        return variant;
    }
    
    static TfuncTuple T_backward(Uint8List candidbytes, CandidBytes_i start_i) { 
        Variant variant_type = Variant(isTypeStance: true);
        FindLeb128BytesTuple variant_type_len_leb128bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic variant_len = leb128flutter.decodeUnsigned(variant_type_len_leb128bytes_tuple.item1);
        if (variant_len is int) { variant_len = BigInt.from(variant_len); }
        CandidBytes_i next_field_start_candidbytes_i = variant_type_len_leb128bytes_tuple.item2;
        for (BigInt i=BigInt.from(0);i < variant_len;i=i+BigInt.one) {
            FindLeb128BytesTuple leb128_bytes_tuple = find_leb128bytes(candidbytes, next_field_start_candidbytes_i);
            Uint8List field_id_hash_leb128_bytes = leb128_bytes_tuple.item1;
            int field_id_hash = leb128flutter.decodeUnsigned(field_id_hash_leb128_bytes) as int;
            CandidBytes_i field_type_code_byte_candidbytes_i = leb128_bytes_tuple.item2;
            TfuncTuple t_func_tuple = crawl_type_table_whirlpool(candidbytes, field_type_code_byte_candidbytes_i);
            CandidType ctype = t_func_tuple.item1;
            variant_type[field_id_hash] = ctype; 
            next_field_start_candidbytes_i = t_func_tuple.item2;
        }
        return TfuncTuple(variant_type, next_field_start_candidbytes_i);


    }

    MfuncTuple M(Uint8List candidbytes, int start_i) {
        Variant variant = Variant();
        FindLeb128BytesTuple leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        Uint8List variant_field_i_leb128_bytes = leb128_bytes_tuple.item1;
        int variant_field_i = leb128flutter.decodeUnsigned(variant_field_i_leb128_bytes) as int;
        List<int> variant_fields_hashs = this.keys.toList(); // .keys are with the sort in the RecordAndVariantMap class
        // print('variant_fields_hashs: ${variant_fields_hashs}');
        int variant_field_hash = variant_fields_hashs[variant_field_i];
        CandidType field_ctype = this[variant_field_hash]!;
        MfuncTuple field_m_func_tuple = field_ctype.M(candidbytes, leb128_bytes_tuple.item2);
        variant[variant_field_hash]= field_m_func_tuple.item1;
        return MfuncTuple(variant, field_m_func_tuple.item2);   
    }

    Uint8List T_forward() {
        List<int> t_bytes = [];
        t_bytes.addAll(leb128flutter.encodeSigned(Variant.type_code));
        Iterable<int> hash_keys = this.keys;
        t_bytes.addAll(leb128flutter.encodeUnsigned(hash_keys.length));   
        for (int hash_key in hash_keys) {
            t_bytes.addAll(leb128flutter.encodeUnsigned(hash_key));
            t_bytes.addAll(this[hash_key]!.T_forward());
        }
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128flutter.encodeSigned(type_table_i);
    }

    Uint8List M_forward() {
        if (this.keys.length > 1) { throw Exception('something went wrong, variant can only hold one value.'); }
        List<int> m_bytes = [];
        m_bytes.addAll(leb128flutter.encodeUnsigned(0));
        m_bytes.addAll(this.values.first.M_forward());
        return Uint8List.fromList(m_bytes);
    }

}

// for the forward of a vec { variant {A,B,C }  } create a vec and for each vec-item: create: new Variant with that item's-specific variant-fieldtype-id and value. Vector() 
// Vector()..addAll([Variant.fromMap({'A':a_value}), Variant.fromMap({'B':b_value}), Variant.fromMap({'C':c_value})]);


// ----------------------------------------------



// can a function have more than one candidtype parameters, in the general &in a func reference ? is the length of the func-reference-in_types in the leb128?
// how can i know when the function annotations are finish in a func-reference-type? is the length of the func-annotations in the leb128?
// are function annotations just a single byte? what happens when there are more than 256 annotations 
// is a non-opaque-func-reference automatic(always) with the non-opaque-service? or can a non-opaque-func-reference be with an opaque-service? for the now i will do it so it can be both. if it can be both then what is the point of a non-opaque-func-reference with an opaque-service-reference. 
// can the datatypes of the in_types & out_types of a func-reference be Index of the type_table or must they be written out within this func-reference-type-table-type 
// is the principalreference-type suppose to be given as an index in a type-table? even in the list of params? for the now, yes.


abstract class ReferenceType extends CandidType {
    bool get isOpaque;
}




// helper function for the TypeTableReferences in the FuntionReference M_backwards 
CandidType type_table_ference_as_the_type_stance(TypeTableReference type_table_fer) {
    CandidType type_table_type = type_table[type_table_fer.type_table_i];
    if (type_table_type is TypeTableReference) {
        type_table_type = type_table_ference_as_the_type_stance(type_table_type);
    } 
    if (type_table_type is TypeTableReference) {
        throw Exception('something cursion is wrong');
    }
    if (type_table_type.isTypeStance==false) {
        throw Exception('this should be true');
    }
    return type_table_type;
}



class FunctionReference extends ReferenceType {
    static const int type_code = -22;

    final bool isTypeStance;

    bool get isOpaque {
        if (this.isTypeStance==true) {
            throw Exception('CandidType: FunctionReference .isOpaque is not known on this FunctionReference-stance because isTypeStance==true');
        }
        return service == null; 
    }

    final List<CandidType> in_types;
    final List<CandidType> out_types;

    final bool isQuery;
    final bool isOneWay;  

    final ServiceReference? service;
    final Text? method_name;

    FunctionReference({required this.in_types, required this.out_types, this.isQuery=false, this.isOneWay=false, this.service, this.method_name, this.isTypeStance=false}) {
        for (List<CandidType> types_list in [in_types, out_types]) {
            for (CandidType typestance in types_list) {
                if (typestance.isTypeStance==false) {
                    throw Exception('CandidType: FunctionReference in_types & out_types lists needs each type-stance/finition with the isTypeStance=true, since these are the type-finitions for the function, not values.');
                }
            }
        }
        if ( (this.service != null && this.method_name == null) || (this.service == null && this.method_name != null)) {
            throw Exception('CandidType: FunctionReference service and method_name must be given both together or both null.');
        }
        if (this.isTypeStance==true && this.service != null) {
            throw Exception('CandidType: FunctionReference service & method_name must be null when isTypeStance==true');
        }
    }

    static TfuncTuple T_backward(Uint8List candidbytes, CandidBytes_i start_i) {
        List<CandidType> in_types = [];
        List<CandidType> out_types = [];
        CandidBytes_i next_types_list_start_i = start_i;
        for (List<CandidType> types_list in [in_types, out_types]) {
            FindLeb128BytesTuple types_len_leb128bytes_tuple = find_leb128bytes(candidbytes, next_types_list_start_i);
            int types_len = leb128flutter.decodeUnsigned(types_len_leb128bytes_tuple.item1) as int;
            CandidBytes_i next_type_start_i = types_len_leb128bytes_tuple.item2;
            for (int type_i=0;type_i < types_len;type_i++) {
                TfuncTuple type_t_func_tuple = crawl_type_table_whirlpool(candidbytes, next_type_start_i);
                types_list.add(type_t_func_tuple.item1);
                next_type_start_i = type_t_func_tuple.item2;
            }
            next_types_list_start_i = next_type_start_i;
        }
        CandidBytes_i func_marks_len_leb128bytes_start_i = next_types_list_start_i;
        FindLeb128BytesTuple func_marks_len_leb128bytes_tuple = find_leb128bytes(candidbytes, func_marks_len_leb128bytes_start_i);
        int func_marks_len = leb128flutter.decodeUnsigned(func_marks_len_leb128bytes_tuple.item1);
        CandidBytes_i next_func_mark_start_i = func_marks_len_leb128bytes_tuple.item2;
        bool isQuery = false;
        bool isOneWay = false;
        for (int func_mark_i = 0; func_mark_i < func_marks_len; func_mark_i++) {
            // leb128? or the single-byte? for the now, the single-byte
            int func_mark_code = candidbytes[next_func_mark_start_i]; 
            if (func_mark_code == 1) {
                isQuery = true;
            }
            else if (func_mark_code == 2) {
                isOneWay = true;
            }
            next_func_mark_start_i = next_func_mark_start_i + 1;
        }
        FunctionReference func_fer = FunctionReference(in_types: in_types, out_types: out_types, isQuery: isQuery, isOneWay: isOneWay, isTypeStance: true);
        return TfuncTuple(func_fer, next_func_mark_start_i);
    } 

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        late CandidBytes_i next_i;
        ServiceReference? service_value;
        Text? method_name_value;
        if (candidbytes[start_i] == 0) {
            next_i = start_i + 1;
        } else if (candidbytes[start_i] == 1) {
            MfuncTuple service_m_func_tuple = ServiceReference(isTypeStance: true, methods_types: {}).M(candidbytes, start_i + 1); // .M on a type-stance gives-back a with the istypestance=false
            service_value = service_m_func_tuple.item1 as ServiceReference; 
            MfuncTuple method_name_text_m_func_tuple = Text().M(candidbytes, service_m_func_tuple.item2);
            method_name_value = method_name_text_m_func_tuple.item1 as Text;
            next_i = method_name_text_m_func_tuple.item2;
        }
        for (List<CandidType> types_list in [this.in_types, this.out_types]) {
            for(int i=0;i<types_list.length;i++) {
                if (types_list[i] is TypeTableReference) {
                    types_list[i] = type_table_ference_as_the_type_stance(types_list[i] as TypeTableReference);
                }
            }
        }
        FunctionReference func_fer = FunctionReference(
            in_types: this.in_types, 
            out_types: this.out_types, 
            isQuery: this.isQuery, 
            isOneWay: this.isOneWay, 
            service: service_value,
            method_name: method_name_value
        );
        if (func_fer.service != null) {
            func_fer.service!.methods[func_fer.method_name!] = func_fer; // putting this function-reference as a method on this function_reference.service
        }
        return MfuncTuple(func_fer, next_i);
    }
    
    Uint8List T_forward() {
        List<int> t_bytes = [];
        t_bytes.addAll(leb128flutter.encodeSigned(FunctionReference.type_code));
        for (List<CandidType> types_list in [this.in_types, this.out_types]) {
            t_bytes.addAll(leb128flutter.encodeUnsigned(types_list.length));
            for (CandidType ctype in types_list) {
                t_bytes.addAll(ctype.T_forward());
            }
        }
        int func_marks_len = 0;
        if (this.isQuery) { func_marks_len += 1; }
        if (this.isOneWay) { func_marks_len += 1; }
        t_bytes.addAll(leb128flutter.encodeUnsigned(func_marks_len));
        if (this.isQuery) { t_bytes.add(1); }
        if (this.isOneWay) { t_bytes.add(2); }
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128flutter.encodeSigned(type_table_i);
    }
    Uint8List M_forward() {
        List<int> m_bytes = [];
        if (this.service != null) {
            m_bytes.add(1);
            m_bytes.addAll(this.service!.M_forward());
            m_bytes.addAll(this.method_name!.M_forward());
        } else {
            m_bytes.add(0);
        }
        return Uint8List.fromList(m_bytes);
    }
}


class ServiceReference extends ReferenceType {
    static const int type_code = -23;

    final bool isTypeStance;
    final Blob? id; 
    bool get isOpaque => id == null;
    Map<Text, FunctionReference> methods = {}; 
    final Map<Text, CandidType>? methods_types; // for the [de]coding of the methtypes  when some may be TypeTableReferences at this point

    ServiceReference({this.id,  Map<Text, FunctionReference>? put_methods, this.isTypeStance=false, this.methods_types}) {
        if (isTypeStance==true) {
            if (this.id != null) {
                throw Exception('id must be null when isTypeStance==true'); // because if its a type-stance that means we only have its data of the type_table and havent called M_backwards() on it yet so we dont know if it has a blob id or not  
            }
            if (this.methods_types == null) { 
                throw Exception('when isTypeStance==true on a ServiceReference it needs a methods_types = {}'); 
            }
        } else {
            if (this.methods_types != null) {
                throw Exception('methods_types can only be given when isTypeStance==true');
            }
        }
        if (put_methods != null) {
            this.methods = put_methods;
        }
    }

    static TfuncTuple T_backward(Uint8List candidbytes, CandidBytes_i start_i) {
        Map<Text, CandidType> methods_types = {}; // CandidType here is either TypeTableReference or FunctionReference
        FindLeb128BytesTuple methods_len_leb128bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int methods_len = leb128flutter.decodeUnsigned(methods_len_leb128bytes_tuple.item1);
        CandidBytes_i next_method_start_i = methods_len_leb128bytes_tuple.item2;
        for (int i=0;i<methods_len;i++) {
            MfuncTuple method_name_m_func_tuple = Text().M(candidbytes, next_method_start_i);
            Text method_name = method_name_m_func_tuple.item1 as Text;
            TfuncTuple function_reference_t_func_tuple = crawl_type_table_whirlpool(candidbytes, method_name_m_func_tuple.item2);
            methods_types[method_name] = function_reference_t_func_tuple.item1; // could be a type table reference
            next_method_start_i = function_reference_t_func_tuple.item2;
        }
        ServiceReference service_fer = ServiceReference(isTypeStance: true, methods_types: methods_types);
        return TfuncTuple(service_fer, next_method_start_i);
    } 

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        if (this.isTypeStance==false) { throw Exception('this function should only be called on a stance with the isTypeStance==true and a Map<Text, FunctionReference> methods_types'); }
        Blob? id_value;
        late CandidBytes_i next_i;
        if (candidbytes[start_i] == 0) {
            next_i = start_i + 1;
        } else if (candidbytes[start_i] == 1) {
            MfuncTuple id_m_func_tuple = Vector(isTypeStance: true, values_type: Nat8()).M(candidbytes, start_i + 1);
            Vector<Nat8> id_value_vecnat8 = Vector.oftheList<Nat8>((id_m_func_tuple.item1 as Vector).cast<Nat8>());
            id_value = Blob.oftheVector(id_value_vecnat8);
            next_i = id_m_func_tuple.item2;
        }
        ServiceReference service = ServiceReference(id: id_value);
        for (MapEntry func_me in this.methods_types!.entries) {
            FunctionReference func_ref = func_me.value.M(Uint8List(0), 0); // getting the FunctionReference types from the type_table without a service or method_name
            service.methods[func_me.key] = FunctionReference(
                service: service, 
                method_name: func_me.key,     // putting this service and method_name of this method on this FunctionReference
                in_types: func_ref.in_types,
                out_types: func_ref.out_types,
                isQuery: func_ref.isQuery,
                isOneWay: func_ref.isOneWay
            );
        }
        return MfuncTuple(service, next_i);
    }
    
    Uint8List T_forward() {
        if (this.isTypeStance==true) {
            throw Exception('Cannot serialize this ServiceReference because it has a isTypeStance=true, try to do ServiceReference with an isTypeStance=false');
        }
        for (MapEntry<Text, FunctionReference> method_ref in this.methods.entries) {
            if (method_ref.key.isTypeStance == true) {
                throw Exception('Cannot serialize this ServiceReference because it has a method with a name: CandidType: Text with an empty String, try setting the method-name to a Text(\'sampletext\')');
            }
            if (method_ref.value.isTypeStance == true) {
                throw Exception('Cannot serialize this ServiceReference because it has a method-FunctionReference with an isTypeStance=true, try to make the methods-FunctionReferences with the isTypeStance=false');
            }
        }
        List<int> t_bytes = [];
        t_bytes.addAll(leb128flutter.encodeSigned(ServiceReference.type_code));
        t_bytes.addAll(leb128flutter.encodeUnsigned(this.methods.keys.length));
        for (MapEntry kv in this.methods.entries) { // does this need sort? 
            t_bytes.addAll(kv.key.M_forward()); // Text
            t_bytes.addAll(kv.value.T_forward()); // FunctionReference
        } 
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128flutter.encodeSigned(type_table_i);
    }

    Uint8List M_forward() {
        List<int> m_bytes = [];
        if (this.id == null) {
            m_bytes.add(0);
        } else {
            m_bytes.add(1);
            m_bytes.addAll(this.id!.M_forward());
        }
        return Uint8List.fromList(m_bytes);
    }
}


class PrincipalReference extends ReferenceType {
    static const int type_code = -24;

    final bool isTypeStance;
    bool get isOpaque => id == null;

    final Blob? id; 

    PrincipalReference({this.id, this.isTypeStance=false}) {
        if (this.isTypeStance==true && this.id != null) {
            throw Exception('if isTypeStance == true then that means that we dont know if this is an opaque reference or not yet.');
        } 
    }

    static TfuncTuple T_backward(Uint8List candidbytes, CandidBytes_i start_i) {
        return TfuncTuple(PrincipalReference(isTypeStance: true), start_i);
    } 
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        Blob? id_value;
        late CandidBytes_i next_i;
        if (candidbytes[start_i] == 0) {
            next_i = start_i + 1;
        } else if (candidbytes[start_i] == 1) {
            MfuncTuple id_m_func_tuple = Vector(isTypeStance: true, values_type: Nat8()).M(candidbytes, start_i + 1);
            Vector<Nat8> id_value_vecnat8 = Vector.oftheList<Nat8>((id_m_func_tuple.item1 as Vector).cast<Nat8>());
            id_value = Blob.oftheVector(id_value_vecnat8); 
            next_i = id_m_func_tuple.item2;
        }
        PrincipalReference principal_fer = PrincipalReference(id: id_value);
        return MfuncTuple(principal_fer, next_i);
    }    
    Uint8List T_forward() {
        List<int> type_code_bytes = leb128flutter.encodeSigned(PrincipalReference.type_code);
        int type_table_i = put_t_in_the_type_table_forward(type_code_bytes);
        return leb128flutter.encodeSigned(type_table_i);
    }
    Uint8List M_forward() {
        List<int> m_bytes = [];
        if (this.id == null) {
            m_bytes.add(0);
        } else {
            m_bytes.add(1);
            m_bytes.addAll(this.id!.M_forward());
        }
        return Uint8List.fromList(m_bytes);
    }
}




