import 'dart:html';
import 'dart:typed_data';

//import 'package:js/js.dart';
import 'package:js/js_util.dart';


import '../ic_tools.dart';

import './subtlecryptokeysjslib.dart';









/// A [Keys] implementation that uses the [SubtleCrypto](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto) Web api.
///
/// The keys are ECDSA on the P-256 curve (also known as secp256r1) and use SHA-256 as the hash function.
class SubtleCryptoECDSAP256Keys extends Keys {
    
    //static Uint8List DER_public_key_start = Uint8List.fromList([48, 89, 48, 19, 6, 7, 42, 134, 72, 206, 61, 2, 1, 6, 8, 42, 134, 72, 206, 61, 3, 1, 7, 3, 66, 0, 4]);
    
    CryptoKey private_key;

    CryptoKey public_key;
    /*
    Future<CryptoKey> get public_key {
        return promiseToFuture(callMethod(window.crypto!.subtle!, 'importKey', [
            'spki', 
            this.public_key_DER,
            EcKeyImportParams(
                name: 'ECDSA',
                namedCurve: 'P-256'
            ),
            true, // its a public-key here
            ['verify']
        ]));
    }
    */
    SubtleCryptoECDSAP256Keys._({required super.public_key_DER, required this.public_key, required this.private_key});

    static Future<SubtleCryptoECDSAP256Keys> of_the_cryptokeys({required CryptoKey public_key, required CryptoKey private_key}) async {
        return SubtleCryptoECDSAP256Keys._(
            public_key_DER: (await promiseToFuture(callMethod(window.crypto!.subtle!, 'exportKey', ['spki', public_key]))).asUint8List(), 
            public_key: public_key,
            private_key: private_key
        ); 
    }    

    /// This function generates a new key-pair using the SubtleCrypto [generateKey](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/generateKey) 
    /// method. 
    static Future<SubtleCryptoECDSAP256Keys> new_keys({bool extractable = false}) async {
        if (Crypto.supported == false || window.crypto!.subtle == null ) {
            throw UnsupportedError('Subtle Crypto api not supported on this browser');
        }
                
        Object crypto_key_pair = await promiseToFuture(callMethod(window.crypto!.subtle!, 'generateKey', [
            EcKeyGenParams(
                name: 'ECDSA',
                namedCurve: 'P-256'
            ),
            extractable,
            jsify(['sign'])
        ]));
        
        CryptoKey private_key = getProperty(crypto_key_pair, 'privateKey');
        CryptoKey public_key  = getProperty(crypto_key_pair, 'publicKey');
        
        // 'spki' format is with the clude of the DER bytes
        ByteBuffer public_key_DER_native_byte_buffer = await promiseToFuture(callMethod(window.crypto!.subtle!, 'exportKey', ['spki', public_key]));   
        
        return SubtleCryptoECDSAP256Keys._(
            public_key_DER: public_key_DER_native_byte_buffer.asUint8List(), 
            public_key: public_key,
            private_key: private_key
        );
        
    }
    
    Future<Uint8List> authorize(Uint8List message) async {
        ByteBuffer signature = await promiseToFuture(callMethod(window.crypto!.subtle!, 'sign', [
            EcdsaParams(
                name: 'ECDSA',
                hash: 'SHA-256'
            ),
            this.private_key,
            message
        ]));
        return signature.asUint8List();
    }
    
    
    /// Verifies a signature on a message by an ECDSA P-256 curve key-pair (also known as secp256r1) using SHA-256 as the hash function. 
    static Future<bool> verify({ required Uint8List message, required Uint8List signature, required Uint8List public_key_DER}) async {
        CryptoKey public_key = await promiseToFuture(callMethod(window.crypto!.subtle!, 'importKey', [
            'spki', 
            public_key_DER,
            EcKeyImportParams(
                name: 'ECDSA',
                namedCurve: 'P-256'
            ),
            true, // its a public-key here
            ['verify']
        ]));
        
        return await promiseToFuture(callMethod(window.crypto!.subtle!, 'verify', [
            EcdsaParams(
                name: 'ECDSA',
                hash: 'SHA-256'
            ),
            public_key,
            signature.buffer,
            message.buffer
        ])); 
    }

}





