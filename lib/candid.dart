
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
/// var record = Record.of_the_map({
///     'size': Nat(size),
///     'color': Variant.of_the_map({ color.name: Null() }),
///     'name': Text(name),
///     'fruits': Vector.of_the_list(fruits.map((f)=>Text(f)))
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
/// ## Type upgrading (subtyping) rules.
/// 
/// When looking for an optional field in a Record, use the [Record.find_option] method.
/// ```dart
/// Nat? number = record.find_option<Nat>('field_name');
/// Text? text = record.find_option<Text>(0);
/// ```
/// 
/// 
/// When 
/// 
/// ```dart
/// 
/// 
/// 
/// 
/// 
/// 
/// ```
/// 
///
/// ## Type-Mode.
/// In this library, each [CandidType] has a mode called a `type_mode`. 
/// A `type_mode` of a particular [CandidType] represents that specific candid **type** without holding a value. 
/// The `type_mode` is needed in scenarios when encoding an [Option] with a null value, or an empty [Vector]. 
/// In the Option scenario, the serializer needs to know the type within the Option, even though the value within the Option is null.
/// In the Vector scenario, the serializer needs to known the type of the values in the Vector even though the length of the Vector is 0.
/// For this reason, when creating an [Option] with a null value, the caller needs to specify the [value_type](Option.value_type) of the Option. 
/// This [value_type](Option.value_type) is a particular [CandidType] in the `type_mode`.
/// For the same reason, when creating a [Vector] with a length of 0, the caller needs to specify the [values_type](Vector.values_type) of the values in the Vector. 
/// This [values_type](Vector.values_type) is a particular [CandidType] in the `type_mode`.
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
/// ### Creating a [CandidType] in the `type_mode`.
/// 
/// Creating a [PrimitiveType] in the `type_mode` is straightforward. Initialize the [PrimitiveType] without passing a value.
/// ```dart
/// var nat_type_mode = Nat(); 
/// var int_type_mode = Int(); 
/// var nat32_type_mode = Nat32(); 
/// var text_type_mode = Text(); 
/// var bool_type_mode = Bool(); 
/// // ...
/// ```
/// Creating an [Option] in `type_mode`.
/// ```dart 
/// var optional_nat_type_mode = Option(value_type: Nat(), type_mode:true);
/// ```
/// Creating a [Vector] in `type_mode`.
/// ```dart 
/// var vector_of_texts_type_mode = Vector(values_type: Text(), type_mode:true);
/// ```
/// Creating a [Record] in `type_mode`. Each field value in a [Record] in `type_mode` must also be in `type_mode`.
/// ```dart 
/// var record_type_mode = Record.of_the_map({
///     'sample_field_one': Nat(),
///     'sample_field_two': Vector(values_type: Text(), type_mode:true);        
/// }, type_mode:true);
/// ```
/// Creating a [Variant] in `type_mode`. The variant value in a [Variant] in `type_mode` must also be in `type_mode`.
/// ```dart 
/// var variant_type_mode = Variant.of_the_map({
///     'blue': Nat(),
/// }, type_mode:true);
/// ```
/// Creating a [Principal] in `type_mode`.
/// ```dart
/// var principal_type_mode = Principal.type_mode();
/// ```
library candid;


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
    Principal,
    Blob,
    magic_bytes,
    c_forwards,
    c_forwards_one,
    c_backwards,
    c_backwards_one,
    candid_text_hash,
    match_variant,
    MatchVariantUnknown
    ;
