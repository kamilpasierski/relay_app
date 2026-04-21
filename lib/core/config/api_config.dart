import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _port = '50851';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$_port/api';
    } else {
      return 'http://127.0.0.1:$_port/api';
    }
  }

  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get userProfile => '$baseUrl/user';
}
