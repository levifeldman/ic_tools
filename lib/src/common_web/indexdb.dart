//import 'dart:indexed_db';
import 'dart:html';
//import 'dart:js' as js;
//import 'dart:js_util';
import 'dart:async';

import 'package:js/js.dart';
import 'package:js/js_util.dart';



class IndexDB {
    
    static bool is_support_here() => window.indexedDB != null;
    
    static void delete_database(String db_name) {
        callMethod(window.indexedDB!, 'deleteDatabase', [db_name]);
    }
    
    
    final String name;
    Object idb_open_db_quest; // save the q bc it needs to stay 
    Object/*IDBDatabase*/ idb_database;
    
    
    
    IndexDB({required this.name, required this.idb_database, required this.idb_open_db_quest});
    
    static Future<IndexDB> open(String db_name, List<String> object_stores_names) async {
        var/*IDBOpenDBRequest*/ q = callMethod(window.indexedDB!, 'open', [db_name, 1]);
        late Object/*IDBDatabase*/ idb_database;
        
        setProperty(q, 
            'onupgradeneeded',
            allowInterop((event) {
                //window.console.log('upgradeneeded');
                idb_database = getProperty(getProperty(event, 'target'), 'result');
                callMethod(idb_database, 'addEventListener', [
                    'error',
                    allowInterop((Event event) {
                        window.console.log(event);
                        window.alert('idb error');  
                    })  
                ]);
                for (String object_store_name in object_stores_names) {
                    /*Object/*IDBObjectStore.)*/ idb_object_store = */callMethod(idb_database, 'createObjectStore', [ object_store_name ]);
                }
            })
        );
        
        //bool onsuccessorerror = false;
        Completer<IndexDB> completer = Completer<IndexDB>();
        
        setProperty(q, 
            'onsuccess',
            allowInterop((event) {
                idb_database = getProperty(q, 'result');
                //onsuccessorerror = true;
                IndexDB idb = IndexDB(
                    name: db_name, 
                    idb_database: idb_database, 
                    idb_open_db_quest: q,
                );
                completer.complete(idb);
            })
        );
        setProperty(q, 
            'onerror',
            allowInterop((event) {
                completer.completeError('IndexDB open error: ${getProperty(q, 'error').toString()}');
                //onsuccessorerror = true;
            })
        );
        
        return completer.future;
        
        /*
        // poll the result
        while (onsuccessorerror == false || getProperty(q, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 100));
        }        
        if (getProperty(q, 'readyState') != 'done') { throw Exception('unknown idb open request readyState'); }
        
        if (getProperty(q, 'error') == null) {
            return IndexDB(
                name: db_name, 
                idb_database: idb_database, 
                idb_open_db_quest: q,
            );
        } else {
            throw getProperty(q, 'error');
        }
        */
    
    }    
    
    
    List<String> object_store_names() {
        return getProperty(this.idb_database, 'objectStoreNames');
    }
    
    
    
    Future<dynamic> get_object({required String object_store_name, required String key}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readonly'/*'readwrite'*/, 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        callMethod(transaction, 'addEventListener', [
            'complete',
            allowInterop((Event event) {

            })
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        late Object?/*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        //bool onsuccess_cursor_complete_orerror = false;
        Completer<dynamic> completer = Completer();
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        Object? value = getProperty(object_store_cursor_with_value!, 'value');
                        //onsuccess_cursor_complete_orerror = true;
                        completer.complete(value);
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    //onsuccess_cursor_complete_orerror = true;
                    completer.complete(null);
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                //onsuccess_cursor_complete_orerror = true;
                completer.completeError('IndexDB get_object error: ${getProperty(idb_quest_object_store_open_cursor, 'error').toString()}');
            })
        );
        return completer.future;
        /*
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 100));
        }
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            return value;
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');
        }
        */
        
    }
    
    
    // returns true if the object-add is success and false if the key is already in the object_store. use put to update a key.
    Future<bool> add_object({required String object_store_name, required String key, required Object value}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readonly', // here to check if the key is already in the object_store
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        
        late Object?/*can be null if 0 objects*//*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        Completer<bool> completer = Completer();
        //bool onsuccess_cursor_complete_orerror = false;
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        bool is_key_in_the_object_store = true;
                        completer.complete(false);
                        //onsuccess_cursor_complete_orerror = true;
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    //onsuccess_cursor_complete_orerror = true;
                    // the key does not exist yet. good. we can add it.
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                //onsuccess_cursor_complete_orerror = true;
                completer.completeError('IndexDB add_object open-cursor error: ${getProperty(idb_quest_object_store_open_cursor, 'error')}');
            })
        );
        /*
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 100));
        }
        
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            if (is_key_in_the_object_store == true) {
                return false;
            }
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');

        }
        */

        
        Object/*IDBTransaction)*/ transaction2 = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readwrite', 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store2 = callMethod(transaction2, 'objectStore', [object_store_name]);
        /*
        bool transaction_complete = false;
        callMethod(transaction2, 'addEventListener', [
            'complete',
            allowInterop((event) {
                transaction_complete = true;
            })
        ]);
        */
        Object/*IDBRequest*/ idb_quest_object_store_add = callMethod(object_store2, 'add', [value, key]);
        setProperty(idb_quest_object_store_add, 
            'onsuccess',
            allowInterop((event) {
                completer.complete(true);
            })
        );
        setProperty(idb_quest_object_store_add, 
            'onerror',
            allowInterop((event) {
                //onsuccess_cursor_complete_orerror = true;
                completer.completeError('IndexDB add_object error: ${getProperty(idb_quest_object_store_add, 'error')}');
            })
        );
        
        return completer.future;
        
        /*
        while (getProperty(idb_quest_object_store_add, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 100));
        }
        if (getProperty(idb_quest_object_store_add, 'error') == null) {
            // the add in the queue now wait for the complete
            while (transaction_complete == false) { await Future.delayed(Duration(milliseconds: 100)); }
            return true;
        } else {
            throw getProperty(idb_quest_object_store_add, 'error');
        }
        */
        
    }
    
    
    // returns true if the object-put/update is success and false if the key is not found in the object_store. use add to add a new key.
    Future<bool> put_object({required String object_store_name, required String key, required Object value}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readwrite', 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        late Object?/*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        //bool onsuccess_cursor_complete_orerror = false;
        Completer<bool> completer = Completer();
        //bool is_key_in_the_object_store = false;
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) async {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        // update
                        Object/*IDBRequest*/ idb_quest_update = callMethod(object_store_cursor_with_value!, 'update', [value]);
                        setProperty(idb_quest_update, 
                            'onsuccess',
                            allowInterop((event) async {
                                completer.complete(true);
                            }),
                        );
                        setProperty(idb_quest_update, 
                            'onerror',
                            allowInterop((event) async {
                                completer.completeError('IndexDB update error: ${getProperty(idb_quest_update, 'error')}');
                            }),
                        );
                        
                        /*
                        // await here is ok bc we call cursor.update before this await and we wont call cursor.continue after this
                        while (getProperty(idb_quest_update, 'readyState') == 'pending') { await Future.delayed(Duration(milliseconds: 100)); } 
                        if (getProperty(idb_quest_update, 'error') == null) {
                            //is_key_in_the_object_store = true;
                            //onsuccess_cursor_complete_orerror = true;
                        } else {
                            //throw getProperty(idb_quest_update, 'error');
                        }
                        */
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    //onsuccess_cursor_complete_orerror = true;
                    completer.complete(false);
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                //onsuccess_cursor_complete_orerror = true;
                completer.completeError('IndexDB put_object open-cursor error: ${getProperty(idb_quest_object_store_open_cursor, 'error')}');
            })
        );
        
        return completer.future; 
        
        /*
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 100));
        }
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            if (is_key_in_the_object_store == true) {
                return true;
            } else {
                return false;
            }
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');
        }
        */
        
    }
    
    // adds the object if not there. if it is there it updates the object
    Future<void> add_or_put_object({required String object_store_name, required String key, required Object value}) async {
        if (
            await this.add_object(
                object_store_name: object_store_name, 
                key: key, 
                value: value,
            ) == false
        ) {
            await this.put_object(
                object_store_name: object_store_name, 
                key: key, 
                value: value
            );  
        }            
    }    
    
    
    
    void shutdown() {
        callMethod(this.idb_database, 'close', []);
    }
    

}




@JS()
@anonymous
class IDBDatabaseTransactionOptions  {
    external String get durability;
    
    external factory IDBDatabaseTransactionOptions({
        String durability
    });
}


