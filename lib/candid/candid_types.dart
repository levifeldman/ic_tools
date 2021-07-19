
// We assume that the fields in a record or variant type are sorted by increasing id and the methods in a service are sorted by name.

import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';
import 'dart:math';
import '../leb128/main.dart' show leb128flutter;
import 'package:tuple/tuple.dart';



Uint8List magic_bytes = Uint8List.fromList(utf8.encode('DIDL')); //0x4449444C


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
typedef MfuncTuple = Tuple2<dynamic,CandidBytes_i>; // M_function gives back a CandidType-stance or dart-prim-type (or null) with the values and a Candidbytes_i
typedef M_func = MfuncTuple Function(Uint8List candidbytes, int start_i);
typedef TfuncTuple = Tuple2<M_func,CandidBytes_i>; //T-function gives back a M_function , and if the T-function is: happening in the non-primitive-type: { a Tuple with a candidbytes_i }

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


TfuncTuple TfuncWhirlpool(Uint8List candidbytes, CandidBytes_i type_code_candidbytes_i) {
    int type_code = candidbytes[type_code_candidbytes_i];
    if (isPrimitiveCandidTypeCode(type_code)) {
        M_func m_func = candidtypecodesastheTfunc[type_code](); 
        return TfuncTuple(m_func, type_code_candidbytes_i + 1);
    } else if (isCandidTypeCode(type_code)) {
        TfuncTuple t_func_tuple = candidtypecodesastheTfunc[type_code](candidbytes, type_code_candidbytes_i + 1);
        return t_func_tuple;
    } else {
        // type_table_index
        M_func m_func = (Uint8List candidbytes_, CandidBytes_i start_i){
            return type_table[type_code](candidbytes, start_i);
        };
        return TfuncTuple(m_func, type_code_candidbytes_i + 1);
    }
}


List<M_func> type_table = []; 
CandidBytes_i crawl_type_table(Uint8List candidbytes) {
    type_table.clear();
    int type_table_length = candidbytes[4]; // chack what happens if there is greater than 255 itmes in the type table, is this number max 255 or is it a leb128-code[ed]-number
    CandidBytes_i next_type_start_candidbytes_i = 5;
    for (int t=0;t<type_table_length;t++) {
        TfuncTuple t_func_tuple = TfuncWhirlpool(candidbytes, next_type_start_candidbytes_i);
        M_func m_func = t_func_tuple.item1;
        next_type_start_candidbytes_i = t_func_tuple.item2;
        type_table.add(m_func);
    }
    return next_type_start_candidbytes_i;
}




abstract class CandidType {

}

abstract class PrimitiveCandidType extends CandidType {
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
    static M_func T() {
        return Null.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        return MfuncTuple(null, start_i);
    };

}


class Bool extends PrimitiveCandidType {
    static M_func T() {
        return Bool.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        return MfuncTuple(candidbytes[start_i]==1, start_i + 1);
    };

}


class Nat extends PrimitiveCandidType {
    static M_func T() {
        return Nat.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        Tuple2<Uint8List, CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int leb128_nat = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1);
        return MfuncTuple(leb128_nat, leb128_bytes_tuple.item2);
    };

} 

// test this 
class Int extends PrimitiveCandidType {
    static M_func T() {
        return Int.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        Tuple2<Uint8List, CandidBytes_i> sleb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int sleb128_int = leb128flutter.decodeSigned(sleb128_bytes_tuple.item1);
        return MfuncTuple(sleb128_int, sleb128_bytes_tuple.item2);
    };

} 

class Nat8 extends PrimitiveCandidType {
    static M_func T() {
        return Nat8.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        // String nat8_asabitstring = '';
        // for (CandidBytes_i nat8_byte_i=start_i;nat8_byte_i<start_i+1;nat8_byte_i++) {
        //     nat8_asabitstring += candidbytes[nat8_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat8_asabitstring, radix: 2);

        int value = ByteData.sublistView(candidbytes, start_i, start_i+1).getUint8(0);
        MfuncTuple m_func_tuple = MfuncTuple(value, start_i+1);
        return m_func_tuple;    
    };

} 

class Nat16 extends PrimitiveCandidType {
    static M_func T() {
        return Nat16.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        // String nat16_asabitstring = '';
        // for (CandidBytes_i nat16_byte_i=start_i;nat16_byte_i<start_i+2;nat16_byte_i++) {
        //     nat16_asabitstring += candidbytes[nat16_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat16_asabitstring, radix: 2);
        
        int value = ByteData.sublistView(candidbytes, start_i, start_i+2).getUint16(0);
        MfuncTuple m_func_tuple = MfuncTuple(value, start_i+2);
        return m_func_tuple;          
    };

} 

class Nat32 extends PrimitiveCandidType {
    static M_func T() {
        return Nat32.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        // String nat32_asabitstring = '';
        // for (CandidBytes_i nat32_byte_i=start_i;nat32_byte_i<start_i+4;nat32_byte_i++) {
        //     nat32_asabitstring += candidbytes[nat32_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat32_asabitstring, radix: 2);
        
        int value = ByteData.sublistView(candidbytes, start_i, start_i+4).getUint32(0);
        MfuncTuple m_func_tuple = MfuncTuple(value, start_i+4);
        return m_func_tuple;                 
    };

} 



class Nat64 extends PrimitiveCandidType {
    static M_func T() {
        return Nat64.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
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
        MfuncTuple m_func_tuple = MfuncTuple(value, start_i+8);
        return m_func_tuple;                 
    };

} 

class Int8 extends PrimitiveCandidType {
    static M_func T() {
        return Int8.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+1).getInt8(0);
        MfuncTuple m_func_tuple = MfuncTuple(value, start_i+1);
        return m_func_tuple;                  
    };

} 

class Int16 extends PrimitiveCandidType {
    static M_func T() {
        return Int16.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+2).getInt16(0);
        MfuncTuple m_func_tuple = MfuncTuple(value, start_i+2);
        return m_func_tuple;           
    };

} 

class Int32 extends PrimitiveCandidType {
    static M_func T() {
        return Int32.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+4).getInt32(0);
        MfuncTuple m_func_tuple = MfuncTuple(value, start_i+4);
        return m_func_tuple;            
    };

} 

class Int64 extends PrimitiveCandidType {
    static M_func T() {
        return Int64.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        int value = ByteData.sublistView(candidbytes, start_i, start_i+8).getInt64(0);
        return MfuncTuple(value, start_i+8);    // whaat bout when in javascript max integer?     
    };

} 



class Float32 extends PrimitiveCandidType {
    static M_func T() {
        return Float32.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        double value = ByteData.sublistView(candidbytes, start_i, start_i+4).getFloat32(0);
        return MfuncTuple(value, start_i+4);     
    };

} 

class Float64 extends PrimitiveCandidType {
    static M_func T() {
        return Float64.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        double value = ByteData.sublistView(candidbytes, start_i, start_i+8).getFloat64(0);
        return MfuncTuple(value, start_i+8);    
    };

} 

class Text extends PrimitiveCandidType {
    static M_func T() {
        return Text.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        Tuple2<Uint8List,CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int len_utf8_bytes = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1);
        CandidBytes_i next_i = leb128_bytes_tuple.item2 + len_utf8_bytes;
        Uint8List utf8_bytes = candidbytes.sublist(leb128_bytes_tuple.item2, next_i);
        return MfuncTuple(utf8.decode(utf8_bytes), next_i);

    };

} 

class Reserved extends PrimitiveCandidType {
    static M_func T() {
        return Reserved.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        return MfuncTuple(Reserved(), start_i);      
    };

} 

class Empty extends PrimitiveCandidType {
    static M_func T() {
        return Empty.M;
    }

    static M_func M = (Uint8List candidbytes, CandidBytes_i start_i){ 
        throw UnimplementedError('');    // NB: M(_ : empty) will never be called. 
    };

} 

// ------------------------------------


class Option extends ConstructType {
    M_func _opt_value_m_func;
    Option(this._opt_value_m_func);
    static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i) { 
        // 110
        // type_code-cursion
        TfuncTuple opt_value_t_func_tuple = TfuncWhirlpool(candidbytes, start_i);
        Option opt = Option(opt_value_t_func_tuple.item1);
        return TfuncTuple(opt.M, opt_value_t_func_tuple.item2);
    }
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        // can either be Null or the value
        throw UnimplementedError('');
        int opt_first_byte = candidbytes[start_i];
        if (opt_first_byte==0) {
            return MfuncTuple(null, start_i + 1);
        } else if (opt_first_byte==1) {
            MfuncTuple opt_value_m_func_tuple = _opt_value_m_func(candidbytes, start_i + 1);
            return opt_value_m_func_tuple;
        }
        else {
            throw Exception('candid Option M func must start with a 0 or 1 byte.');
        }
    }
}

class Vector extends ConstructType { // mixin List? or just valuate to a list.
    M_func _vector_type_m_function;
    Vector(this._vector_type_m_function);
    static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i) {
        TfuncTuple vector_type_t_func_tuple = TfuncWhirlpool(candidbytes, start_i);
        Vector vec = Vector(vector_type_t_func_tuple.item1);
        return TfuncTuple(vec.M, vector_type_t_func_tuple.item2);
    } 
    MfuncTuple M(Uint8List candidbytes, CandidBytes_i start_i) {
        Tuple2<Uint8List,CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int vec_len = leb128flutter.decodeUnsigned(leb128_bytes_tuple.item1);
        List<dynamic> vec = [];
        CandidBytes_i next_vec_item_start_i = leb128_bytes_tuple.item2;
        for (int i=0;i<vec_len;i++) {
            MfuncTuple m_func_tuple = _vector_type_m_function(candidbytes, next_vec_item_start_i);
            vec.add(m_func_tuple.item1);
            next_vec_item_start_i = m_func_tuple.item2;
        }
        return MfuncTuple(vec, next_vec_item_start_i);
    }
}






class RecordAndVariantMap extends ConstructType with MapMixin<int, dynamic> {
    Map<int, dynamic> _map = {}; // values are M_functions when its a record_type in a type_table
    Iterable<int> get keys => _map.keys.toList()..sort();
    dynamic operator [](dynamic key) {
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
    void operator []=(dynamic key, dynamic value) { // key can be String or a nat(int). if key is String it gets hashed with the candid-hash for the lookup which is: nat. 
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
        _map[k] = value;
    }
    dynamic remove(Object? key) {
        return _map.remove(key);
    }
    void clear() {
        return _map.clear();
    }
}


class Record extends RecordAndVariantMap {
    static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i) { 
        Record record_types = Record();
        int record_len = candidbytes[start_i];
        CandidBytes_i next_field_start_candidbytes_i = start_i + 1;
        for (int i=0;i<record_len;i++) {
            Tuple2<Uint8List, CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, next_field_start_candidbytes_i);
            Uint8List field_id_hash_leb128_bytes = leb128_bytes_tuple.item1;
            int field_id_hash = leb128flutter.decodeUnsigned(field_id_hash_leb128_bytes);
            // throw here and in variant fieldtypes if field-id-hash is less than any of the field hashes already in the record_types
            CandidBytes_i field_type_code_byte_candidbytes_i = leb128_bytes_tuple.item2;
            TfuncTuple t_func_tuple = TfuncWhirlpool(candidbytes, field_type_code_byte_candidbytes_i);
            M_func m_func = t_func_tuple.item1;
            next_field_start_candidbytes_i = t_func_tuple.item2;
            record_types[field_id_hash] = m_func; 
        }
        return TfuncTuple(record_types.M, next_field_start_candidbytes_i);
    }

    MfuncTuple M(Uint8List candidbytes, int start_i) {
        // print('start Record.M');
        Record record = Record();
        CandidBytes_i next_i = start_i;
        for (int hash_key in this.keys) { // .toList()..sort() -> should be sorting on the keys property
            // print(hash_key);
            // print(this[hash_key]);
            M_func field_m_func = this[hash_key];
            MfuncTuple field_m_func_tuple = field_m_func(candidbytes, next_i);
            record[hash_key]= field_m_func_tuple.item1;
            next_i =        field_m_func_tuple.item2;
            // print(record[hash_key]);
        }
        return MfuncTuple(record, next_i);            
    }

}



class Variant extends RecordAndVariantMap {
    static TfuncTuple T(Uint8List candidbytes, CandidBytes_i start_i) { 
        Variant variant_types = Variant();
        int variant_len = candidbytes[start_i];
        CandidBytes_i next_field_start_candidbytes_i = start_i + 1;
        for (int i=0;i<variant_len;i++) {
            Tuple2<Uint8List, CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, next_field_start_candidbytes_i);
            Uint8List field_id_hash_leb128_bytes = leb128_bytes_tuple.item1;
            int field_id_hash = leb128flutter.decodeUnsigned(field_id_hash_leb128_bytes);
            CandidBytes_i field_type_code_byte_candidbytes_i = leb128_bytes_tuple.item2;
            TfuncTuple t_func_tuple = TfuncWhirlpool(candidbytes, field_type_code_byte_candidbytes_i);
            M_func m_func = t_func_tuple.item1;
            next_field_start_candidbytes_i = t_func_tuple.item2;
            variant_types[field_id_hash] = m_func; 
        }
        return TfuncTuple(variant_types.M, next_field_start_candidbytes_i);


    }

    MfuncTuple M(Uint8List candidbytes, int start_i) {
        Variant variant = Variant();
        Tuple2<Uint8List, CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        Uint8List variant_field_i_leb128_bytes = leb128_bytes_tuple.item1;
        int variant_field_i = leb128flutter.decodeUnsigned(variant_field_i_leb128_bytes);
        List<int> variant_fields_hashs = this.keys.toList(); 
        // print('variant_fields_hashs: ${variant_fields_hashs}');
        int variant_field_hash = variant_fields_hashs[variant_field_i];
        M_func field_m_func = this[variant_field_hash];
        MfuncTuple field_m_func_tuple = field_m_func(candidbytes, leb128_bytes_tuple.item2);
        variant[variant_field_hash]= field_m_func_tuple.item1;
        return MfuncTuple(variant, field_m_func_tuple.item2);   
    }
}









