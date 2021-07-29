
// We assume that the fields in a record or variant type are sorted by increasing id and the methods in a service are sorted by name.

import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';
import 'dart:math';
// import '../leb128/main.dart' show leb128flutter;
import 'package:tuple/tuple.dart';
import 'tools.dart';
import 'cross_platform_tools/cross_platform_tools.dart';



final Uint8List magic_bytes = Uint8List.fromList(utf8.encode('DIDL')); //0x4449444C


// Map<dynamic,int> candid_type_codes = {
//     // "primitive-types"
//     // T : <primtype> -> i8*
//     'null': 127,  // T(null)     = sleb128(-1)  = 0x7f
//     'bool': 126,  // T(bool)     = sleb128(-2)  = 0x7e
//     'nat' : 125,    // T(nat)      = sleb128(-3)  = 0x7d
//     'int' : 124,   // T(int)      = sleb128(-4)  = 0x7c
//     'nat8' : 123,    // T(nat8)     = sleb128(-5)  = 0x7b
//     'nat16': 122,    // T(nat16)    = sleb128(-6)  = 0x7a
//     'nat32': 121,    // T(nat32)    = sleb128(-7)  = 0x79
//     'nat64': 120,    // T(nat64)    = sleb128(-8)  = 0x78
//     'int8' : 119,   // T(int8)     = sleb128(-9)  = 0x77
//     'int16': 118,    // T(int16)    = sleb128(-10) = 0x76
//     'int32': 117,    // T(int32)    = sleb128(-11) = 0x75
//     'int64': 116,    // T(int64)    = sleb128(-12) = 0x74
//     'float32': 115,    // T(float32)  = sleb128(-13) = 0x73
//     'float64': 114,    // T(float64)  = sleb128(-14) = 0x72
//     'text': 113,    // T(text)     = sleb128(-15) = 0x71
//     'reserved': 112,    // T(reserved) = sleb128(-16) = 0x70
//     'empty': 111,    // T(empty)    = sleb128(-17) = 0x6f
//     // constructive-types
//     'opt': 110,    // T(opt <datatype>) = sleb128(-18) I(<datatype>)              // 0x6e
//     'vec': 109,    // T(vec <datatype>) = sleb128(-19) I(<datatype>)              // 0x6d
//     'record': 108,    // T(record {<fieldtype>^N}) = sleb128(-20) T*(<fieldtype>^N)  // 0x6c
//     'variant': 107,    // T(variant {<fieldtype>^N}) = sleb128(-21) T*(<fieldtype>^N) // 0x6b
//     // field-type  
//     // T : <fieldtype> -> i8*
//     // T(<nat>:<datatype>) = leb128(<nat>) I(<datatype>) // last byte of the leb128<nat>-coding is < 128
//     // [re]ference-types    
//     // T : <reftype> -> i8*
//     'func': 106,    // T(func (<datatype1>*) -> (<datatype2>*) <funcann>*) = sleb128(-22) T*(<datatype1>*) T*(<datatype2>*) T*(<funcann>*) // 0x6a
//     'service': 105,    // T(service {<methtype>*}) = sleb128(-23) T*(<methtype>*)                                    // 0x69
//     'principal': 104,    // T(principal) = sleb128(-24)                                       // 0x68
//     // method-type
//     // T : <methtype> -> i8*
//     // T(<name>:<datatype>) = leb128(|utf8(<name>)|) i8*(utf8(<name>)) I(<datatype>)
//     // "function-annotations"
//     // T : <funcann> -> i8*
//     'query': 1,    // T(query)  = i8(1)
//     'oneway': 2    // T(oneway) = i8(2)
// };

// String? candid_type_code_as_a_type_string(int candid_type_code_byte) {
//     String? rs; 
//     candid_type_codes.forEach(
//         (type_string, code_byte) { 
//             if (code_byte == candid_type_code_byte) { 
//                 rs = type_string; 
//             } 
//         }
//     );
//     return rs;
// }









// all nat and int candidtypes turn into dart int and BigInt Types. and all dart ints and bigints are coded as candid int (and nat?)


typedef CandidBytes_i = int;     
typedef MfuncTuple = Tuple2<CandidType,CandidBytes_i>; // M_function gives back a CandidType-stance with the values and a Candidbytes_i
// typedef M_func = MfuncTuple Function(Uint8List candidbytes, int start_i);
typedef TfuncTuple = Tuple2<CandidType,CandidBytes_i>; //T-function gives back a CandidType-stance with isTypeStance = true with a m_func

// :primtypes-T-functions are:
//      in the type_table: with the lack of the cept of the candidbytes-parameters with the lack of the give-back of a candidbytes_i
//      in the param_table: ''  ''  ''  ''
// :datatypes(non-primitive)-T-functions are:
//      in the type_table: with the cept of the candidbytes-parameters with the give-back of a candidbytes_i
//      in the param_table: in the type_table as a M_function


// values are either primtype-T-functions: give-back: M_func and are with the lack of the parameters. or this map value can be a non-primtype-T-function: candidbytes,start_i params and: give-back: TFuncTuple 
const Map<int, dynamic> candidtypecodesastheTfunc = {  // primitivetype-T-functions are with the lack of the parameters.
    // "primitive-types"
    // T : <primtype> -> i8*
    127: Null.T, // 'null': 127,  // T(null)     = sleb128(-1)  = 0x7f
    126: Bool.T, // 'bool': 126,  // T(bool)     = sleb128(-2)  = 0x7e
    125: Nat.T, // 'nat' : 125,    // T(nat)      = sleb128(-3)  = 0x7d
    124: Int.T, // 'int' : 124,   // T(int)      = sleb128(-4)  = 0x7c
    123: Nat8.T, // 'nat8' : 123,    // T(nat8)     = sleb128(-5)  = 0x7b
    122: Nat16.T, // 'nat16': 122,    // T(nat16)    = sleb128(-6)  = 0x7a
    121: Nat32.T, // 'nat32': 121,    // T(nat32)    = sleb128(-7)  = 0x79
    120: Nat64.T,    // T(nat64)    = sleb128(-8)  = 0x78
    119: Int8.T, // 'int8' : 119,   // T(int8)     = sleb128(-9)  = 0x77
    118: Int16.T, // 'int16': 118,    // T(int16)    = sleb128(-10) = 0x76
    117: Int32.T, // 'int32': 117,    // T(int32)    = sleb128(-11) = 0x75
    116: Int64.T, // 'int64': 116,    // T(int64)    = sleb128(-12) = 0x74
    115: Float32.T, // 'float32': 115,    // T(float32)  = sleb128(-13) = 0x73
    114: Float64.T, // 'float64': 114,    // T(float64)  = sleb128(-14) = 0x72
    113: Text.T, // 'text': 113,    // T(text)     = sleb128(-15) = 0x71
    112: Reserved.T, // 'reserved': 112,    // T(reserved) = sleb128(-16) = 0x70
    111: Empty.T, // 'empty': 111,    // T(empty)    = sleb128(-17) = 0x6f
    // // constructive-types
    110: Option.T, // 'opt': 110,    // T(opt <datatype>) = sleb128(-18) I(<datatype>)              // 0x6e
    109: Vector.T, // 'vec': 109,    // T(vec <datatype>) = sleb128(-19) I(<datatype>)              // 0x6d
    108: Record.T,    // T(record {<fieldtype>^N}) = sleb128(-20) T*(<fieldtype>^N)  // 0x6c
    107: Variant.T, // 'variant': 107,    // T(variant {<fieldtype>^N}) = sleb128(-21) T*(<fieldtype>^N) // 0x6b
    // field-type  
    // T : <fieldtype> -> i8*
    // T(<nat>:<datatype>) = leb128(<nat>) I(<datatype>) // last byte of the leb128<nat>-coding is < 128
    // [re]ference-types    
    // T : <reftype> -> i8*
    // 'func': 106,    // T(func (<datatype1>*) -> (<datatype2>*) <funcann>*) = sleb128(-22) T*(<datatype1>*) T*(<datatype2>*) T*(<funcann>*) // 0x6a
    // 'service': 105,    // T(service {<methtype>*}) = sleb128(-23) T*(<methtype>*)                                    // 0x69
    // 'principal': 104,    // T(principal) = sleb128(-24)                                       // 0x68
    // method-type
    // T : <methtype> -> i8*
    // T(<name>:<datatype>) = leb128(|utf8(<name>)|) i8*(utf8(<name>)) I(<datatype>)
    // "function-annotations"
    // T : <funcann> -> i8*
    // 'query': 1,    // T(query)  = i8(1)
    // 'oneway': 2    // T(oneway) = i8(2)
};

bool isCandidTypeCode(int type_code) => 127 >= type_code && type_code >=104; 
bool isPrimitiveCandidTypeCode(int type_code) => 127 >= type_code && type_code >=111; 

int candid_text_hash(String text) { 
    // hash(id) = ( Sum_(i=0..k) utf8(id)[i] * 223^(k-i) ) mod 2^32 where k = |utf8(id)|-1
    int hash = 0;
    for (int b in utf8.encode(text)) {
        hash = hash * 223 + b;  
    }
    return hash % pow(2, 32) as int;
}

Tuple2<Uint8List, CandidBytes_i> find_leb128bytes(Uint8List candidbytes, CandidBytes_i start_i) {
    CandidBytes_i c = start_i;
    while (candidbytes[c] >= 128) { 
        c += 1; 
    }
    CandidBytes_i next_i = c + 1;
    Uint8List field_id_hash_leb128_bytes = candidbytes.sublist(start_i, next_i);
    // print('leb128-bytes: ${field_id_hash_leb128_bytes}');
    return Tuple2<Uint8List, CandidBytes_i>(field_id_hash_leb128_bytes, next_i);
}

// backwards
TfuncTuple TfuncWhirlpool(Uint8List candidbytes, CandidBytes_i type_code_candidbytes_i) {
    int type_code = candidbytes[type_code_candidbytes_i];
    if (isPrimitiveCandidTypeCode(type_code)) {
        CandidType primctype = candidtypecodesastheTfunc[type_code](); 
        return TfuncTuple(primctype, type_code_candidbytes_i + 1);
    } else if (isCandidTypeCode(type_code)) {
        TfuncTuple t_func_tuple = candidtypecodesastheTfunc[type_code](candidbytes, type_code_candidbytes_i + 1);
        return t_func_tuple;
    } else {
        // type_table_index
        return TfuncTuple(TypeTableReference(type_code), type_code_candidbytes_i + 1);
    }
}


List<CandidType> type_table = []; 
class TypeTableReference extends CandidType { // extends Candidype , more custom?
    int type_table_i; 
    MfuncTuple M;
    TypeTableReference(this.type_table_i) {
        M = (Uint8List candidbytes, CandidBytes_i start_i) => type_table[type_table_i].M(candidbytes, start_i);
    }
    final bool isTypeStance = true;
}
CandidBytes_i crawl_type_table(Uint8List candidbytes) {
    type_table.clear();
    int type_table_length = candidbytes[4]; // chack what happens if there is greater than 255 itmes in the type table, is this number max 255 or is it a leb128-code[ed]-number
    CandidBytes_i next_type_start_candidbytes_i = 5;
    for (int t=0;t<type_table_length;t++) {
        TfuncTuple t_func_tuple = TfuncWhirlpool(candidbytes, next_type_start_candidbytes_i);
        CandidType ctype = t_func_tuple.item1;
        if (ctype.isTypeStance==false) { throw Exception('T functions need to return a ctype with an isTypeStance=true'); }
        next_type_start_candidbytes_i = t_func_tuple.item2;
        type_table.add(ctype);
    }
    return next_type_start_candidbytes_i;
}

List<CandidType> crawl_memory_bytes(CandidBytes_i param_count_i, Uint8List candidbytes) {
    List<CandidType> candids = [];
    int param_count = candidbytes[param_count_i];   
    if (param_count > 0) {
        CandidBytes_i params_types_start_i = param_count_i + 1;
        CandidBytes_i params_types_finish_i = params_types_start_i + param_count;
        List params_types = candidbytes.sublist(params_types_start_i, params_types_finish_i);
        CandidBytes_i next_param_start_candidbytes_i = params_types_finish_i.toInt(); // .toInt()==.copy()
        for (int p=0;p<param_count;p++) {
            int type_code = params_types[p];
            late CandidType ctype;
            if (isPrimitiveCandidTypeCode(type_code)) {
                ctype = candidtypecodesastheTfunc[type_code]();
            } else { // type_table_lookup
                ctype = type_table[type_code]; 
            }
            MfuncTuple m_func_tuple = ctype.M(candidbytes, next_param_start_candidbytes_i);
            CandidType candid_value = m_func_tuple.item1;
            if (candid_value.isTypeStance==true) { throw Exception('M functions need to return a CandidType with an isTypeStance=false'); }
            candids.add();
            next_param_start_candidbytes_i = m_func_tuple.item2;
        }
    } 
    return candids;
}


// backwards
List<CandidType> candid_bytes_as_the_candid_types(Uint8List candidbytes) {
    print(bytesasahexstring(candidbytes));
    if (!(aresamebytes(candidbytes.sublist(0, 4), magic_bytes))) { throw Exception(':void: magic-bytes.'); }
    CandidBytes_i param_count_i = crawl_type_table(candidbytes);
    List<CandidType> candids = crawl_memory_bytes(param_count_i, candidbytes);
    return candids;
}


// forwards
Uint8List candid_types_as_the_candid_bytes(List<CandidType> candids) {
    throw UnimplementedError('');
}








abstract class CandidType {
    // static const int type_code;
    bool get isTypeStance;
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i);

}

abstract class PrimitiveCandidType extends CandidType {
    bool get isTypeStance {
        return value == null;
    }

    // static M_func T();
    // static M_func M;
}

abstract class NonPrimitiveCandidType extends CandidType {
    // static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i);
    // M_func M;
}

abstract class ConstructType extends NonPrimitiveCandidType {}
abstract class ReferenceType extends NonPrimitiveCandidType {}
abstract class FunctionAnnotation extends NonPrimitiveCandidType {}

// class MethodType extends NonPrimitiveCandidType {}



class Null extends PrimitiveCandidType {
    get value => throw Exception('CandidType: Null is with the lack of a value.'); // should i make the value null?
    
    static Null T() => Null();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        MfuncTuple(Null(), start_i);
    }
}


class Bool extends PrimitiveCandidType {
    bool? value;
    Bool(this.value);
    
    static Bool T() => Bool();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        MfuncTuple(Bool(candidbytes[start_i]==1), start_i + 1);
    }
}


class Nat extends PrimitiveCandidType {
    dynamic? value;// can be int or BigInt
    Nat(this.value);

    static Nat T() => Nat();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        Tuple2<Uint8List, CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic leb128_nat = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1); // can be int or BigInt
        return MfuncTuple(Nat(leb128_nat), leb128_bytes_tuple.item2);
    }

} 

// test this 
class Int extends PrimitiveCandidType {
    dynamic? value;// can be int or BigInt
    Int(this.value);

    static Int T() => Int();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        Tuple2<Uint8List, CandidBytes_i> sleb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic sleb128_int = leb128flutter.decodeSigned(sleb128_bytes_tuple.item1); // can be int or BigInt
        return MfuncTuple(Int(sleb128_int), sleb128_bytes_tuple.item2);
    }

} 

class Nat8 extends PrimitiveCandidType {
    int? value;
    Nat8(this.value);

    static Nat8 T() => Nat8();
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

} 

class Nat16 extends PrimitiveCandidType {
    int? value;
    Nat16(this.value);
    
    static Nat16 T() => Nat16();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // String nat16_asabitstring = '';
        // for (CandidBytes_i nat16_byte_i=start_i;nat16_byte_i<start_i+2;nat16_byte_i++) {
        //     nat16_asabitstring += candidbytes[nat16_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat16_asabitstring, radix: 2);
        
        int value = ByteData.sublistView(candidbytes, start_i, start_i+2).getUint16(0);
        MfuncTuple m_func_tuple = MfuncTuple(Nat16(value), start_i+2);
        return m_func_tuple;          
    }

} 

class Nat32 extends PrimitiveCandidType {
    int? value;
    Nat32(this.value);
    
    static Nat32 T() => Nat32();

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // String nat32_asabitstring = '';
        // for (CandidBytes_i nat32_byte_i=start_i;nat32_byte_i<start_i+4;nat32_byte_i++) {
        //     nat32_asabitstring += candidbytes[nat32_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat32_asabitstring, radix: 2);
        
        int value = ByteData.sublistView(candidbytes, start_i, start_i+4).getUint32(0);
        MfuncTuple m_func_tuple = MfuncTuple(Nat32(value), start_i+4);
        return m_func_tuple;                 
    }
} 



class Nat64 extends PrimitiveCandidType {
    dynamic? value; // can be int or BigInt bc of the dart on the web is with the int-max-size: 2^53
    Nat64(this.value);
    
    static Nat64 T() => Nat64();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // get BigInt/int from candid_nat64 
        String nat64_asabitstring = '';
        for (int nat64_byte_i=start_i;nat64_byte_i<start_i+8;nat64_byte_i++) {
            nat64_asabitstring += candidbytes[nat64_byte_i].toRadixString(2); 
        }
        // checks for bigint here bc of the javascript ints are only up to 2^53
        dynamic value = BigInt.parse(nat64_asabitstring, radix: 2);
        if (value.isValidInt) {
            value = value.toInt();
        }
        MfuncTuple m_func_tuple = MfuncTuple(Nat64(value), start_i+8);
        return m_func_tuple;                 
    }
} 

class Int8 extends PrimitiveCandidType {
    int? value;
    Int8(this.value);
    
    static Int8 T() => Int8();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+1).getInt8(0);
        MfuncTuple m_func_tuple = MfuncTuple(Int8(value), start_i+1);
        return m_func_tuple;                  
    }

} 

class Int16 extends PrimitiveCandidType {
    int? value;
    Int16(this.value);
    
    static Int16 T() => Int16();

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+2).getInt16(0);
        MfuncTuple m_func_tuple = MfuncTuple(Int16(value), start_i+2);
        return m_func_tuple;           
    }
} 

class Int32 extends PrimitiveCandidType {
    int? value;
    Int32(this.value);
    
    static Int32 T() => Int32();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+4).getInt32(0);
        MfuncTuple m_func_tuple = MfuncTuple(Int32(value), start_i+4);
        return m_func_tuple;            
    }
} 

// test on the web 
class Int64 extends PrimitiveCandidType {
    int? value;
    Int64(this.value);
    
    static Int64 T() => Int64();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+8).getInt64(0);
        return MfuncTuple(Int64(value), start_i+8);    // whaat bout when in javascript max integer?  docs has the return type: int but says "The return value will be between -263 and 263 - 1, inclusive ", so what happens in the javascript when value is bigger than 2^53?   
    }

} 

class Float32 extends PrimitiveCandidType {
    double? value;
    Float32(this.value);

    static Float32 T() => Float32();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        double value = ByteData.sublistView(candidbytes, start_i, start_i+4).getFloat32(0);
        return MfuncTuple(Float32(value), start_i+4);     
    }

} 

class Float64 extends PrimitiveCandidType {
    double? value;
    Float64(this.value);

    static Float64 T() => Float64();

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        double value = ByteData.sublistView(candidbytes, start_i, start_i+8).getFloat64(0);
        return MfuncTuple(Float64(value), start_i+8);    
    }

} 

class Text extends PrimitiveCandidType {
    String? value;
    Text(this.value);

    static Text T() => Text();

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        Tuple2<Uint8List,CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int len_utf8_bytes = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1);
        CandidBytes_i next_i = leb128_bytes_tuple.item2 + len_utf8_bytes;
        Uint8List utf8_bytes = candidbytes.sublist(leb128_bytes_tuple.item2, next_i);
        return MfuncTuple(Text(utf8.decode(utf8_bytes)), next_i);
    }
} 

class Reserved extends PrimitiveCandidType {
    get value => throw Exception('CandidType: Reserved is with the lack of a value.');
    static Reserved T() => Reserved();
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        return MfuncTuple(Reserved(), start_i);      
    }
} 

class Empty extends PrimitiveCandidType {
    get value => throw Exception('CandidType: Empty is with the lack of a value.');

    static Empty T() => Empty();

    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) { 
        throw Exception('M(_ : empty) will never be called.');    // NB: M(_ : empty) will never be called. 
    }
} 

// ------------------------------------

// have to start store of the stances themselves 
// m_funcs must give-back a new stance.


// :do: backwards: constypes need tfuncs to give back ctypes and mfuncs to give back a new stance of themselves with the value
// figure out if primtype .value should be final or not
// make sure constypes with a isTypeStance=true have their value_type with the isTypeStance=true

// Option(CandidType-stance or TFunction) // 
class Option extends ConstructType {
    final CandidType? value; // what happens when someone puts an option with a Null candidtype. why is there a Null candidtype?
    final CandidType? value_type;
    final bool isTypeStance;
    Option(CandidType? value, {CandidType? value_type, bool isTypeStance=false}) { 
        this.value = value;
        this.value_type = value_type;
        this.isTypeStance = isTypeStance;
        if (isTypeStance==true) {
            if (this.value_type==null) {
                throw Exception('for an Option as a type-stance is with the value_type-parameter-quirement by the class-rules.');
            }
            if (this.value!=null) {
                throw Exception('for an Option as a type-stance is with the value-parameter-null-quirement by the class-rules.');
            }
        } else {
            if (this.value==null && this.value_type==null) {
                throw Exception('an Option needs either a CandidType value, or if the value is null: an Option needs the value_type-parameter set to a CandidType-[in]stance with the isTypeStance=true');
            }
        }
        if (this.value_type != null) {
            if (value_type.isTypeStance==false) {
                throw Exception('The Option value_type CandidType must have .isTypeStance == true');
            }           
        }
    }

    static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i) { 
        // 110
        // type_code-cursion
        TfuncTuple value_t_func_tuple = TfuncWhirlpool(candidbytes, start_i);
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
            MfuncTuple value_type_m_func_tuple = this.value_type.M(candidbytes, start_i + 1);
            val = value_type_m_func_tuple.item1;
            next_i = value_type_m_func_tuple.item2;
        }
        else {
            throw Exception('candid Option M func must start with a 0 or 1 byte.');
        }
        Option opt = Option(val, value_type: this.value_type);
        return MfuncTuple(opt, next_i);
    }
}


// :test of this class is with the lack of the List.of and List.from constructors
class Vector extends ConstructType with ListMixin<CandidType> {         // mixin List? or just valuate to a list.
    List<CandidType> _list = [];
    _canputinthevectortypecheck(CandidType new_c) {
        if (this.values_type != null) { // test this throw 
            throw Exception('a Vector with a values_type is a vector-[in]stance of a vector-type(the type of the vectors values), if you want to put CandidType values in a vector, create a new Vector().');
        }
        if (_list.length > 0) {
            _list.forEach((CandidType list_c) { 
                if (list_c.runtimeType != new_c.runtimeType) { throw Exception(':CandidType-values in a Vector-list are with the quirement of the same-specific-candidtype-type. :type of the vector-values-now: ${this[0].runtimeType}.'); }
            });
        }
    }
    int get length => _list.length;
    set length => throw Exception('why are you setting the length of the vector here?');
    CandidType operator [](int i) => _list[i];
    void operator []=(int i, CandidType v) { 
        _canputinthevectortypecheck(v);
        _list[i] = v;
    }
    void add(CandidType c) { 
        _canputinthevectortypecheck(c);
        _list.add(c);
    }
    void addAll(List<CandidType> candids) {    
        candids.forEach((CandidType c){
            if (c.runtimeType != candids[0].runtimeType) {
                throw Exception('each list-value in an addAll of a Vector must be the same type');
            }
            _canputinthevectortypecheck(c);
        });
        _list.addAll(candids);
    } 


    final CandidType? values_type;
    bool get isTypeStance => values_type != null;
    Vector({this.values_type}) {
        if (values_type!=null) {
            if (values_type.isTypeStance==false) {
                throw Exception('The Vector values_type CandidType must have .isTypeStance == true');
            }
        } 
    }
    static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i) {
        TfuncTuple values_type_t_func_tuple = TfuncWhirlpool(candidbytes, start_i);
        Vector vec = Vector(values_type: values_type_t_func_tuple.item1);
        return TfuncTuple(vec, vector_type_t_func_tuple.item2);
    } 
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        Tuple2<Uint8List,CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int vec_len = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1);
        CandidBytes_i next_vec_item_start_i = leb128_bytes_tuple.item2;
        Vector vec = Vector();
        for (int i=0;i<vec_len;i++) {
            MfuncTuple m_func_tuple = this.values_type.M(candidbytes, next_vec_item_start_i);
            vec.add(m_func_tuple.item1);
            next_vec_item_start_i = m_func_tuple.item2;
        }
        return MfuncTuple(vec, next_vec_item_start_i);
    }
}






abstract class RecordAndVariantMap extends ConstructType with MapMixin<int, CandidType> {
    final bool isTypeStance;
    RecordAndVariantMap({this.isTypeStance=false});
    Map<int, CandidType> _map = {}; // values are CandidTypes with a isTypeStance=true when its a record_type in a type_table
    Iterable<int> get keys => _map.keys.toList()..sort();
    Iterable<CandidType> get values => this.keys.map((int k)=>this[k]);
    CandidType operator [](dynamic key) { // String or int
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
    CandidType remove(Object? key) {
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
    Record({isTypeStance=false}) : super(isTypeStance: isTypeStance);
    // bool get isTypeStance {
    //     bool g = true;
    //     for (CandidType ct in this.values) { if (ct.isTypeStance==false) { g = false; } }
    //     return g;
    // }
    static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i) { 
        Record record_type = Record(isTypeStance: true);
        int record_len = candidbytes[start_i];
        CandidBytes_i next_field_start_candidbytes_i = start_i + 1;
        for (int i=0;i<record_len;i++) {
            Tuple2<Uint8List, CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, next_field_start_candidbytes_i);
            Uint8List field_id_hash_leb128_bytes = leb128_bytes_tuple.item1;
            int field_id_hash = leb128flutter.decodeUnsigned(field_id_hash_leb128_bytes);
            // throw here and in variant fieldtypes if field-id-hash is less than any of the field hashes already in the record_types
            CandidBytes_i field_type_code_byte_candidbytes_i = leb128_bytes_tuple.item2;
            TfuncTuple t_func_tuple = TfuncWhirlpool(candidbytes, field_type_code_byte_candidbytes_i);
            CandidType ctype = t_func_tuple.item1;
            next_field_start_candidbytes_i = t_func_tuple.item2;
            record_type[field_id_hash] = ctype; 
        }
        return TfuncTuple(record_type, next_field_start_candidbytes_i);
    }

    MfuncTuple M(Uint8List candidbytes, int start_i) {
        Record record = Record();
        CandidBytes_i next_i = start_i;
        for (int hash_key in this.keys) { // .toList()..sort() -> should be sorting on the keys property
            CandidType ctype = this[hash_key];
            MfuncTuple ctype_m_func_tuple = ctype.M(candidbytes, next_i);
            record[hash_key]= ctype_m_func_tuple.item1;
            next_i =        ctype_m_func_tuple.item2;
        }
        return MfuncTuple(record, next_i);            
    }

}



class Variant extends RecordAndVariantMap {
    Variant({isTypeStance=false}) : super(isTypeStance: isTypeStance);
    static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i) { 
        Variant variant_type = Variant(isTypeStance: true);
        int variant_len = candidbytes[start_i];
        CandidBytes_i next_field_start_candidbytes_i = start_i + 1;
        for (int i=0;i<variant_len;i++) {
            Tuple2<Uint8List, CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, next_field_start_candidbytes_i);
            Uint8List field_id_hash_leb128_bytes = leb128_bytes_tuple.item1;
            int field_id_hash = leb128flutter.decodeUnsigned(field_id_hash_leb128_bytes);
            CandidBytes_i field_type_code_byte_candidbytes_i = leb128_bytes_tuple.item2;
            TfuncTuple t_func_tuple = TfuncWhirlpool(candidbytes, field_type_code_byte_candidbytes_i);
            CandidType ctype = t_func_tuple.item1;
            variant_type[field_id_hash] = ctype; 
            next_field_start_candidbytes_i = t_func_tuple.item2;
        }
        return TfuncTuple(variant_type, next_field_start_candidbytes_i);


    }

    MfuncTuple M(Uint8List candidbytes, int start_i) {
        Variant variant = Variant();
        Tuple2<Uint8List, CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        Uint8List variant_field_i_leb128_bytes = leb128_bytes_tuple.item1;
        int variant_field_i = leb128flutter.decodeUnsigned(variant_field_i_leb128_bytes);
        List<int> variant_fields_hashs = this.keys.toList(); // .keys are with the sort in the RecordAndVariantMap class
        // print('variant_fields_hashs: ${variant_fields_hashs}');
        int variant_field_hash = variant_fields_hashs[variant_field_i];
        CandidType field_ctype = this[variant_field_hash];
        MfuncTuple field_m_func_tuple = field_ctype.M(candidbytes, leb128_bytes_tuple.item2);
        variant[variant_field_hash]= field_m_func_tuple.item1;
        return MfuncTuple(variant, field_m_func_tuple.item2);   
    }
}









