import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' show Utf8;
import 'dart:convert';

typedef rust_bls_stantiate = ffi.Int64 Function();
typedef rust_bls_verify = ffi.Int64 Function(ffi.Pointer<Utf8> autograph, ffi.Pointer<Utf8> message, ffi.Pointer<Utf8> public_key);

typedef dart_bls_stantiate = int Function();
typedef dart_bls_verify = int Function(ffi.Pointer<Utf8> autograph, ffi.Pointer<Utf8> message, ffi.Pointer<Utf8> public_key);


ffi.DynamicLibrary dlffi = ffi.DynamicLibrary.open("rust_bls12381/target/release/librust_bls12381.so");

final dart_bls_stantiate bls_stantiate = dlffi.lookup<ffi.NativeFunction<rust_bls_stantiate>>('bls_stantiate').asFunction();
final dart_bls_verify bls_verify = dlffi.lookup<ffi.NativeFunction<rust_bls_verify>>('bls_verify').asFunction();


