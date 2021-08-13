// @JS('candid')
// library candidjs;


import 'package:js/js.dart';





// @JS("codecandidcountbalancequest")
// external codecandidcountbalancequest(String countidentifierstring);


// @JS("test")
// external test();




import 'dart:js' as js;

test() {
    return js.context.callMethod('test', []);
}





// web/app.js
// window.state = {
//     hello: 'world'
// }

// Now make use of this JS object in Flutter.
// main.dart
// import 'dart:js' as js;
// var state = js.JsObject.fromBrowserObject(js.context['state']);
// print(state['hello']);





