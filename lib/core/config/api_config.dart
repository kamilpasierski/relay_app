import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://relay-api-26x8.onrender.com/api';
    } else {
      return 'https://relay-api-26x8.onrender.com/api';
    }
  }

  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get userProfile => '$baseUrl/user';
}
