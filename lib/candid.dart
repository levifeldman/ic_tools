
/// Library for serializing Dart values and [Candid](https://github.com/dfinity/candid/blob/master/spec/Candid.md) types forwards and backwards. 
///
/// This library leverages the self-describing property of the [Candid specification](https://github.com/dfinity/candid/blob/master/spec/Candid.md). 
/// This means that in contrast to other Candid implementations, deserialization in this library does not require the response types to be known beforehand. 
///  
/// ```dart
/// 
/// enum Color {
///     blue,
///     green,
/// }
/// 
/// BigInt size = BigInt.from(500);
/// Color color = Color.blue;
/// String name = 'Wonder';
/// List<String> fruits = ['apple', 'banana', 'strawberry', 'blueberry']; 
/// 
/// var record = Record.oftheMap({
///     'size': Nat(size),
///     'color': Variant.oftheMap({ color.name: Null() }),
///     'name': Text(name),
///     'fruits': Vector.oftheList(fruits.map((f)=>Text(f)))
/// });
///
/// Uint8List serialization = c_forwards_one(record);
/// 
/// Record r = c_backwards_one(serialization) as Record;
/// BigInt r_size = (r['size'] as Nat).value;
/// Color r_color = match_variant(r['color'] as Variant, {
///     for (Color c in Color.values) c.name: (_nul) => c,
/// }); 
/// String r_name = (r['name'] as Text).value;
/// List<String> r_fruits = (r['fruits'] as Vector).cast_vector<Text>().map((text)=>text.value).toList();
/// 
/// assert(size == r_size);
/// assert(color == r_color);
/// assert(name == r_name);
/// for (int i=0;i<fruits.length;i++) {
///     assert(fruits[i] == r_fruits[i]);
/// }
/// 
/// ```
/// 
/// ## TypeStance mode.
/// In this library, each [CandidType] has a mode called a TypeStance mode. 
/// A TypeStance of a particular [CandidType] represents that specific candid **type** without holding a value. 
/// The TypeStance mode is needed in scenarios when encoding an [Option] with a null value, or an empty [Vector]. 
/// In the Option scenario, the serializer needs to know the type within the Option, even though the value within the Option is null.
/// In the Vector scenario, the serializer needs to known the type of the values in the Vector even though the length of the Vector is 0.
/// For this reason, when creating an [Option] with a null value, the caller needs to specify the [value_type](Option.value_type) of the Option. This [value_type](Option.value_type) is a particular [CandidType] in the TypeStance mode.
/// For the same reasen, when creating a [Vector] with a length of 0, the caller needs to specify the [values_type](Vector.values_type) of the values within the Vector. This [values_type](Vector.values_type) is a particular [CandidType] in the TypeStance mode.
/// 
/// Creating an [Option] with a null value.
/// ```dart
/// var optional_text = Option(value: null, value_type: Text());
/// var optional_int = Option(value: null, value_type: Int());
/// ```
/// Creating a [Vector] with a length of 0.
/// ```dart
/// var vector_of_bools = Vector(values_type: Bool());
/// ```
/// 
/// ### Creating a [CandidType] in a TypeStance mode.
/// 
/// Creating a [PrimitiveType] in a TypeStance mode is straigtforward. Initialize the [PrimitiveType] without passing a value.
/// ```dart
/// var nat_typestance = Nat(); 
/// var int_typestance = Int(); 
/// var nat32_typestance = Nat32(); 
/// var text_typestance = Text(); 
/// var bool_typestance = Bool(); 
/// // ...
/// ```
/// Creating an [Option] in TypeStance mode.
/// ```dart 
/// var optional_nat_typestance = Option(value_type: Nat(), isTypeStance:true);
/// ```
/// Creating a [Vector] in TypeStance mode.
/// ```dart 
/// var vector_of_texts_typestance = Vector(values_type: Text(), isTypeStance:true);
/// ```
/// Creating a [Record] in TypeStance mode. Each field value in a [Record] in TypeStance mode must also be a TypeStance.
/// ```dart 
/// var record_typestance = Record.oftheMap({
///     'sample_field_one': Nat(),
///     'sample_field_two': Vector(values_type: Text(), isTypeStance:true);        
/// }, isTypeStance:true);
/// ```
/// Creating a [Variant] in TypeStance mode. The variant value in a [Variant] in TypeStance mode must also be a TypeStance.
/// ```dart 
/// var variant_typestance = Variant.oftheMap({
///     'blue': Nat(),
/// }, isTypeStance:true);
/// ```
/// Creating a [Principal] in TypeStance mode.
/// ```dart
/// var principal_typestance = Principal.typestance();
/// ```
library;


export 'src/candid.dart' show 
    CandidType,
    PrimitiveType,
    ConstructType,
    ReferenceType,
    Null,
    Empty,
    Reserved,
    Bool,
    Int,
    Int8,
    Int16,
    Int32,
    Int64,
    Nat,
    Nat8,
    Nat16,
    Nat32,
    Nat64,
    Float32,
    Float64,
    Text,
    Option,
    Vector,
    Record,
    Variant,
    FunctionReference,
    ServiceReference,
    PrincipalReference,
    Blob,
    PrincipalCandid,
    magic_bytes,
    c_forwards,
    c_forwards_one,
    c_backwards,
    c_backwards_one,
    candid_text_hash,
    match_variant
    ;
