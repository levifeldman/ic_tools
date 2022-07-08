import 'dart:html';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'dart:typed_data';

import '../ic_tools.dart';

import 'subtlecryptocallerjslib.dart';










class SubtleCryptoECDSAP256Caller extends Caller {
    
    static Uint8List DER_public_key_start = Uint8List.fromList([48, 89, 48, 19, 6, 7, 42, 134, 72, 206, 61, 2, 1, 6, 8, 42, 134, 72, 206, 61, 3, 1, 7, 3, 66, 0, 4]);
    
    CryptoKey private_key;
    CryptoKey public_key;
    
    SubtleCryptoECDSAP256Caller({required super.public_key_DER, required this.private_key, required this.public_key});


    static Future<SubtleCryptoECDSAP256Caller> new_keys() async {
        if (Crypto.supported == false || window.crypto!.subtle == null ) {
            throw UnsupportedError('Subtle Crypto api not supported on this browser');
        }
                
        Object crypto_key_pair = await promiseToFuture(callMethod(window.crypto!.subtle!, 'generateKey', [
            EcKeyGenParams(
                name: 'ECDSA',
                namedCurve: 'P-256'
            ),
            false, // extractable: 
            jsify(['sign'])
        ]));
        
        CryptoKey private_key = getProperty(crypto_key_pair, 'privateKey');
        CryptoKey public_key  = getProperty(crypto_key_pair, 'publicKey');
        
        // 'spki' format is with the clude of the DER bytes
        ByteBuffer public_key_DER_native_byte_buffer = await promiseToFuture(callMethod(window.crypto!.subtle!, 'exportKey', ['spki', public_key]));   
        
        return SubtleCryptoECDSAP256Caller(
            public_key_DER: public_key_DER_native_byte_buffer.asUint8List(), 
            private_key: private_key, 
            public_key: public_key
        ); 
        
    }
    
    Future<Uint8List> private_key_authorize_function(Uint8List message) async {
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





