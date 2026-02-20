import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps host machine localhost to 10.0.2.2.
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }
}
