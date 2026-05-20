import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'package:relay_app/core/services/auth_service.dart';

class FaultService {
  Future<List<Map<String, dynamic>>> getFaults() async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final url = Uri.parse('${ApiConfig.baseUrl}/faults');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);

        return dataList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('Błąd pobierania usterek: $e');
    }
    return [];
  }

  Future<bool> updateFaultStatus(int faultId, String status) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final url = Uri.parse('${ApiConfig.baseUrl}/faults/$faultId');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Błąd aktualizacji statusu: $e');
      return false;
    }
  }
}
