
import 'dart:async';

import 'package:flutter/services.dart';

class Testplugin {
  static const MethodChannel _channel =
      const MethodChannel('testplugin');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
