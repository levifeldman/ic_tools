// #[allow(clippy::all)]
// #[allow(dead_code)]
mod bls;
use crate::bls::bls12381::bls::{init, core_verify, BLS_OK, BLS_FAIL};
use wasm_bindgen::prelude::*;



fn main() {
    let loadblsstatus: bool = loadbls();
    println!("loadblsstatus: {}", loadblsstatus);
    if loadblsstatus == true {
        let b: bool = verify("333333","333333","333333");
        println!("verify sponse: {}", b);
    }
}


// #[wasm_bindgen]
pub fn loadbls() -> bool {
    if init() == BLS_OK {
        bls_verify_test();
        return true;
    } else {
        return false;
    }
}

// #[wasm_bindgen]
pub fn verify(autograph: &str, message: &str, key: &str) -> bool {
    let autograph_bytes: Vec<u8> = hex::decode(&autograph).unwrap();
    let message_bytes: Vec<u8> = hex::decode(&message).unwrap();
    let key_bytes: Vec<u8> = hex::decode(&key).unwrap();
    if core_verify(&autograph_bytes, &message_bytes, &key_bytes) == BLS_OK {
        return true;
    } else {
        return false;
    }
}

fn bls_verify_test() {
    let pk = hex::decode("a7623a93cdb56c4d23d99c14216afaab3dfd6d4f9eb3db23d038280b6d5cb2caaee2a19dd92c9df7001dede23bf036bc0f33982dfb41e8fa9b8e96b5dc3e83d55ca4dd146c7eb2e8b6859cb5a5db815db86810b8d12cee1588b5dbf34a4dc9a5").unwrap();
    let sig = hex::decode("b89e13a212c830586eaa9ad53946cd968718ebecc27eda849d9232673dcd4f440e8b5df39bf14a88048c15e16cbcaabe").unwrap();
    assert_eq!(init(), BLS_OK);
    assert_eq!(core_verify(&sig, b"hello".as_ref(), &pk), BLS_OK);
    assert_eq!(core_verify(&sig, b"hallo".as_ref(), &pk), BLS_FAIL);
}



// #[wasm_bindgen]
pub fn sumtest(x: i32, y: i32) -> i32 {
    x + y
}


// #[wasm_bindgen]
pub fn minustest(x: i32, y: i32) -> i32 {
    x - y
}














