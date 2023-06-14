import 'dart:html' show CryptoKey;

import '../ic_tools.dart';
import '../tools/tools.dart';

import './subtlecryptokeys.dart';
import './indexdb.dart';
import './tools.dart';
import './ii_login.dart';

/// [Caller] implementation with a [SubtleCryptoECDSAP256Keys] 
/// session-key, an [internet-identity](https://identity.ic0.app) login function, 
/// and save/load accross browser sessions using [IndexDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API).
///
/// Use the [IICaller.login] function to login a user with internet-identity.
/// 
/// Use the [IICaller.indexdb_save] and [IICaller.indexdb_load] functions to save/load the user accross browser sessions.   
class IICaller extends Caller {
    // extend the type of the Caller.keys
    SubtleCryptoECDSAP256Keys keys;
    
    IICaller._({
        required SubtleCryptoECDSAP256Keys keys,
        required List<Legation> legations,
    }) : keys = keys, super(keys:keys, legations:legations);
    
    
    /// Performs the [internet-identity](https://identity.ic0.app) login flow 
    /// with a [SubtleCrypto](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto) session key with the `extractable` property set to `false` for the highest security.
    static Future<IICaller> login({Duration valid_duration = const Duration(days: 30), String? derivation_origin, String ii_url = 'https://identity.ic0.app'}) async {
        SubtleCryptoECDSAP256Keys session_keys = await SubtleCryptoECDSAP256Keys.new_keys();
        List<Legation> legations = await ii_login(
            session_public_key_DER: session_keys.public_key_DER,
            valid_duration: valid_duration,
            derivation_origin: derivation_origin,
            ii_url: ii_url
        );
        return IICaller._(
            keys: session_keys,
            legations: legations
        );
    }
    
    
    static String _indexdb_name = 'ic_tools_web';
    static String _indexdb_object_store_name = 'user_keys';
    static String _indexdb_object_key_cryptokey_public = 'user_crypto_key_public';
    static String _indexdb_object_key_cryptokey_private = 'user_crypto_key_private';
    static String _indexdb_object_key_legations = 'user_legations';
    
    /// Saves this [IICaller] into the browser's [IndexDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)
    /// making it possible to store this logged in user accross browser sessions even when the SubtleCrypto session-private-key `extractable` property is set to false. 
    Future<void> indexdb_save() async {
        if (IndexDB.is_support_here()) {
            
            IndexDB idb = await IndexDB.open(_indexdb_name, [_indexdb_object_store_name]);
            
            await idb.add_or_put_object(
                object_store_name: _indexdb_object_store_name, 
                key: _indexdb_object_key_cryptokey_public, 
                value: this.keys.public_key,
            );
            await idb.add_or_put_object(
                object_store_name: _indexdb_object_store_name, 
                key: _indexdb_object_key_cryptokey_private, 
                value: this.keys.private_key
            );             
            await idb.add_or_put_object(
                object_store_name: _indexdb_object_store_name, 
                key: _indexdb_object_key_legations, 
                value: this.legations.map<JSLegation>(jslegation_of_a_legation).toList(), 
            );
            idb.shutdown();            
        } else {
            print('IndexDB not supported here. User will be logged out when the session closes.');
        }   
    }
    
    /// Loads the user that is saved in the [IndexDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API) 
    /// if there is one.
    /// 
    /// The user's session might be expired so check it by the [IICaller.legations.is_expired](List<Legation>.is_expired) method, and the [IICaller.legations.duration_to_expiration](List<Legation>.duration_to_expiration) method.
    static Future<IICaller?> indexdb_load() async {
        IICaller? user;
        if (IndexDB.is_support_here()) {
            
            IndexDB idb = await IndexDB.open(_indexdb_name, [_indexdb_object_store_name]);
            
            CryptoKey? user_crypto_key_public = await idb.get_object(
                object_store_name: _indexdb_object_store_name, 
                key: _indexdb_object_key_cryptokey_public
            ) as CryptoKey?;
            
            CryptoKey? user_crypto_key_private = await idb.get_object(
                object_store_name: _indexdb_object_store_name, 
                key: _indexdb_object_key_cryptokey_private
            ) as CryptoKey?;

            List<Legation>? user_legations = (await idb.get_object(
                object_store_name: _indexdb_object_store_name, 
                key: _indexdb_object_key_legations
            ) as List<dynamic>?).nullmap((list_dynamic)=>list_dynamic.cast<JSLegation>().map<Legation>(legation_of_a_jslegation).toList()); 

            idb.shutdown();
            
            if (
                user_crypto_key_public != null 
                && user_crypto_key_private != null
                && user_legations != null
            ) {
                user = IICaller._(
                    keys: await SubtleCryptoECDSAP256Keys.of_the_cryptokeys(
                        public_key: user_crypto_key_public,
                        private_key: user_crypto_key_private
                    ),
                    legations: user_legations
                );
            }
        } else {
            print('IndexDB not supported here.');
        }
        
        return user;
                
    }

    
    
}
