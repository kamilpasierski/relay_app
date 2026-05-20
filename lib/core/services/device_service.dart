import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'package:relay_app/core/services/auth_service.dart';

Future<Map<String, dynamic>?> getDeviceDetails(String uuid) async {
  final token = await AuthService().getToken();
  if (token == null) return null;

  final url = Uri.parse('${ApiConfig.baseUrl}/devices/$uuid');

  try {
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      final deviceData = decodedData.containsKey('data')
          ? decodedData['data']
          : decodedData;

      return deviceData;
    } else {
      debugPrint('Błąd pobierania urządzenia. Status: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Błąd połączenia: $e');
  }
  return null;
}

class DeviceService {
  Future<Map<String, dynamic>?> getDeviceDetails(String uuid) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}/public/devices/$uuid');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        return decodedData.containsKey('data')
            ? decodedData['data']
            : decodedData;
      } else {
        debugPrint(
          'Błąd pobierania urządzenia. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Błąd połączenia: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getDeviceEvents(String uuid) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/devices/$uuid/events');

    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);

        return decodedData
            .map((event) => Map<String, dynamic>.from(event))
            .toList();
      } else {
        print('Błąd API (${response.statusCode}): ${response.body}');
        throw Exception('Nie udało się pobrać historii urządzenia.');
      }
    } catch (e) {
      print('Wyjątek podczas pobierania zdarzeń: $e');
      throw Exception('Błąd połączenia z serwerem: $e');
    }
  }
}
