import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'package:relay_app/core/services/auth_service.dart';

class DeviceService {
  final http.Client httpClient;
  final AuthService authService;

  DeviceService({http.Client? httpClient, AuthService? authService})
    : httpClient = httpClient ?? http.Client(),
      authService = authService ?? AuthService();

  Future<Map<String, dynamic>?> getDeviceDetails(String uuid) async {
    final token = await authService.getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/devices/$uuid');

    final headers = {'Accept': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await httpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final deviceData = decodedData.containsKey('data')
            ? decodedData['data']
            : decodedData;

        return deviceData;
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
      final response = await httpClient.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);

        return decodedData
            .map((event) => Map<String, dynamic>.from(event))
            .toList();
      } else {
        debugPrint('Błąd API (${response.statusCode}): ${response.body}');
        throw Exception('Nie udało się pobrać historii urządzenia.');
      }
    } catch (e) {
      debugPrint('Wyjątek podczas pobierania zdarzeń: $e');
      throw Exception('Błąd połączenia z serwerem: $e');
    }
  }
}
