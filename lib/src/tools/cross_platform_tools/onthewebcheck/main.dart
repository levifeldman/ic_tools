import 'stub.dart'
    if (dart.library.io) 'linux.dart'
    if (dart.library.js) 'web.dart';



abstract class onthewebcheck {
    late bool isontheweb;
}

onthewebcheck onthewebcheckstance = getonthewebcheckstance();

/// Whether this code is running on the Web platform.
final bool isontheweb = onthewebcheckstance.isontheweb;




