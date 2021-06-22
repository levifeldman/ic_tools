#[allow(clippy::all)]
#[allow(dead_code)]
mod bls;
use bls::bls12381::{bls as blss};

use wasm_bindgen::prelude::*;




#[wasm_bindgen]
pub fn loadbls() -> bool {
    if blss::init() == blss::BLS_OK {
        return true;
    } else {
        return false;
    }
}

#[wasm_bindgen]
pub fn verify(autograph: &[u8], message: &[u8], key: &[u8]) -> bool {
    if blss::core_verify(autograph, message, key) == blss::BLS_OK {
        return true;
    } else {
        return false;
    }
}


#[wasm_bindgen]
pub fn sumtest(x: i32, y: i32) -> i32 {
    // bls::bls12381::bls::core_verify(sig: &[u8], m: &[u8], w: &[u8])
    x + y
}


#[wasm_bindgen]
pub fn minustest(x: i32, y: i32) -> i32 {
    x - y
}














