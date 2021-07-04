// // use miracl_core_bls12381::bls12381::bls::{init, core_verify, BLS_OK, BLS_FAIL};
// use ic_agent::bls::bls12381::bls::{init, core_verify, BLS_OK, BLS_FAIL};




#[allow(clippy::all)]
#[allow(dead_code)]
mod bls;
use bls::bls12381::bls::{init, core_verify, BLS_OK}; //BLS_FAIL
use wasm_bindgen::prelude::*;



fn main() {
    // bls_test();

    println!("finish test.");

    let loadblsstatus: bool = init() == BLS_OK;
    println!("loadblsstatus: {}", loadblsstatus);
    if loadblsstatus == true {
    
    
    }



}

#[wasm_bindgen]
pub fn bls_stantiate() -> bool {
    init() == BLS_OK
}

#[wasm_bindgen]
pub fn bls_verify(autograph: &[u8], message: &[u8], public_key: &[u8]) -> bool {
    core_verify(autograph, message, public_key) == BLS_OK
}




#[test]
fn bls_test() {
    assert_eq!(bls_stantiate(), true);
    
    let pk: Vec<u8> = hex::decode("a7623a93cdb56c4d23d99c14216afaab3dfd6d4f9eb3db23d038280b6d5cb2caaee2a19dd92c9df7001dede23bf036bc0f33982dfb41e8fa9b8e96b5dc3e83d55ca4dd146c7eb2e8b6859cb5a5db815db86810b8d12cee1588b5dbf34a4dc9a5").unwrap();
    let sig: Vec<u8> = hex::decode("b89e13a212c830586eaa9ad53946cd968718ebecc27eda849d9232673dcd4f440e8b5df39bf14a88048c15e16cbcaabe").unwrap();
    println!("len of the pk: {}, len of the autograph: {}", pk.len(), sig.len());
    println!("sig: {:?}", sig);
    println!("mes: {:?}", b"hello".as_ref());  
    println!("pk: {:?}", pk);
    let r1: bool = bls_verify(&sig, b"hello".as_ref(), &pk);
    let r2: bool = bls_verify(&sig, b"hallo".as_ref(), &pk);
    println!("r1: {}, r2: {}", r1,r2);
    assert_eq!(r1, true);
    assert_eq!(r2, false);

}


// #[test]
fn bls_test2() {
    println!("start bls_test2");
    let aut: [u8; 48] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    // let m: [u8; 5] = [1,2,3,4,5];
    let pk: [u8; 96] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    println!("len of the pk: {}, len of the autograph: {}", pk.len(), aut.len());
    let x: bool = bls_verify(&aut, b"hello".as_ref(), &pk);
    println!("a,b,c: {}", x);
}
