import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/core/services/scan_history_service.dart';

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

  // TYMCZASOWY MOCK: Pobieranie osi czasu urządzenia
  Future<List<Map<String, dynamic>>> getDeviceEvents(String uuid) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Przykładowe dane z bazy (do zastąpienia strzałem GET /api/devices/{uuid}/events)
    return [
      {
        'date': '2026-05-12T09:30:00Z',
        'type': 'fixed',
        'title': 'Naprawiono usterkę',
        'description': 'Wymiana spalonego bezpiecznika i test układu.',
        'user': 'Jan Kowalski',
      },
      {
        'date': '2026-05-11T14:15:00Z',
        'type': 'fault',
        'title': 'Zgłoszono usterkę',
        'description': 'Przekaźnik nie reaguje na sygnał sterujący.',
        'user': 'Anna Nowak',
      },
      {
        'date': '2026-01-20T10:00:00Z',
        'type': 'install',
        'title': 'Instalacja urządzenia',
        'description': 'Pierwszy montaż w szafie RACK 01.',
        'user': 'System',
      },
    ];
  }
}
