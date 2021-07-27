// primitive-types

// reserved is a type with unknown content that ought to be ignored. Its purpose is to occupy field ids in records in order to prevent backwards/forwards compatibility problems, see the description of record types below.

// empty


/*
construct-types

opt <datatype>
vec <datatype> ->  A vector is a homogeneous sequence of values of the same data type.
blob == vec nat8
record -> A record is a heterogeneous sequence of values of different data types. Each value is tagged by a field id which is a numeric value that has to be unique within the record and carries a single value of specified data type. The order in which fields are specified is immaterial.
    hash function for a [re]cord-field's-shorthand-name->hash_function:
    hash(id) = ( Sum_(i=0..k) utf8(id)[i] * 223^(k-i) ) mod 2^32 where k = |utf8(id)|-1
A field id must be smaller than 2^32 and no id may occur twice in the same variant type.



record { <fieldtype>; }

record {
  name : text;
  street : text;
  num : nat;
  city : text;
  zip : nat;
}

// these two are the same 
record { nat; nat }
record { 0 : nat; 1 : nat }


variant { <fieldtype>; }

A variant is a tagged union of different possible data types. The tag is given by a numeric id that uniquely determines the variant case. Each case is described as a field. The order in which fields are specified is immaterial.
Like for record fields, the id for a variant tag can also be given as a name, which is a shorthand for its hash.
A field id must be smaller than 2^32 and no id may occur twice in the same variant type.

type color = variant { red; green; blue };

type tree = variant {
  leaf : int;
  branch : record {left : tree; val : int; right : tree};
}


reference-types -> A service reference points to a service and is described by an actor type. Through this, services can communicate connections to other services.

<reftype> ::= ... | service <actortype>

type broker = service {
  findCounterService : (name : text) ->
    (service {up : () -> (); current : () -> nat});
}



<reftype> ::= ... | principal | ...




:Serialisation.

At runtime, every Candid value is serialised into a triple (T, M, R), 
    where T ("type") and M ("memory") are sequences of bytes 
    and R ("references") is a sequence of references. If R is empty, it can be omitted.

T : <primtype> -> i8*
T(null)     = sleb128(-1)  = 0x7f
T(bool)     = sleb128(-2)  = 0x7e
T(nat)      = sleb128(-3)  = 0x7d
T(int)      = sleb128(-4)  = 0x7c
T(nat8)     = sleb128(-5)  = 0x7b
T(nat16)    = sleb128(-6)  = 0x7a
T(nat32)    = sleb128(-7)  = 0x79
T(nat64)    = sleb128(-8)  = 0x78
T(int8)     = sleb128(-9)  = 0x77
T(int16)    = sleb128(-10) = 0x76
T(int32)    = sleb128(-11) = 0x75
T(int64)    = sleb128(-12) = 0x74
T(float32)  = sleb128(-13) = 0x73
T(float64)  = sleb128(-14) = 0x72
T(text)     = sleb128(-15) = 0x71
T(reserved) = sleb128(-16) = 0x70
T(empty)    = sleb128(-17) = 0x6f


T : <constype> -> i8*                                       
T(opt <datatype>) = sleb128(-18) I(<datatype>)              // 0x6e
T(vec <datatype>) = sleb128(-19) I(<datatype>)              // 0x6d
T(record {<fieldtype>^N}) = sleb128(-20) T*(<fieldtype>^N)  // 0x6c
T(variant {<fieldtype>^N}) = sleb128(-21) T*(<fieldtype>^N) // 0x6b


T : <fieldtype> -> i8*
T(<nat>:<datatype>) = leb128(<nat>) I(<datatype>)

T : <reftype> -> i8*
T(func (<datatype1>*) -> (<datatype2>*) <funcann>*) =
  sleb128(-22) T*(<datatype1>*) T*(<datatype2>*) T*(<funcann>*) // 0x6a
T(service {<methtype>*}) =
  sleb128(-23) T*(<methtype>*)                                    // 0x69
T(principal) = sleb128(-24)                                       // 0x68

T : <methtype> -> i8*
T(<name>:<datatype>) = leb128(|utf8(<name>)|) i8*(utf8(<name>)) I(<datatype>)

T : <funcann> -> i8*
T(query)  = i8(1)
T(oneway) = i8(2)

T* : <X>* -> i8*
T*(<X>^N) = leb128(N) T(<X>)^N

Every nested type is encoded as either a primitive type or an index into a list of type definitions. This allows for recursive types and sharing of types occuring multiple times:

I : <datatype> -> i8*
I(<primtype>) = T(<primtype>)
I(<datatype>) = sleb128(i)  where type definition i defines T(<datatype>)

Type definitions themselves are represented as a list of serialised data types:

T*(<datatype>*)

The data types in this list can themselves refer to each other (or themselves) via I.

Note:

    Due to the type definition prefix, there are always multiple possible ways to represent any given serialised type. Type serialisation hence is not technically a function but a relation.

    The serialised data type representing a method type must denote a function type.

    Because recursion goes through T, this format by construction rules out non-well-founded definitions like type t = t.





Memory

M maps an Candid value to a byte sequence representing that value. The definition is indexed by type. We assume that the fields in a record value are sorted by increasing id.

M : <val> -> <primtype> -> i8*
M(n : nat)      = leb128(n)
M(i : int)      = sleb128(i)
M(n : nat<N>)   = i<N>(n)
M(i : int<N>)   = i<N>(signed_N^-1(i))
M(z : float<N>) = f<N>(z)
M(b : bool)     = i8(if b then 1 else 0)
M(t : text)     = leb128(|utf8(t)|) i8*(utf8(t))
M(_ : null)     = .
M(_ : reserved) = .
// NB: M(_ : empty) will never be called

M : <val> -> <constype> -> i8*
M(null : opt <datatype>) = i8(0)
M(?v   : opt <datatype>) = i8(1) M(v : <datatype>)
M(v*   : vec <datatype>) = leb128(N) M(v : <datatype>)*
M(kv*  : record {<fieldtype>*}) = M(kv : <fieldtype>)*
M(kv   : variant {<fieldtype>*}) = leb128(i) M(kv : <fieldtype>*[i])

M : (<nat>, <val>) -> <fieldtype> -> i8*
M((k,v) : k:<datatype>) = M(v : <datatype>)

M : <val> -> <reftype> -> i8*
M(ref(r) : service <actortype>) = i8(0)
M(id(v*) : service <actortype>) = i8(1) M(v* : vec nat8)

M(ref(r)   : func <functype>) = i8(0)
M(pub(s,n) : func <functype>) = i8(1) M(s : service {}) M(n : text)

M(ref(r) : principal) = i8(0)
M(id(v*) : principal) = i8(1) M(v* : vec nat8)








References

R maps an Candid value to the sequence of references contained in that value. The definition is indexed by type. We assume that the fields in a record value are sorted by increasing id.

R : <val> -> <primtype> -> <ref>*
R(_ : <primtype>) = .

R : <val> -> <constype> -> <ref>*
R(null : opt <datatype>) = .
R(?v   : opt <datatype>) = R(v : <datatype>)
R(v*   : vec <datatype>) = R(v : <datatype>)*
R(kv*  : record {<fieldtype>*}) = R(kv : <fieldtype>)*
R(kv   : variant {<fieldtype>*}) = R(kv : <fieldtype>*[i])

R : (<nat>, <val>) -> <fieldtype> -> <ref>*
R((k,v) : k:<datatype>) = R(v : <datatype>)

R : <val> -> <reftype> -> <ref>*
R(ref(r) : service <actortype>) = r
R(id(b*) : service <actortype>) = .
R(ref(r)   : func <functype>) = r
R(pub(s,n) : func <functype>) = .
R(ref(r) : principal) = r
R(id(b*) : principal) = .

Note:

    It is unspecified how references r are represented, neither internally nor externally. When binding to Wasm, their internal representation is expected to be based on Wasm reference types, i.e., anyref or subtypes thereof. It is up to the system how to represent or translate the reference table on the wire.

Parameters and Results

A defines the argument mapping. Essentially, an argument list is serialised into the triple (T,M,R) as if it was a single closed record. T and M are combined into a single byte stream B, where they are preceded by the string "DIDL" as a magic number and a possible list of type definitions. We assume that the argument values are sorted by increasing id.

A(kv* : <datatype>*) = ( B(kv* : <datatype>*), R(kv* : <datatype>*) )

B(kv* : <datatype>*) =
  i8('D') i8('I') i8('D') i8('L')      magic number
  T*(<datatype>*)                      type definition table
  I*(<datatype>*)                      types of the argument list
  M(kv* : <datatype>*)                 values of argument list

The vector T*(<datatype>*) contains an arbitrary sequence of type definitions (see above), to be referenced in the serialisation of the other <datatype> vector.

The same representation is used for function results.

Note:

    It is unspecified how the pair (B,R) representing a serialised value is bundled together in an external environment.

Deserialisation

Deserialisation at an expected type sequence (<t'>,*) proceeds by

    checking for the magic number DIDL
    using the inverse of the T function to decode the type definitions (<t>,*)
    check that (<t>,*) <: (<t'>,*), else fail
    using the inverse of the M function, indexed by (<t>,*), to decode the values (<v>,*)
    use the coercion function C[(<t>,*) <: (<t'>,*)]((<v>,*)) to understand the decoded values at the expected type.

Deserialisation of future types

Deserialisation uses the following mechanism for robustness towards future extensions:

    A serialised type may be headed by an opcode other than the ones defined above (i.e., less than -24). Any such opcode is followed by an LEB128-encoded count, and then a number of bytes corresponding to this count. A type represented that way is called a future type.

    A value corresponding to a future type is called a future value. It is represented by two LEB128-encoded counts, m and n, followed by a m bytes in the memory representation M and accompanied by n corresponding references in R.

These measures allow the serialisation format to be extended with new types in the future, as long as their representation and the representation of the corresponding values include a length prefix matching the above scheme, and thereby allowing an older deserialiser not understanding them to skip over them. The subtyping rules ensure that upgradability is maintained in this situation, i.e., an old deserialiser has no need to understand the encoded data.












*/ 










// T* : <X>* -> i8*
// T*(<X>^N) = leb128(N) T(<X>)^N

// Every nested type is encoded as either a primitive type or an index into a list of type definitions. This allows for recursive types and sharing of types occuring multiple times:

// I : <datatype> -> i8*
// I(<primtype>) = T(<primtype>)
// I(<datatype>) = sleb128(i)  where type definition i defines T(<datatype>)

// Type definitions themselves are represented as a list of serialised data types:

// T*(<datatype>*)

// The data types in this list can themselves refer to each other (or themselves) via I.

// Note:

//     Due to the type definition prefix, there are always multiple possible ways to represent any given serialised type. Type serialisation hence is not technically a function but a relation.

//     The serialised data type representing a method type must denote a function type.

//     Because recursion goes through T, this format by construction rules out non-well-founded definitions like type t = t.




// :questions:
//  - will there ever be a nested record in the type table?
//      for the now i will treat it like there could be .
//  - what happens if there are more than 104 types in the type table, how will we know if the type_code is an index in the type table or if its a candidtype?
// 

export 'candid_types.dart';
