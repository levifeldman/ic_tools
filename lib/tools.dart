
import 'package:http/http.dart';
import 'dart:typed_data';


String bytesasahexstring(List<int> bytes) {    
    String s = '';
    for (int i in bytes) {
        String st = i.toRadixString(16);
        if (st.length == 1) { st = '0'+st; }
        s += st;
    }
    return s;
}


String bytesasabitstring(List<int> bytes) {
    String s = '';
    for (int i in bytes) {
        String it = i.toRadixString(2);
        while (it.length<8) {
            it = '0' + it;
        }
        s += it;
    }
    return s;
}

bool aresamebytes(List<int> b1, List<int> b2) {
    if (b1.length != b2.length) {
        return false;
    }
    bool isqual = true;
    for (int i=0;i<b1.length; i++) {
        if (b1[i] != b2[i]) {
            isqual = false;
        }
    }
    return isqual;
}











// String placeUrlVariablesIntoUrlPathString({required String mainString, required Map<String,String>map}) {
//     map.forEach((key,value) {
//         mainString = mainString.replaceAll(key, value);
//     });
//     return mainString;

// }



void main() {
    // Map map = {
    //     '<vf>': 'levi'
    // };
    // print(placeUrlVariablesIntoUrlPathString(mainString: 'hello, <vf>. i am going to the store.', map: {'<vf>': '123'}));
    // print(null.toString());
    // 
    // 
    // 
    // 
    
}




































