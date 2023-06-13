import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';
import 'dart:math';

import 'package:tuple/tuple.dart';

import './tools/tools.dart';
import './ic_tools.dart';



final Uint8List magic_bytes = Uint8List.fromList(utf8.encode('DIDL')); //0x4449444C



typedef CandidBytes_i = int;     
typedef TfuncTuple = Tuple2<CandidType,CandidBytes_i>; // T_backward gives back a CandidType-stance with isTypeStance=true for the M_backwards-function. and a Candidbytes_i for non-primitive-types
typedef MfuncTuple = Tuple2<CandidType,CandidBytes_i>; // M_backward gives back a CandidType-stance with the values and a Candidbytes_i




final Map<int, PrimitiveType> backwards_primtypes_opcodes_for_the_primtype_type_stances = { //PrimitiveType is with isTypeStance = true; 
    Null.type_code     : Null(isTypeStance: true),
    Reserved.type_code : Reserved(isTypeStance: true),
    Empty.type_code    : Empty(isTypeStance: true),
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
};

// static T_backwards functions start_i starts after the type_code-signed-leb128bytes

final Map<int, TfuncTuple Function(Uint8List candidbytes, CandidBytes_i start_i)> constypes_and_reftypes_opcodes_for_the_static_T_backwards_function = {
    Option.type_code  : Option._T_backward,
    Vector.type_code  : Vector._T_backward,
    Record.type_code  : Record._T_backward,
    Variant.type_code : Variant._T_backward,
    FunctionReference.type_code : FunctionReference._T_backward,
    ServiceReference.type_code  : ServiceReference._T_backward,
    PrincipalReference.type_code: PrincipalReference._T_backward
};

bool isPrimTypeCode(int type_code) => backwards_primtypes_opcodes_for_the_primtype_type_stances.keys.contains(type_code);
bool isConsOrRefTypeCode(int type_code) => constypes_and_reftypes_opcodes_for_the_static_T_backwards_function.keys.contains(type_code);




/// The [text-hash](https://github.com/dfinity/candid/blob/master/spec/Candid.md#shorthand-symbolic-field-ids) that is used when using a [String] for the field name of a [Record] or [Variant],
/// converting the field name to the [int] representation which is how it is sent over the wire. 
int candid_text_hash(String text) { 
    // hash(id) = ( Sum_(i=0..k) utf8(id)[i] * 223^(k-i) ) mod 2^32 where k = |utf8(id)|-1
    int hash = 0;
    for (int b in utf8.encode(text)) {
        hash = (((hash * 223) % pow(2, 32) as int) + b) % pow(2, 32) as int;  
    }
    return hash;
}




// backwards

List<CandidType> type_table = []; 

class TypeTableReference extends CandidType { 
    final bool isTypeStance = true;
    final int type_table_i; 
    
    late MfuncTuple Function(Uint8List candidbytes, CandidBytes_i start_i) m;
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) => m(candidbytes, start_i);
    
    // for the empty vector and a null-option.value so it can be backwards and then forwards 
    late CandidType Function() get_final_type_stance_f;
    CandidType get_final_type_stance() => get_final_type_stance_f();
    
    TypeTableReference(this.type_table_i) {
        m = (Uint8List candidbytes, CandidBytes_i start_i) => type_table[type_table_i]._M(candidbytes, start_i);
        
        // for the empty vector and a null-option.value so it can be backwards and then forwards    
        get_final_type_stance_f = () {
            CandidType down_the_road = type_table[type_table_i];
            if (down_the_road is TypeTableReference) {
                return down_the_road.get_final_type_stance();
            } else {
                return down_the_road;
            }
        };
    }

    Uint8List _T_forward() => throw Exception('Method not needed');
    Uint8List _M_forward() => throw Exception('Method not needed');

}

TfuncTuple crawl_type_table_whirlpool(Uint8List candidbytes, CandidBytes_i type_code_start_candidbytes_i) {
    FindLeb128BytesTuple type_code_sleb128bytes_tuple = find_leb128bytes(candidbytes, type_code_start_candidbytes_i);
    int type_code = leb128.decodeSigned(type_code_sleb128bytes_tuple.item1).toInt();
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
    dynamic type_table_length = leb128.decodeUnsigned(type_table_length_leb128bytes_tuple.item1);
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
    dynamic param_count = leb128.decodeUnsigned(param_count_leb128bytes_tuple.item1);   
    if (param_count is int) { param_count = BigInt.from(param_count); }
    CandidBytes_i params_types_next_i = param_count_leb128bytes_tuple.item2;
    List<int> params_type_codes = [];
    for (BigInt i=BigInt.from(0);i<param_count;i=i+BigInt.one) {
        FindLeb128BytesTuple type_code_sleb128bytes_tuple = find_leb128bytes(candidbytes, params_types_next_i);
        int type_code = leb128.decodeSigned(type_code_sleb128bytes_tuple.item1).toInt();
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
        } else if (type_code == PrincipalReference.type_code) {
            ctype = PrincipalReference(isTypeStance: true);
        } else {
            throw Exception('params_list_types codes can either be a type_table_i or a primtypecode or a principal-reference'); // this is because a PrincipalReference even though not a primitive-type it is considered a non-composite type because its T-function has only its type_code so it is not put in the type-table.
        }

        MfuncTuple ctype_m_func_tuple = ctype._M(candidbytes, next_param_value_start_i);
        CandidType cvalue = ctype_m_func_tuple.item1;
        if (cvalue.isTypeStance==true) { throw Exception('M functions need to return a CandidType with an isTypeStance=false'); }
        candids.add(cvalue);
        next_param_value_start_i = ctype_m_func_tuple.item2;
    }
    type_table.clear();
    return candids;
}


// backwards
/// De-serialize bytes into a List of [CandidType]s.
List<CandidType> c_backwards(Uint8List candidbytes) {
    try {
        if (candidbytes.length < 6) { throw Exception('candidbytes are a minimum of 6 bytes.'); }
        if (!(aresamebytes(candidbytes.sublist(0, 4), magic_bytes))) { throw Exception(':void: magic-bytes.'); }
        CandidBytes_i param_count_i = crawl_type_table(candidbytes);
        List<CandidType> candids = crawl_memory_bytes(candidbytes, param_count_i);
        return candids;
    } catch(e) {
        print('candid: $candidbytes');
        throw e;
    }
}
// can't take a T type param and return it cast it bc it might be a non-null option value but sent as the value itself without the option. candid subtyping rules.
/// Like [c_backwards] but returns one value. When the caller knows that the response contains only one value this is convenient.
CandidType c_backwards_one(Uint8List candidbytes) {
    return c_backwards(candidbytes).first;
}


// forwards
List<List<int>> type_table_forward = []; // each [inner] list is a candid(cons)types._T_forward() 

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
/// Serialize a List of [CandidType]s into the binary over-the-wire format.
Uint8List c_forwards(List<CandidType> candids) {
    candids.forEach((CandidType c){ if (c.isTypeStance==true) { throw Exception('c_forwards must be with the candids of the isTypeStance=false'); }});
    List<int> candidbytes = magic_bytes.toList();
    List<int> params_list_types_bytes_section = [];
    List<int> params_list_values_bytes_section = [];
    for (CandidType candid in candids) {
        params_list_types_bytes_section.addAll(candid._T_forward()); // sleb128-bytes() of either primtype -opcode or type_table_i    // composite-types (types with a T-function that has more data/parameters beside the opcode) use the type_table_forward list for the T function to put the types and gives back the type_table_i-leb128-code-bytes. 
        params_list_values_bytes_section.addAll(candid._M_forward()); 
    }
    candidbytes.addAll(leb128.encodeUnsigned(BigInt.from(type_table_forward.length)));
    for (List<int> type_bytes in type_table_forward) { candidbytes.addAll(type_bytes); }
    candidbytes.addAll(leb128.encodeUnsigned(BigInt.from(candids.length)));
    candidbytes.addAll(params_list_types_bytes_section);
    candidbytes.addAll(params_list_values_bytes_section);
    type_table_forward.clear();
    return Uint8List.fromList(candidbytes);
}
/// Like [c_forwards] but when serializing a single value this is convenient.
Uint8List c_forwards_one(CandidType c) {
    return c_forwards([c]);
}



abstract class CandidType {
    bool get isTypeStance;
    
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i);
    
    Uint8List _T_forward();
    Uint8List _M_forward();
    
    /// Useful when deserializing an Option Response but working with Candid's subtyping rules.
    /// Candid's rules state that an Option with a non-null value can be sent as the value itself without the Option wrapping it. 
    /// This function makes that check for you and returns the Option type even if the value is sent by itself for the consistency.    
    /// ```dart
    /// Uint8List candidbytes = ...;
    /// Option<Nat> optional_nat = CandidType.as_option<Nat>(c_backwards_one(candidbytes));
    /// ```
    static Option<T> as_option<T extends CandidType>(CandidType option) {
        if (option is Option) {
            return (option as Option).cast_option<T>();
        } else {
            return Option<T>(value: option as T);
        }
    }
}


abstract class PrimitiveType extends CandidType {
    final _v = null;
    dynamic get value;
    bool get isTypeStance => this._v == null;

    String toString() {
        String s = get_typename_ofthe_toString(super.toString());
        return this._v != null ? s + ': ${this._v}' : s;
    }

}




class Null extends PrimitiveType {
    static const int type_code = -1;
    get value => throw Exception('CandidType: Null is with the lack of a value.'); 
    final bool isTypeStance;
    Null({this.isTypeStance = false});

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) {
        return MfuncTuple(Null(), start_i);
    }

    Uint8List _M_forward() {
        return Uint8List(0);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Null.type_code);
    }

    String toString() => 'Null';  
}

class Reserved extends PrimitiveType {
    static const int type_code = -16;
    get value => throw Exception('CandidType: Reserved is with the lack of a value.');
    final bool isTypeStance;
    Reserved({this.isTypeStance = false});
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        return MfuncTuple(Reserved(), start_i);      
    }
    
    Uint8List _M_forward() {
        return Uint8List(0);
    }

    Uint8List _T_forward() {
        return leb128.encodeSigned(Reserved.type_code);
    }

    String toString() => 'Reserved';  
} 

class Empty extends PrimitiveType {
    static const int type_code = -17;
    get value => throw Exception('CandidType: Empty is with the lack of a value.');
    final bool isTypeStance;
    Empty({this.isTypeStance = false});
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        throw Exception('_M(_ : empty) will never be called.'); 
    }

    Uint8List _M_forward () {
        throw Exception('_M(_ : empty) will never be called.'); 
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Empty.type_code);
    }

    String toString() => 'Empty';  
} 


class Bool extends PrimitiveType {
    static const int type_code = -2;
    final bool? _v;
    Bool([this._v]);
    
    bool get value => this._v!;

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) {
        return MfuncTuple(Bool(candidbytes[start_i]==1), start_i + 1);
    }

    Uint8List _M_forward() {
        Uint8List l = Uint8List(1);
        l[0] = this.value==true ? 1 : 0;
        return l;
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Bool.type_code);
    }

}


class Nat extends PrimitiveType {
    static const int type_code = -3;
    final BigInt? _v;
    Nat([this._v]) {
        if (_v != null) {
            if (_v! < BigInt.from(0)) {
                throw Exception('CandidType: Nat can only hold a value >=0 ');
            }
        
        }    
    }
    
    BigInt get value => this._v!;

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        FindLeb128BytesTuple leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        BigInt leb128_nat = leb128.decodeUnsigned(leb128_bytes_tuple.item1);
        return MfuncTuple(Nat(leb128_nat), leb128_bytes_tuple.item2);
    }

    Uint8List _M_forward() {
        return leb128.encodeUnsigned(this.value);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Nat.type_code);
    }

} 

class Int extends PrimitiveType {
    static const int type_code = -4;
    final BigInt? _v;
    Int([this._v]) {
        
    }
    
    BigInt get value => this._v!;

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        FindLeb128BytesTuple sleb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        BigInt sleb128_int = leb128.decodeSigned(sleb128_bytes_tuple.item1);
        return MfuncTuple(Int(sleb128_int), sleb128_bytes_tuple.item2);
    }
    
    Uint8List _M_forward() {
        return leb128.encodeSigned(this.value);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Int.type_code);
    }

} 

class Nat8 extends PrimitiveType {
    static const int type_code = -5;
    final int? _v;
    Nat8([this._v]) {
        if (_v != null) {
            if (_v! < 0 || _v! > pow(2, 8)-1 ) {
                throw Exception('CandidType: Nat8 value can be between 0<=value && value <= 255 ');
            }
        }
    }
    
    int get value => this._v!;
 
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        MfuncTuple m_func_tuple = MfuncTuple(Nat8(candidbytes[start_i]), start_i+1);
        return m_func_tuple;    
    }
    
    Uint8List _M_forward() {
        return Uint8List.fromList([this.value]);
    }

    Uint8List _T_forward() {
        return leb128.encodeSigned(Nat8.type_code);
    }

} 

class Nat16 extends PrimitiveType {
    static const int type_code = -6;
    final int? _v;
    Nat16([this._v]) {
        if (_v!=null) {
            if (_v! < 0 || _v! > pow(2, 16)-1 ) {
                throw Exception('CandidType: Nat16 value can be between 0<=value && value <= ${pow(2, 16)-1} ');            
            }
        }    
    }
    
    int get value => this._v!;
    
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // String nat16_asabitstring = '';
        // for (CandidBytes_i nat16_byte_i=start_i;nat16_byte_i<start_i+2;nat16_byte_i++) {
        //     nat16_asabitstring += candidbytes[nat16_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat16_asabitstring, radix: 2);
        
        int v = ByteData.sublistView(candidbytes, start_i, start_i+2).getUint16(0, Endian.little);
        MfuncTuple m_func_tuple = MfuncTuple(Nat16(v), start_i+2);
        return m_func_tuple;          
    }

    Uint8List _M_forward() {
        String rstr = this.value.toRadixString(2);
        while (rstr.length<16) {
            rstr = '0' + rstr;
        }
        List<int> bytes = [];
        for (int i=0;i<2;i++) {
            bytes.add(int.parse(rstr.substring(i*8, i*8+8), radix: 2));   
        }
        return Uint8List.fromList(bytes.reversed.toList());// as Uint8List;
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Nat16.type_code);
    }


} 

class Nat32 extends PrimitiveType {
    static const int type_code = -7;
    final int? _v;
    Nat32([this._v]) {
        if (_v!=null) {
            if (_v! < 0 || _v! > pow(2, 32)-1 ) {
                throw Exception('CandidType: Nat32 value can be between 0<=value && value <= ${pow(2, 32)-1} ');
            }
        }
    }
    
    int get value => this._v!;
    
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // String nat32_asabitstring = '';
        // for (CandidBytes_i nat32_byte_i=start_i;nat32_byte_i<start_i+4;nat32_byte_i++) {
        //     nat32_asabitstring += candidbytes[nat32_byte_i].toRadixString(2); 
        // }
        // int value = int.parse(nat32_asabitstring, radix: 2);
        
        int v = ByteData.sublistView(candidbytes, start_i, start_i+4).getUint32(0, Endian.little);
        MfuncTuple m_func_tuple = MfuncTuple(Nat32(v), start_i+4);
        return m_func_tuple;                 
    }

    Uint8List _M_forward() {
        String rstr = this.value.toRadixString(2);
        while (rstr.length<32) {
            rstr = '0' + rstr;
        }
        List<int> bytes = [];
        for (int i=0;i<4;i++) {
            bytes.add(int.parse(rstr.substring(i*8, i*8+8), radix: 2));   
        }
        return Uint8List.fromList(bytes.reversed.toList());
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Nat32.type_code);
    }
} 



class Nat64 extends PrimitiveType {
    static const int type_code = -8;
    final BigInt? _v; // BigInt bc of the dart on the web is with the int-max-size: 2^53
    Nat64([this._v]) {
        if (_v != null) {
            if (_v! < BigInt.from(0) || _v! > BigInt.from(2).pow(64)-BigInt.from(1)) {
                throw Exception('CandidType: Nat64 value can be between 0<=value && value <= ${BigInt.from(2).pow(64)-BigInt.from(1)} ');
            }
        }
    }
    
    BigInt get value => this._v!;
    
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        // get BigInt/int of the candid_nat64 
        String nat64_asabitstring = bytes_as_the_bitstring(Uint8List.fromList(candidbytes.sublist(start_i, start_i + 8).reversed.toList()));
        BigInt va = BigInt.parse(nat64_asabitstring, radix: 2);
        MfuncTuple m_func_tuple = MfuncTuple(Nat64(va), start_i+8);
        return m_func_tuple;                 
    }

    Uint8List _M_forward() {
        String rstr = this.value.toRadixString(2);
        while (rstr.length<64) {
            rstr = '0' + rstr;
        }
        List<int> bytes = [];
        for (int i=0;i<8;i++) {
            bytes.add(int.parse(rstr.substring(i*8, i*8+8), radix: 2));   
        }
        return Uint8List.fromList(bytes.reversed.toList());
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Nat64.type_code);
    }

} 

class Int8 extends PrimitiveType {
    static const int type_code = -9;
    final int? _v;
    Int8([this._v]) {
        if (_v!=null) {
            if ( _v! < -128 || _v! > 127 ) {
                throw Exception('CandidType: Int8 value must be between -128<=value && value <=127');
            }
        } 
    }
    
    int get value => this._v!;
    
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int v = ByteData.sublistView(candidbytes, start_i, start_i+1).getInt8(0);
        MfuncTuple m_func_tuple = MfuncTuple(Int8(v), start_i+1);
        return m_func_tuple;                  
    }

    Uint8List _M_forward() {
        ByteData bytedata = ByteData(1);
        bytedata.setInt8(0, this.value);
        return Uint8List.view(bytedata.buffer);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Int8.type_code);
    }

} 

class Int16 extends PrimitiveType {
    static const int type_code = -10;
    final int? _v;
    Int16([this._v]) {
        if (_v!=null) {
            if (_v! < pow(-2,15) || _v! > pow(2,15)-1 ) {
                throw Exception('CandidType: Int16 value must be between ${pow(-2,15)} <= value && value <= ${pow(2,15)-1}');
            }
        }
    }
    
    int get value => this._v!;
    
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int v = ByteData.sublistView(candidbytes, start_i, start_i+2).getInt16(0, Endian.little);
        MfuncTuple m_func_tuple = MfuncTuple(Int16(v), start_i+2);
        return m_func_tuple;           
    }

    Uint8List _M_forward() {
        ByteData bytedata = ByteData(2);
        bytedata.setInt16(0, this.value, Endian.little);
        return Uint8List.view(bytedata.buffer);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Int16.type_code);
    }
} 

class Int32 extends PrimitiveType {
    static const int type_code = -11;
    final int? _v;
    Int32([this._v]) {
        if (_v!=null) { 
            if (_v! < pow(-2,31) || _v! > pow(2,31)-1 ) {
                throw Exception('CandidType: Int32 value must be between ${pow(-2,31)} <= value && value <= ${pow(2,31)-1}');
            }
        }
    }
    
    int get value => this._v!;
    
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        int v = ByteData.sublistView(candidbytes, start_i, start_i+4).getInt32(0, Endian.little);
        MfuncTuple m_func_tuple = MfuncTuple(Int32(v), start_i+4);
        return m_func_tuple;            
    }

    Uint8List _M_forward() {
        ByteData bytedata = ByteData(4);
        bytedata.setInt32(0, this.value, Endian.little);
        return Uint8List.view(bytedata.buffer);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Int32.type_code);
    }
} 

class Int64 extends PrimitiveType {
    static const int type_code = -12;
    final BigInt? _v;
    Int64([this._v]) {
        if (_v != null) {
            if (_v! < BigInt.from(-2).pow(63) || _v! > BigInt.from(2).pow(63)-BigInt.from(1)) {
                throw Exception('CandidType: Int64 value can be between ${BigInt.from(-2).pow(63)}<=value && value <= ${BigInt.from(2).pow(63)-BigInt.from(1)} ');
            }
        }
    }
    
    BigInt get value => this._v!;
    
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        String int64_asabitstring = bytes_as_the_bitstring(Uint8List.fromList(candidbytes.sublist(start_i, start_i + 8).reversed.toList())); // .reverse for the little-endian
        BigInt v = twos_compliment_bitstring_as_the_bigint(int64_asabitstring, bit_size: 64); // int or BigInt
        return MfuncTuple(Int64(v), start_i+8);
    }

    Uint8List _M_forward() {
        String tc_bitstring = bigint_as_the_twos_compliment_bitstring(this.value, bit_size: 64);
        Uint8List bytes = bitstring_as_the_bytes(tc_bitstring);
        return Uint8List.fromList(bytes.reversed.toList());        
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Int64.type_code);
    }
} 

class Float32 extends PrimitiveType {
    static const int type_code = -13;
    final double? _v;
    Float32([this._v]) {
        // :do: make this limit the range of the values for the single-presscission
    }

    double get value => this._v!;

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        double v = ByteData.sublistView(candidbytes, start_i, start_i+4).getFloat32(0, Endian.little);
        return MfuncTuple(Float32(v), start_i+4);     
    }

    Uint8List _M_forward() {
        ByteData bytedata = ByteData(4);
        bytedata.setFloat32(0, this.value, Endian.little);
        return Uint8List.view(bytedata.buffer);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Float32.type_code);
    }

} 


class Float64 extends PrimitiveType {
    static const int type_code = -14;
    final double? _v;
    Float64([this._v]);

    double get value => this._v!;

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        double v = ByteData.sublistView(candidbytes, start_i, start_i+8).getFloat64(0, Endian.little);
        return MfuncTuple(Float64(v), start_i+8);    
    }

    Uint8List _M_forward() {
        ByteData bytedata = ByteData(8);
        bytedata.setFloat64(0, this.value, Endian.little);
        return Uint8List.view(bytedata.buffer);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Float64.type_code);
    }

} 

class Text extends PrimitiveType {
    static const int type_code = -15;
    final String? _v;
    Text([this._v]);

    String get value => this._v!;

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) { 
        Tuple2<Uint8List,CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int len_utf8_bytes = leb128.decodeUnsigned(leb128_bytes_tuple.item1).toInt();
        CandidBytes_i next_i = leb128_bytes_tuple.item2 + len_utf8_bytes;
        Uint8List utf8_bytes = candidbytes.sublist(leb128_bytes_tuple.item2, next_i);
        return MfuncTuple(Text(utf8.decode(utf8_bytes)), next_i);
    }

    Uint8List _M_forward() {
        List<int> bytes = [];
        bytes.addAll(leb128.encodeUnsigned(this.value.length));
        bytes.addAll(utf8.encode(this.value));
        return Uint8List.fromList(bytes);
    }
    
    Uint8List _T_forward() {
        return leb128.encodeSigned(Text.type_code);
    }
} 


// ------------------------------------

// M_backward-functions must give-back a new stance.



abstract class ConstructType extends CandidType {}


/// Option candid type.
/// 
/// ```dart
/// var non_null_optional_text = Option(value: Text('hi'));
/// var null_optional_text = Option(value: null, value_type: Text());
/// ```
/// Check the documentation on the [candid] library page for more on creating an Option with a null value.
class Option<T extends CandidType?> extends ConstructType {
    static const int type_code = -18;
    /// The value within the Option. Can be set to null. When setting to null make sure the [value_type] is specified. Check the documentation on the [candid] library page for more.  
    late final T? value; 
    /// A [CandidType] in the TypeStance mode. Check the documentation on the [candid] library page for more.
    late final T? value_type;
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
    
    /// Casts an [Option<CandidType>] into an [Option<C extends CandidType>].
    /// Useful for casting the type of [this.value] into a **specific** [CandidType]
    Option<C> cast_option<C extends CandidType>() {
        return Option<C>(
            value: this.value == null ? null : C == Blob ? Blob.oftheVector((this.value as Vector).cast_vector<Nat8>()) as C : this.value as C, 
            value_type: this.value_type == null ? null : C == Blob ? Blob([],isTypeStance:true) as C : this.value_type as C, 
            isTypeStance: this.isTypeStance
        );
    }

    static TfuncTuple _T_backward(Uint8List candidbytes, CandidBytes_i start_i) { 
        // type_code-whirlpool
        TfuncTuple value_t_func_tuple = crawl_type_table_whirlpool(candidbytes, start_i);
        Option opt_type = Option(value_type: value_t_func_tuple.item1, isTypeStance: true);
        return TfuncTuple(opt_type, value_t_func_tuple.item2);
    }
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) {
        int opt_first_byte = candidbytes[start_i];
        late CandidBytes_i next_i;
        late CandidType? val; 
        if (opt_first_byte==0) {
            val = null;
            next_i = start_i + 1;
        } else if (opt_first_byte==1) {
            MfuncTuple value_type_m_func_tuple = this.value_type!._M(candidbytes, start_i + 1);
            val = value_type_m_func_tuple.item1;
            next_i = value_type_m_func_tuple.item2;
        }
        else {
            throw Exception('candid Option M bytes must start with a 0 or 1 byte.');
        }
        Option opt = Option(value: val, value_type: this.value_type is TypeTableReference ? (this.value_type as TypeTableReference).get_final_type_stance() : this.value_type); // this.value_type could be a type_table_i
        return MfuncTuple(opt, next_i);
    }

    Uint8List _T_forward() {
        List<int> t_bytes = [];
        t_bytes.addAll(leb128.encodeSigned(Option.type_code));
        Uint8List value_type_t_forward_bytes = this.value != null ? this.value!._T_forward() : this.value_type!._T_forward();
        t_bytes.addAll(value_type_t_forward_bytes);
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128.encodeSigned(type_table_i); 
    }

    Uint8List _M_forward() {
        List<int> bytes = [];
        if (this.value == null) {
            bytes.add(0);
        } else if (this.value != null) {
            bytes.add(1);
            bytes.addAll(this.value!._M_forward());
        }
        return Uint8List.fromList(bytes);
    }

    String toString() {
        return 'Option: ${this.value}';
    }
}

/// Vector candid type with a [ListMixin].
/// 
/// Creating a Vector.
/// ```dart
/// var vector_of_text = Vector.oftheList([Text('hi'), Text('The sky is blue')]);
/// var empty_vector_of_text = Vector.oftheList([], values_type: Text()); 
/// ```
/// Check the documentation on the [candid] library page for more on creating an empty Vector with a length of 0.
class Vector<T extends CandidType> extends ConstructType with ListMixin<T> {         
    static const int type_code = -19;
    final T? values_type; // use if want to serialize an empty vector or when creating a type-finition/type-stance/isTypeStance=true
    final bool isTypeStance;
    Vector({this.values_type, this.isTypeStance= false}) {
        /*if (this.values_type == null && this.length == 0) {
            throw Exception('candid cannot conclude the type of the items in this vector. candid c_forward needs the type of the vector-values to serialize a Vector. either put a candidtype in this vector .add(Nat(548)) .  or if you want the vector to be empty, give a values_type-parameter of a candidtype with isTypeStance: true, when creating this vector. Vector(values_type: Int64()/Text()/Record.oftheMap({\'key\': Nat()}, isTypeStance: true)/...)');
        }*/
    }

    static Vector<T> oftheList<T extends CandidType>(Iterable<T> list, {T? values_type}) {
        Vector<T> vec = Vector<T>(values_type: values_type);
        vec.addAll(list);
        return vec;
    }

    Vector<C> cast_vector<C extends CandidType>() => Vector.oftheList<C>(this.cast<C>());
    
    List<T> _list = <T>[];
    _canputinthevectortypecheck(/*T new_c*/) {
        if (this.isTypeStance == true) { 
            throw Exception('a Vector with a isTypeStance=true is a vector-[in]stance of a vector-type(the type of the vectors values), if you want to put CandidType values in a vector, create a new Vector().');
        }
        /*
        if (this.values_type != null) {
            if (this.values_type.runtimeType != new_c.runtimeType) {
                throw Exception('if the Vector has a values_type-field , the candidtype of the vector-values must match the candidtype of the values_type-field. this.values_type.runtimeType: ${this.values_type.runtimeType}, new_c.runtimeType: ${new_c.runtimeType}');
            }
        }
        if (_list.length > 0) {
            _list.forEach((T list_c) {
                if (list_c.runtimeType != new_c.runtimeType) { throw Exception(':CandidType-values in a Vector-list are with the quirement of the same-specific-candidtype-type. :type of the vector-values-now: ${this[0].runtimeType}.'); }
            });
        }
        done by the T
        */
    }
    int get length => _list.length;
    set length(int l) => throw Exception('why are you setting the length of the vector here?');
    T operator [](int i) => _list[i];
    void operator []=(int i, T c) { 
        _canputinthevectortypecheck();
        _list[i] = c;
    }
    void add(T c) { 
        _canputinthevectortypecheck();
        _list.add(c);
    }
    void addAll(Iterable<T> candids) {    
        /*
        candids.forEach((T c){
            if (c.runtimeType != candids.first.runtimeType) {
                throw Exception('each list-value in an addAll of a Vector must be the same type');
            }
            
            _canputinthevectortypecheck(c);
        });
        */
        _canputinthevectortypecheck();
        _list.addAll(candids);
    } 


    static TfuncTuple _T_backward(Uint8List candidbytes, CandidBytes_i start_i) {
        TfuncTuple values_type_t_func_tuple = crawl_type_table_whirlpool(candidbytes, start_i);
        Vector vec = Vector(values_type: values_type_t_func_tuple.item1, isTypeStance: true);
        return TfuncTuple(vec, values_type_t_func_tuple.item2);
    } 
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) {
        Tuple2<Uint8List,CandidBytes_i> leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        BigInt vec_len_b = leb128.decodeUnsigned(leb128_bytes_tuple.item1);
        late int vec_len;
        if (vec_len_b.isValidInt) {
            vec_len = vec_len_b.toInt();  
        } else {
            throw Exception('these candid-bytes are too big for this dart code to handle, there are more than 2^64 bytes. these candid-bytes are held in lists and a dart-list can only index up to 2^64-1, the max of the dart-int. ');
        }
        late Vector vec;
        CandidBytes_i next_vec_item_start_i = leb128_bytes_tuple.item2;
        if (this.values_type! is Nat8) {
            CandidBytes_i finish_nat8s_i = next_vec_item_start_i + vec_len;
            vec = Blob(candidbytes.sublist(next_vec_item_start_i, finish_nat8s_i));
            next_vec_item_start_i = finish_nat8s_i;
        } else {
            vec = Vector(values_type: this.values_type is TypeTableReference ? (this.values_type as TypeTableReference).get_final_type_stance() : this.values_type);
            for (int i=0;i<vec_len;i=i+1) {
                MfuncTuple m_func_tuple = this.values_type!._M(candidbytes, next_vec_item_start_i);
                vec.add(m_func_tuple.item1);
                next_vec_item_start_i = m_func_tuple.item2;
            }
        }
        return MfuncTuple(vec, next_vec_item_start_i);
    }

    Uint8List _T_forward() {
        List<int> t_bytes = [];
        t_bytes.addAll(leb128.encodeSigned(Vector.type_code));
        if (this.values_type == null && this.length == 0) {
            throw Exception('candid cannot conclude the type of the items in this vector. candid c_forward needs a vector-values-type to serialize a Vector. either put a candidtype in this vector .add(Nat(548)) .  or if you want the vector to be empty, give a values_type-param when creating this vector. Vector(values_type: Int64()/Text()/...)');
        }
        Uint8List values_type_t_forward_bytes = this.values_type != null ? this.values_type!._T_forward() : this[0]._T_forward();
        t_bytes.addAll(values_type_t_forward_bytes);
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128.encodeSigned(type_table_i);
    }

    Uint8List _M_forward() {
        List<int> m_bytes = [];
        m_bytes.addAll(leb128.encodeUnsigned(this.length));
        for (CandidType c in this) {
            m_bytes.addAll(c._M_forward());
        }
        return Uint8List.fromList(m_bytes);
    }
}

/// Blob extends Vector<Nat8> with useful functionality for direct handling of the bytes of a Blob without the [Nat8] type in between.
class Blob extends Vector<Nat8> { 
    Blob(Iterable<int> bytes_list, {super.isTypeStance = false}) : super(values_type: Nat8()) {
        if (bytes_list.length > 0) {
            this.addAll_bytes(bytes_list);
        }
    }
    static Blob oftheVector(Vector<Nat8> vecnat8) {
        return Blob(vecnat8.map<int>((Nat8 nat8byte)=>nat8byte.value).toList());
    }
    /// Turns this list of [Nat8]s into standard dart bytes [Uint8List].
    Uint8List get bytes {
        List<int> l = map((Nat8 nat8byte)=>nat8byte.value).toList();
        return Uint8List.fromList(l); 
    } 
    void add_byte(int byte) { 
        super.add(Nat8(byte));
    }
    void addAll_bytes(Iterable<int> bytes_list) {  
        super.addAll(bytes_list.map<Nat8>((int byte)=>Nat8(byte)));
    }
    int get_byte_i(int i) {
        Nat8 nat8byte = this[i];
        return nat8byte.value;
    }
    
    String toString() => this.bytes.toString();
}





abstract class RecordAndVariantMap extends ConstructType with MapMixin<int, CandidType> {
    final bool isTypeStance;
    RecordAndVariantMap({this.isTypeStance=false});
    Map<int, CandidType> _map = {}; // values are CandidTypes with a isTypeStance=true when this is a record_type of a type_table
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
                throw Exception('candid fieldtype-id as an int needs to be < 2^32. "An id value must be smaller than 2^32." ');
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
    bool containsKey(dynamic key) {
        if (key is! String && key is! int) {
            throw Exception('must pass either a String or an int for a Record field lookup');
        } 
        return key is String ? super.containsKey(candid_text_hash(key)) : super.containsKey(key);
    }
}

/// A Record is structured using a [Map] structure.
///
/// The [Map] keys are of the type [int] and the values are [CandidType]s.
/// It is possible to use a [String] for the field-name when setting a field or looking up a value, 
/// however the [String] field-name gets converted into an [int] using the [candid_text_hash] according to the candid-specification. 
/// So when iterating through the keys/field-names of the Record the key is an [int] type. 
/// Use the [candid_text_hash] function to get the [int] representation of a [String] field-name.
/// Creating a Record.
/// ```dart
/// var record = Record.oftheMap({
///     'greeting': Text('Hi'),
///     'name': Text('Bob'),
///     'address_info': Record.oftheMap({
///         'zip_code': Nat(12345),
///         'street_name': Text('Mountain'),
///     }),
///     'ready': Bool(true)
/// });
///
/// var tuple_style_record = Record.oftheMap({
///     0: Nat(5),
///     1: Text('green')
/// });
/// ```
class Record extends RecordAndVariantMap {
    static const int type_code = -20;
    Record({isTypeStance=false}) : super(isTypeStance: isTypeStance);
    
    static oftheMap(Map<dynamic, CandidType> record_map, {isTypeStance=false}) { // Map<String or int, CandidType>
        Record record = Record(isTypeStance: isTypeStance);
        for (MapEntry mkv in record_map.entries) { record[mkv.key] = mkv.value; }
        return record;
    }
    
    /// Candid subtyping rules state that an [Option] can be missing within a record if it is sent with a null-value.
    /// Use this function when looking for an [Option] in a [Record].
    /// [key] can be a [String] or an [int].
    T? find_option<T extends CandidType>(dynamic key) {
        if (this.containsKey(key)) {
            return CandidType.as_option<T>(this[key]!).value;   
        }   
        return null;
    }
    
    static TfuncTuple _T_backward(Uint8List candidbytes, CandidBytes_i start_i) { 
        Record record_type = Record(isTypeStance: true);
        FindLeb128BytesTuple record_len_find_leb128bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic record_len = leb128.decodeUnsigned(record_len_find_leb128bytes_tuple.item1);
        if (record_len is int) { record_len = BigInt.from(record_len); }
        CandidBytes_i next_field_start_candidbytes_i = record_len_find_leb128bytes_tuple.item2;
        for (BigInt i=BigInt.from(0);i<record_len;i=i+BigInt.one) {
            FindLeb128BytesTuple leb128_bytes_tuple = find_leb128bytes(candidbytes, next_field_start_candidbytes_i);
            Uint8List field_id_hash_leb128_bytes = leb128_bytes_tuple.item1;
            int field_id_hash = leb128.decodeUnsigned(field_id_hash_leb128_bytes).toInt();
            for (int k in record_type.keys) {
                if (k >= field_id_hash) {
                    throw Exception('key of the record is out of order');
                }
            }
            CandidBytes_i field_type_code_byte_candidbytes_i = leb128_bytes_tuple.item2;
            TfuncTuple t_func_tuple = crawl_type_table_whirlpool(candidbytes, field_type_code_byte_candidbytes_i);
            CandidType ctype = t_func_tuple.item1;
            next_field_start_candidbytes_i = t_func_tuple.item2;
            record_type[field_id_hash] = ctype; 
        }
        return TfuncTuple(record_type, next_field_start_candidbytes_i);
    }

    MfuncTuple _M(Uint8List candidbytes, int start_i) {
        Record record = Record();
        CandidBytes_i next_i = start_i;
        for (int hash_key in this.keys) { //  is with the sort on the keys property
            CandidType ctype = this[hash_key]!;
            MfuncTuple ctype_m_func_tuple = ctype._M(candidbytes, next_i);
            record[hash_key]= ctype_m_func_tuple.item1;
            next_i =        ctype_m_func_tuple.item2;
        }
        return MfuncTuple(record, next_i);            
    }

    Uint8List _T_forward() {
        List<int> t_bytes = [];
        t_bytes.addAll(leb128.encodeSigned(Record.type_code));
        Iterable<int> hash_keys = this.keys;
        t_bytes.addAll(leb128.encodeUnsigned(hash_keys.length));
        for (int hash_key in hash_keys) {
            t_bytes.addAll(leb128.encodeUnsigned(hash_key));
            t_bytes.addAll(this[hash_key]!._T_forward());
        }
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128.encodeSigned(type_table_i);
    }

    Uint8List _M_forward() {
        List<int> m_bytes = [];
        for (int hashkey in this.keys) {
            m_bytes.addAll(this[hashkey]!._M_forward());
        } 
        return Uint8List.fromList(m_bytes);
    }

}


/// A Variant is structured using a [Map] structure.
///  
/// Only **one** field key and value is needed to specify the chosen variant and value.
/// ```dart
/// var variant = Variant.oftheMap({
///     'blue': Nat(555)
/// });
/// ```
/// For variant types without associated values such as: `variant {install; reinstall; upgrade}`, the field value is the [Null] type.
/// ```dart
/// var variant = Variant.oftheMap({
///     'upgrade': Null()
/// });
/// ```
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
    
    static TfuncTuple _T_backward(Uint8List candidbytes, CandidBytes_i start_i) { 
        Variant variant_type = Variant(isTypeStance: true);
        FindLeb128BytesTuple variant_type_len_leb128bytes_tuple = find_leb128bytes(candidbytes, start_i);
        dynamic variant_len = leb128.decodeUnsigned(variant_type_len_leb128bytes_tuple.item1);
        if (variant_len is int) { variant_len = BigInt.from(variant_len); }
        CandidBytes_i next_field_start_candidbytes_i = variant_type_len_leb128bytes_tuple.item2;
        for (BigInt i=BigInt.from(0);i < variant_len;i=i+BigInt.one) {
            FindLeb128BytesTuple leb128_bytes_tuple = find_leb128bytes(candidbytes, next_field_start_candidbytes_i);
            Uint8List field_id_hash_leb128_bytes = leb128_bytes_tuple.item1;
            int field_id_hash = leb128.decodeUnsigned(field_id_hash_leb128_bytes).toInt();
            for (int k in variant_type.keys) {
                if (k >= field_id_hash) {
                    throw Exception('key of the variant is out of order');
                }
            }
            CandidBytes_i field_type_code_byte_candidbytes_i = leb128_bytes_tuple.item2;
            TfuncTuple t_func_tuple = crawl_type_table_whirlpool(candidbytes, field_type_code_byte_candidbytes_i);
            CandidType ctype = t_func_tuple.item1;
            variant_type[field_id_hash] = ctype; 
            next_field_start_candidbytes_i = t_func_tuple.item2;
        }
        return TfuncTuple(variant_type, next_field_start_candidbytes_i);


    }

    MfuncTuple _M(Uint8List candidbytes, int start_i) {
        Variant variant = Variant();
        FindLeb128BytesTuple leb128_bytes_tuple = find_leb128bytes(candidbytes, start_i);
        Uint8List variant_field_i_leb128_bytes = leb128_bytes_tuple.item1;
        int variant_field_i = leb128.decodeUnsigned(variant_field_i_leb128_bytes).toInt();
        List<int> variant_fields_hashs = this.keys.toList();
        int variant_field_hash = variant_fields_hashs[variant_field_i];
        CandidType field_ctype = this[variant_field_hash]!;
        MfuncTuple field_m_func_tuple = field_ctype._M(candidbytes, leb128_bytes_tuple.item2);
        variant[variant_field_hash]= field_m_func_tuple.item1;
        return MfuncTuple(variant, field_m_func_tuple.item2);   
    }

    Uint8List _T_forward() {
        List<int> t_bytes = [];
        t_bytes.addAll(leb128.encodeSigned(Variant.type_code));
        Iterable<int> hash_keys = this.keys;
        t_bytes.addAll(leb128.encodeUnsigned(hash_keys.length));   
        for (int hash_key in hash_keys) {
            t_bytes.addAll(leb128.encodeUnsigned(hash_key));
            t_bytes.addAll(this[hash_key]!._T_forward());
        }
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128.encodeSigned(type_table_i);
    }

    Uint8List _M_forward() {
        if (this.keys.length > 1) { throw Exception('variant can only hold one value.'); }
        List<int> m_bytes = [];
        m_bytes.addAll(leb128.encodeUnsigned(0));
        m_bytes.addAll(this.values.first._M_forward());
        return Uint8List.fromList(m_bytes);
    }

}


// ----------------------------------------------

// can the datatypes of the in_types & out_types of a func-reference be Index of the type_table or must they be written out within this func-reference-type-table-type 



abstract class ReferenceType extends CandidType {
    bool get isOpaque;
}




// helper function for the TypeTableReferences in the FuntionReference M_backwards 
CandidType type_table_ference_as_a_type_stance(TypeTableReference type_table_fer) {
    CandidType type_table_type = type_table[type_table_fer.type_table_i];
    if (type_table_type is TypeTableReference) {
        type_table_type = type_table_ference_as_a_type_stance(type_table_type);
    } 
    if (type_table_type is TypeTableReference) {
        throw Exception('something is wrong');
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
    String toString() => '${get_typename_ofthe_toString(super.toString())}: (${this.in_types.toString().substring(1, this.in_types.toString().length - 1)}) -> (${this.out_types.toString().substring(1, this.out_types.toString().length - 1)})${isQuery ? ' query' : ''}${isOneWay ? ' oneway' : ''}, service: ${this.service}, method_name: ${this.method_name}.';

    static TfuncTuple _T_backward(Uint8List candidbytes, CandidBytes_i start_i) {
        List<CandidType> in_types = [];
        List<CandidType> out_types = [];
        CandidBytes_i next_types_list_start_i = start_i;
        for (List<CandidType> types_list in [in_types, out_types]) {
            FindLeb128BytesTuple types_len_leb128bytes_tuple = find_leb128bytes(candidbytes, next_types_list_start_i);
            int types_len = leb128.decodeUnsigned(types_len_leb128bytes_tuple.item1).toInt();
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
        int func_marks_len = leb128.decodeUnsigned(func_marks_len_leb128bytes_tuple.item1).toInt();
        CandidBytes_i next_func_mark_start_i = func_marks_len_leb128bytes_tuple.item2;
        bool isQuery = false;
        bool isOneWay = false;
        for (int func_mark_i = 0; func_mark_i < func_marks_len; func_mark_i++) {
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

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) {
        late CandidBytes_i next_i;
        ServiceReference? service_value;
        Text? method_name_value;
        if (candidbytes[start_i] == 0) {
            next_i = start_i + 1;
        } else if (candidbytes[start_i] == 1) {
            MfuncTuple service_m_func_tuple = ServiceReference(isTypeStance: true, methods_types: {})._M(candidbytes, start_i + 1); // .M on a type-stance gives-back a with the istypestance=false
            service_value = service_m_func_tuple.item1 as ServiceReference; 
            MfuncTuple method_name_text_m_func_tuple = Text()._M(candidbytes, service_m_func_tuple.item2);
            method_name_value = method_name_text_m_func_tuple.item1 as Text;
            next_i = method_name_text_m_func_tuple.item2;
        }
        for (List<CandidType> types_list in [this.in_types, this.out_types]) {
            for(int i=0;i<types_list.length;i++) {
                if (types_list[i] is TypeTableReference) {
                    types_list[i] = type_table_ference_as_a_type_stance(types_list[i] as TypeTableReference);
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
    
    Uint8List _T_forward() {
        List<int> t_bytes = [];
        t_bytes.addAll(leb128.encodeSigned(FunctionReference.type_code));
        for (List<CandidType> types_list in [this.in_types, this.out_types]) {
            t_bytes.addAll(leb128.encodeUnsigned(types_list.length));
            for (CandidType ctype in types_list) {
                t_bytes.addAll(ctype._T_forward());
            }
        }
        int func_marks_len = 0;
        if (this.isQuery) { func_marks_len += 1; }
        if (this.isOneWay) { func_marks_len += 1; }
        t_bytes.addAll(leb128.encodeUnsigned(func_marks_len));
        if (this.isQuery) { t_bytes.add(1); }
        if (this.isOneWay) { t_bytes.add(2); }
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128.encodeSigned(type_table_i);
    }
    Uint8List _M_forward() {
        List<int> m_bytes = [];
        if (this.service != null) {
            m_bytes.add(1);
            m_bytes.addAll(this.service!._M_forward());
            m_bytes.addAll(this.method_name!._M_forward());
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
    String toString() => '${get_typename_ofthe_toString(super.toString())}${this.id != null ? ': ' + Principal.oftheBytes(this.id!.bytes).text : ''}';

    static TfuncTuple _T_backward(Uint8List candidbytes, CandidBytes_i start_i) {
        Map<Text, CandidType> methods_types = {}; // CandidType here is either TypeTableReference or FunctionReference
        FindLeb128BytesTuple methods_len_leb128bytes_tuple = find_leb128bytes(candidbytes, start_i);
        int methods_len = leb128.decodeUnsigned(methods_len_leb128bytes_tuple.item1).toInt();
        CandidBytes_i next_method_start_i = methods_len_leb128bytes_tuple.item2;
        for (int i=0;i<methods_len;i++) {
            MfuncTuple method_name_m_func_tuple = Text()._M(candidbytes, next_method_start_i);
            Text method_name = method_name_m_func_tuple.item1 as Text;
            TfuncTuple function_reference_t_func_tuple = crawl_type_table_whirlpool(candidbytes, method_name_m_func_tuple.item2);
            methods_types[method_name] = function_reference_t_func_tuple.item1; // could be a type table reference
            next_method_start_i = function_reference_t_func_tuple.item2;
        }
        ServiceReference service_fer = ServiceReference(isTypeStance: true, methods_types: methods_types);
        return TfuncTuple(service_fer, next_method_start_i);
    } 

    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) {
        if (this.isTypeStance==false) { throw Exception('this function is call on a stance with the isTypeStance==true and a Map<Text, FunctionReference> methods_types'); }
        Blob? id_value;
        late CandidBytes_i next_i;
        if (candidbytes[start_i] == 0) {
            next_i = start_i + 1;
        } else if (candidbytes[start_i] == 1) {
            MfuncTuple id_m_func_tuple = Vector(isTypeStance: true, values_type: Nat8())._M(candidbytes, start_i + 1);
            Vector<Nat8> id_value_vecnat8 = Vector.oftheList<Nat8>((id_m_func_tuple.item1 as Vector).cast<Nat8>());
            id_value = Blob.oftheVector(id_value_vecnat8);
            next_i = id_m_func_tuple.item2;
        }
        ServiceReference service = ServiceReference(id: id_value);
        for (MapEntry func_me in this.methods_types!.entries) {
            FunctionReference func_ref = func_me.value._M(Uint8List(1), 0).item1 as FunctionReference; // getting the FunctionReference types from the type_table without a service or method_name
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
    
    Uint8List _T_forward() {
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
        t_bytes.addAll(leb128.encodeSigned(ServiceReference.type_code));
        t_bytes.addAll(leb128.encodeUnsigned(this.methods.keys.length));
        for (Text method_name in this.methods.keys.toList()..sort((a,b)=>a.value.compareTo(b.value))) { 
            t_bytes.addAll(method_name._M_forward()); // Text
            t_bytes.addAll(this.methods[method_name]!._T_forward()); // FunctionReference
        } 
        int type_table_i = put_t_in_the_type_table_forward(t_bytes);
        return leb128.encodeSigned(type_table_i);
    }

    Uint8List _M_forward() {
        List<int> m_bytes = [];
        if (this.id == null) {
            m_bytes.add(0);
        } else {
            m_bytes.add(1);
            m_bytes.addAll(this.id!._M_forward());
        }
        return Uint8List.fromList(m_bytes);
    }
}


class PrincipalReference extends ReferenceType {
    static const int type_code = -24;

    final bool isTypeStance;
    bool get isOpaque => id == null;
    Principal? get principal => this.id == null ? null : Principal.oftheBytes(this.id!.bytes);

    final Blob? id; 

    PrincipalReference({this.id, this.isTypeStance=false}) {
        if (this.isTypeStance==true && this.id != null) {
            throw Exception('if isTypeStance == true then that means that we dont know if this is an opaque reference or not yet.');
        } 
    }
    String toString() => 'CandidType: ' + '${get_typename_ofthe_toString(super.toString())}: ${this.principal != null ? this.principal!.text : 'opaque'}';

    static TfuncTuple _T_backward(Uint8List candidbytes, CandidBytes_i start_i) {
        // Do this for the now while opaque PrincipalReferences are not being used.
        return TfuncTuple(Principal.typestance(), start_i);
    } 
    MfuncTuple _M(Uint8List candidbytes, CandidBytes_i start_i) {
        Blob? id_value;
        late CandidBytes_i next_i;
        if (candidbytes[start_i] == 0) {
            next_i = start_i + 1;
        } else if (candidbytes[start_i] == 1) {
            MfuncTuple id_m_func_tuple = Vector(isTypeStance: true, values_type: Nat8())._M(candidbytes, start_i + 1);
            Vector<Nat8> id_value_vecnat8 = Vector.oftheList<Nat8>((id_m_func_tuple.item1 as Vector).cast<Nat8>());
            id_value = Blob.oftheVector(id_value_vecnat8); 
            next_i = id_m_func_tuple.item2;
        }
        PrincipalReference principal_fer = PrincipalReference(id: id_value);
        if (principal_fer.isOpaque) {
            return MfuncTuple(principal_fer, next_i); 
        } else {
            return MfuncTuple(Principal.oftheBytes(principal_fer.id!.bytes), next_i);
        }
        
    }    
    Uint8List _T_forward() {
        return leb128.encodeSigned(PrincipalReference.type_code);
    }
    Uint8List _M_forward() {
        List<int> m_bytes = [];
        if (this.id == null) {
            m_bytes.add(0);
        } else {
            m_bytes.add(1);
            m_bytes.addAll(this.id!._M_forward());
        }
        return Uint8List.fromList(m_bytes);
    }
}




// ------------------------------------------------------------------------




T match_variant<T>(Variant variant, Map<String, T Function(CandidType)> match_map) {
    for (String variant_string in match_map.keys) {
        CandidType? variant_value = variant[variant_string]; 
        if (variant_value != null) {
            return match_map[variant_string]!(variant_value);
        }
    }
    throw MatchVariantUnknown<T>(
        variant: variant,
        match_map: match_map
    );
}


class MatchVariantUnknown<T> implements Exception {
    final Variant variant;
    final Map<String, T Function(CandidType)> match_map;
    MatchVariantUnknown({required this.variant, required this.match_map});
    String toString() {
        return 'unknown variant: ${variant}\nmatch tries: ${match_map.keys}';
    }
}



extension PrincipalCandid on Principal{
    Principal get candid => this; 
    Principal get c => this; 
    
}







