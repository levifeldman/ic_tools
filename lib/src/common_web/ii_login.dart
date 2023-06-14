import 'dart:typed_data';
import 'dart:html';
import 'dart:async';
import 'dart:js' as js;
//import 'dart:js_util';

import '../ic_tools.dart';

import './ii_jslib.dart';


/// Low level function for the [internet-identity](https://identity.ic0.app) login flow. Use the [IICaller.login] function for a simple login.
///
/// Returns the delegations that the internet-identity grants for the [session_public_key_DER].  
Future<List<Legation>> ii_login({required Uint8List session_public_key_DER, required Duration valid_duration, String? derivation_origin, String ii_url = 'https://identity.ic0.app'}) {
    
    late WindowBase identityWindow;
    
    Completer completer = Completer<List<Legation>>();
    
    window.addEventListener('message', (Event event) async {
        if (completer.isCompleted) {
            return; // this is when there is multiple logins in the same session   
        }
        
        MessageEvent message_event = event as MessageEvent;
        
        if (message_event.origin == ii_url) {
        
            if (message_event.data['kind'] == 'authorize-ready') {
                identityWindow.postMessage(
                    create_ii_auth_quest(
                        kind: "authorize-client", 
                        sessionPublicKey: session_public_key_DER,
                        maxTimeToLive: valid_duration.inMicroseconds * 1000,
                        derivationOrigin: derivation_origin
                    ),
                    ii_url
                );
            }
            
            if (message_event.data['kind'] == 'authorize-client-success') {
                identityWindow.close();
                
                if (_put_js_source_get_bigint_string_into_document_body == false) {
                    //print('putting _js_source_get_bigint_string into document body');
                    Element s = document.createElement('script');
                    s.innerText = _js_source_get_bigint_string;
                    document.body!.append(s);
                    _put_js_source_get_bigint_string_into_document_body = true;
                }
                
                List<Legation> legations = List<Legation>.generate(message_event.data['delegations'].length, (int i) {
                    var sl = message_event.data['delegations'][i];
                    js.context.callMethod('start_logMessages');
                    window.console.log(sl['delegation']['expiration']);
                    String expiration_string = js.context.callMethod('get_last_logMessage_toString').replaceAll('n', ''); 
                    //print(expiration_string);
                    return Legation(
                        legator_public_key_DER: Uint8List.fromList(i == 0 ? message_event.data['userPublicKey'].toList() : message_event.data['delegations'][i-1]['delegation']['pubkey'].toList()), 
                        legator_signature: Uint8List.fromList(sl['signature'].toList()),
                        legatee_public_key_DER: Uint8List.fromList(sl['delegation']['pubkey'].toList()),
                        expiration_timestamp_nanoseconds: BigInt.parse(expiration_string),
                        target_canisters_ids: sl['delegation']['targets'] != null ? sl['delegation']['targets'].toList().map<Principal>((String ps)=>Principal.text(ps)).toList() : null 
                    );
                });

                completer.complete(legations);
            }
            
            if (message_event.data['kind'] == 'authorize-client-failure') {
                print('authorize-client-failure:\n${message_event.data['text']}');
                completer.completeError(AuthorizeClientFailure('${message_event.data['text']}'));
            }
        }
    });
    
    identityWindow = window.open('${ii_url}/#authorize', 'identityWindow');  
    
    return completer.future as Future<List<Legation>>;
}


/// The type of the error that can happen during the internet-identity login flow.
///
/// Throws this error when the internet-identity window message kind is `authorize-client-failure`.
class AuthorizeClientFailure implements Exception {
    final String text;
    AuthorizeClientFailure(this.text);
    String toString() => 'AuthorizeClientFailure: $text';
}



bool _put_js_source_get_bigint_string_into_document_body = false;

String _js_source_get_bigint_string = """
    var logBackup = console.log;
    var logMessages = [];
    
    function start_logMessages() {
        console.log = function() {
            logMessages.push.apply(logMessages, arguments);
            /*logBackup.apply(console, arguments);*/
        };
    }
    
    function get_last_logMessage_toString() {
        console.log = logBackup; 
        /*console.log(typeof(logMessages[logMessages.length-1]));*/
        return logMessages[logMessages.length-1].toString();    
    }
""";
