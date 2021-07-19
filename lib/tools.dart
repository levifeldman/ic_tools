
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


// BigInt bytesasabigint(Uint8List bytes) {
//   BigInt read(int start, int end) {
//     if (end - start <= 4) {
//       int result = 0;
//       for (int i = end - 1; i >= start; i--) {
//         result = result * 256 + bytes[i];
//       }
//       return new BigInt.from(result);
//     }
//     int mid = start + ((end - start) >> 1);
//     var result = read(start, mid) + read(mid, end) * (BigInt.one << ((mid - start) * 8));
//     return result;
//   }
//   return read(0, bytes.length);
// }

// Uint8List bigintasabytes(BigInt number) {
//   // Not handling negative numbers. Decide how you want to do that.
//   int bytes = (number.bitLength + 7) >> 3;
//   var b256 = new BigInt.from(256);
//   var result = new Uint8List(bytes);
//   for (int i = 0; i < bytes; i++) {
//     result[i] = number.remainder(b256).toInt();
//     number = number >> 8;
//   }
//   return result;
// }








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




































