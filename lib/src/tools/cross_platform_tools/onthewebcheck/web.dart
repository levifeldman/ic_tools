import 'main.dart';
import 'dart:html';

import 'dart:typed_data';
import 'dart:convert';



class onthewebcheckweb extends onthewebcheck {
    @override
    bool isontheweb = true;
}



onthewebcheck getonthewebcheckstance() => onthewebcheckweb();

