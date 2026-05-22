import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:relay_app/core/services/scan_history_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScanHistoryService - addScan', () {
    late ScanHistoryService scanHistoryService;
    late MockSharedPreferences mockPreferences;

    setUp(() {
      mockPreferences = MockSharedPreferences();

      scanHistoryService = ScanHistoryService(preferences: mockPreferences);
    });

    group('Success cases', () {
      test('adds new scan to empty history', () async {
        const uuid = 'device-uuid-123';
        const deviceName = 'Living Room Light';

        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan(uuid, deviceName);

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        expect(savedHistory, isNotEmpty);
        expect(savedHistory.first['uuid'], equals(uuid));
        expect(savedHistory.first['name'], equals(deviceName));
      });

      test('adds scan with timestamp in ISO8601 format', () async {
        const uuid = 'device-uuid-123';
        const deviceName = 'Kitchen Plug';

        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan(uuid, deviceName);

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        final timestamp = savedHistory.first['timestamp'] as String;

        expect(() => DateTime.parse(timestamp), returnsNormally);
      });

      test('moves existing scan to top of history', () async {
        const uuid = 'device-uuid-123';
        const deviceName = 'Living Room Light';

        final existingHistory = [
          {
            'uuid': 'other-uuid-1',
            'name': 'Kitchen Light',
            'timestamp': '2024-01-01T10:00:00Z',
          },
          {
            'uuid': uuid,
            'name': 'Old Name',
            'timestamp': '2024-01-01T09:00:00Z',
          },
        ];

        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn(jsonEncode(existingHistory));

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan(uuid, deviceName);

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        expect(savedHistory.first['uuid'], equals(uuid));
        expect(savedHistory.first['name'], equals(deviceName));
      });

      test('respects maximum history limit of 15 items', () async {
        final existingHistory = List<Map<String, dynamic>>.generate(
          15,
          (index) => {
            'uuid': 'device-uuid-$index',
            'name': 'Device $index',
            'timestamp': '2024-01-01T${10 + index}:00:00Z',
          },
        );

        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn(jsonEncode(existingHistory));

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan('device-uuid-new', 'New Device');

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        expect(savedHistory.length, equals(15));
        expect(savedHistory.first['uuid'], equals('device-uuid-new'));
      });

      test('removes oldest item when exceeding maximum limit', () async {
        final existingHistory = List<Map<String, dynamic>>.generate(
          15,
          (index) => {
            'uuid': 'device-uuid-$index',
            'name': 'Device $index',
            'timestamp': '2024-01-01T${10 + index}:00:00Z',
          },
        );

        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn(jsonEncode(existingHistory));

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan('device-uuid-new', 'New Device');

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        final lastUuid = (savedHistory.last as Map<dynamic, dynamic>)['uuid'];

        expect(lastUuid, isNot(equals('device-uuid-14')));
      });

      test('preserves all other scans in history', () async {
        final existingHistory = [
          {
            'uuid': 'device-uuid-1',
            'name': 'Device 1',
            'timestamp': '2024-01-01T10:00:00Z',
          },
          {
            'uuid': 'device-uuid-2',
            'name': 'Device 2',
            'timestamp': '2024-01-01T11:00:00Z',
          },
        ];

        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn(jsonEncode(existingHistory));

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan('device-uuid-3', 'Device 3');

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        expect(savedHistory.length, equals(3));
        expect(
          savedHistory.map((item) => item['uuid']).toList(),
          equals(['device-uuid-3', 'device-uuid-1', 'device-uuid-2']),
        );
      });
    });

    group('Storage interactions', () {
      test('calls getString with correct key', () async {
        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan('device-uuid', 'Device Name');

        verify(() => mockPreferences.getString('scan_history')).called(1);
      });

      test('calls setString to persist changes', () async {
        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan('device-uuid', 'Device Name');

        verify(
          () => mockPreferences.setString('scan_history', any()),
        ).called(1);
      });
    });

    group('Edge cases', () {
      test('handles empty uuid string', () async {
        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan('', 'Device Name');

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        expect(savedHistory.first['uuid'], equals(''));
      });

      test('handles empty device name', () async {
        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan('device-uuid', '');

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        expect(savedHistory.first['name'], equals(''));
      });

      test('handles special characters in device name', () async {
        const specialName = 'Device & "Special" Ąę';

        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        when(
          () => mockPreferences.setString('scan_history', any()),
        ).thenAnswer((_) async => true);

        await scanHistoryService.addScan('device-uuid', specialName);

        final captured =
            verify(
                  () => mockPreferences.setString('scan_history', captureAny()),
                ).captured[0]
                as String;

        final savedHistory = jsonDecode(captured) as List<dynamic>;
        expect(savedHistory.first['name'], equals(specialName));
      });
    });
  });

  group('ScanHistoryService - getHistory', () {
    late ScanHistoryService scanHistoryService;
    late MockSharedPreferences mockPreferences;

    setUp(() {
      mockPreferences = MockSharedPreferences();

      scanHistoryService = ScanHistoryService(preferences: mockPreferences);
    });

    group('Success cases', () {
      test('returns empty list when no history exists', () async {
        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        final result = await scanHistoryService.getHistory();

        expect(result, isEmpty);
      });

      test('returns list of scans from storage', () async {
        final history = [
          {
            'uuid': 'device-uuid-1',
            'name': 'Device 1',
            'timestamp': '2024-01-01T10:00:00Z',
          },
          {
            'uuid': 'device-uuid-2',
            'name': 'Device 2',
            'timestamp': '2024-01-01T11:00:00Z',
          },
        ];

        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn(jsonEncode(history));

        final result = await scanHistoryService.getHistory();

        expect(result, equals(history));
      });

      test('preserves order of scans in history', () async {
        final history = [
          {
            'uuid': 'uuid-1',
            'name': 'First',
            'timestamp': '2024-01-01T10:00:00Z',
          },
          {
            'uuid': 'uuid-2',
            'name': 'Second',
            'timestamp': '2024-01-01T11:00:00Z',
          },
          {
            'uuid': 'uuid-3',
            'name': 'Third',
            'timestamp': '2024-01-01T12:00:00Z',
          },
        ];

        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn(jsonEncode(history));

        final result = await scanHistoryService.getHistory();

        expect(
          result.map((item) => item['uuid']).toList(),
          equals(['uuid-1', 'uuid-2', 'uuid-3']),
        );
      });

      test('returns all required fields for each scan', () async {
        final history = [
          {
            'uuid': 'device-uuid',
            'name': 'Device Name',
            'timestamp': '2024-01-01T10:00:00Z',
          },
        ];

        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn(jsonEncode(history));

        final result = await scanHistoryService.getHistory();

        expect(result.first.containsKey('uuid'), isTrue);
        expect(result.first.containsKey('name'), isTrue);
        expect(result.first.containsKey('timestamp'), isTrue);
      });
    });

    group('Storage interactions', () {
      test('calls getString with correct key', () async {
        when(() => mockPreferences.getString('scan_history')).thenReturn(null);

        await scanHistoryService.getHistory();

        verify(() => mockPreferences.getString('scan_history')).called(1);
      });
    });

    group('Parsing and edge cases', () {
      test('handles malformed JSON gracefully by throwing', () async {
        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn('invalid json {[}');

        expect(() => scanHistoryService.getHistory(), throwsException);
      });

      test('returns list with single item', () async {
        final history = [
          {
            'uuid': 'device-uuid',
            'name': 'Single Device',
            'timestamp': '2024-01-01T10:00:00Z',
          },
        ];

        when(
          () => mockPreferences.getString('scan_history'),
        ).thenReturn(jsonEncode(history));

        final result = await scanHistoryService.getHistory();

        expect(result.length, equals(1));
      });
    });
  });

  group('ScanHistoryService - clearHistory', () {
    late ScanHistoryService scanHistoryService;
    late MockSharedPreferences mockPreferences;

    setUp(() {
      mockPreferences = MockSharedPreferences();

      scanHistoryService = ScanHistoryService(preferences: mockPreferences);
    });

    group('Success cases', () {
      test('clears history from storage', () async {
        when(
          () => mockPreferences.remove('scan_history'),
        ).thenAnswer((_) async => true);

        await scanHistoryService.clearHistory();

        verify(() => mockPreferences.remove('scan_history')).called(1);
      });

      test('returns without error when clearing empty history', () async {
        when(
          () => mockPreferences.remove('scan_history'),
        ).thenAnswer((_) async => true);

        expect(() => scanHistoryService.clearHistory(), returnsNormally);
      });

      test('clears history even if it had many items', () async {
        when(
          () => mockPreferences.remove('scan_history'),
        ).thenAnswer((_) async => true);

        await scanHistoryService.clearHistory();

        verify(() => mockPreferences.remove('scan_history')).called(1);
      });
    });

    group('Storage interactions', () {
      test('calls remove with correct key', () async {
        when(
          () => mockPreferences.remove('scan_history'),
        ).thenAnswer((_) async => true);

        await scanHistoryService.clearHistory();

        verify(() => mockPreferences.remove('scan_history')).called(1);
      });

      test('does not call other storage methods', () async {
        when(
          () => mockPreferences.remove('scan_history'),
        ).thenAnswer((_) async => true);

        await scanHistoryService.clearHistory();

        verifyNever(() => mockPreferences.getString(any()));
        verifyNever(() => mockPreferences.setString(any(), any()));
      });
    });

    group('Edge cases', () {
      test('handles storage errors gracefully', () async {
        when(
          () => mockPreferences.remove('scan_history'),
        ).thenThrow(Exception('Storage error'));

        expect(() => scanHistoryService.clearHistory(), throwsException);
      });
    });
  });

  group('ScanHistoryService - Dependency Injection', () {
    test('uses injected SharedPreferences instance', () async {
      final mockPreferences = MockSharedPreferences();

      when(() => mockPreferences.getString('scan_history')).thenReturn(null);

      when(
        () => mockPreferences.setString('scan_history', any()),
      ).thenAnswer((_) async => true);

      final service = ScanHistoryService(preferences: mockPreferences);

      await service.addScan('uuid', 'name');

      verify(() => mockPreferences.getString('scan_history')).called(1);
    });

    test('uses provided SharedPreferences instance', () {
      final mockPreferences = MockSharedPreferences();
      final service = ScanHistoryService(preferences: mockPreferences);
      expect(service, isA<ScanHistoryService>());
    });
  });
}
