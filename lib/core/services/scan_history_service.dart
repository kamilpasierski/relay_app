import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryService {
  static const String _key = 'scan_history';
  static const int _maxItems = 15;

  final SharedPreferences? _preferences;
  SharedPreferences? _cachedPreferences;

  ScanHistoryService({SharedPreferences? preferences})
    : _preferences = preferences;

  Future<SharedPreferences> _getPreferences() async {
    if (_preferences != null) {
      return _preferences;
    }
    _cachedPreferences ??= await SharedPreferences.getInstance();
    return _cachedPreferences!;
  }

  Future<void> addScan(String uuid, String deviceName) async {
    final prefs = await _getPreferences();
    final String? historyJson = prefs.getString(_key);

    List<dynamic> history = historyJson != null ? jsonDecode(historyJson) : [];

    final existingIndex = history.indexWhere((item) => item['uuid'] == uuid);

    if (existingIndex != -1) {
      history.removeAt(existingIndex);
    }

    final newScan = {
      'uuid': uuid,
      'name': deviceName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.insert(0, newScan);

    if (history.length > _maxItems) {
      history = history.sublist(0, _maxItems);
    }

    await prefs.setString(_key, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await _getPreferences();
    final String? historyJson = prefs.getString(_key);

    if (historyJson == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(historyJson));
  }

  Future<void> clearHistory() async {
    final prefs = await _getPreferences();
    await prefs.remove(_key);
  }
}
