@JS()
library subtlecryptocallerjslib;

import 'package:js/js.dart';
//import 'package:js/js_util.dart';



@JS()
@anonymous
class EcKeyGenParams {
    external String get name; 
    external String get namedCurve; 
    
    external factory EcKeyGenParams({
        String name,
        String namedCurve
    });
}


@JS()
@anonymous
class EcdsaParams {
    external String get name;
    external String get hash;
    
    external factory EcdsaParams({
        String name,
        String hash,     
    }); 
}


typedef EcKeyImportParams = EcKeyGenParams; 
