// // use miracl_core_bls12381::bls12381::bls::{init, core_verify, BLS_OK, BLS_FAIL};
// use ic_agent::bls::bls12381::bls::{init, core_verify, BLS_OK, BLS_FAIL};




#[allow(clippy::all)]
#[allow(dead_code)]
mod bls;
use bls::bls12381::bls::{init, core_verify, BLS_OK}; //BLS_FAIL
use std::ffi::CStr;
use std::os::raw::c_char;


fn main() {
    

}

#[no_mangle]
pub extern "C" fn bls_stantiate() -> i64 {
// pub fn bls_stantiate() -> i64 {
    if init() == BLS_OK {
        1
    } else {
        0
    }
}

#[no_mangle]
pub extern "C" fn bls_verify(autograph_ptr: *const c_char, message_ptr: *const c_char, public_key_ptr: *const c_char) -> i64 {
// pub fn bls_verify(autograph_str: &str, message_str: &str, public_key_str: &str) -> i64 {
    let autograph_cstr: &CStr = unsafe { CStr::from_ptr(autograph_ptr) };
    let message_cstr: &CStr = unsafe { CStr::from_ptr(message_ptr) };
    let public_key_cstr: &CStr = unsafe { CStr::from_ptr(public_key_ptr) };
    let autograph_str: &str = autograph_cstr.to_str().unwrap();
    let message_str: &str = message_cstr.to_str().unwrap();
    let public_key_str: &str = public_key_cstr.to_str().unwrap();
    let autograph_bytes: Vec<u8> = hex::decode(autograph_str).unwrap();
    let message_bytes: Vec<u8> = hex::decode(message_str).unwrap();
    let public_key_bytes: Vec<u8> = hex::decode(public_key_str).unwrap();
    if core_verify(&autograph_bytes, &message_bytes, &public_key_bytes) == BLS_OK { 
        1i64 
    } 
    else { 
        0i64 
    }
}



// change to pass the c_char pointers from this test function.
// #[test]
// fn bls_test() {
//     assert_eq!(bls_stantiate(), 1i64);
    
//     let pk: &str = "a7623a93cdb56c4d23d99c14216afaab3dfd6d4f9eb3db23d038280b6d5cb2caaee2a19dd92c9df7001dede23bf036bc0f33982dfb41e8fa9b8e96b5dc3e83d55ca4dd146c7eb2e8b6859cb5a5db815db86810b8d12cee1588b5dbf34a4dc9a5";
//     let sig: &str = "b89e13a212c830586eaa9ad53946cd968718ebecc27eda849d9232673dcd4f440e8b5df39bf14a88048c15e16cbcaabe";
//     let r1: i64 = bls_verify(&sig, hex::encode(b"hello").as_ref(), &pk);
//     let r2: i64 = bls_verify(&sig, hex::encode(b"hallo").as_ref(), &pk);
//     println!("r1: {}, r2: {}", r1,r2);
//     assert_eq!(r1, 1i64);
//     assert_eq!(r2, 0i64);

// }

