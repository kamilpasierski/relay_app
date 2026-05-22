import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/services/device_service.dart';
import 'package:relay_app/core/services/auth_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthService extends Mock implements AuthService {}

class FakeUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('DeviceService - getDeviceDetails', () {
    late DeviceService deviceService;
    late MockHttpClient mockHttpClient;
    late MockAuthService mockAuthService;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockAuthService = MockAuthService();

      deviceService = DeviceService(
        httpClient: mockHttpClient,
        authService: mockAuthService,
      );
    });

    group('Success cases', () {
      test('returns device details when response status is 200', () async {
        const uuid = 'test-device-uuid';
        const token = 'test_token_xyz';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => token);

        final deviceData = {
          'id': uuid,
          'name': 'Test Device',
          'status': 'online',
        };

        final response = http.Response(jsonEncode(deviceData), 200);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        final result = await deviceService.getDeviceDetails(uuid);

        expect(result, equals(deviceData));
      });

      test(
        'extracts device data from response when wrapped in data field',
        () async {
          const uuid = 'test-device-uuid';
          const token = 'test_token_xyz';

          when(() => mockAuthService.getToken()).thenAnswer((_) async => token);

          final wrappedData = {
            'data': {'id': uuid, 'name': 'Test Device', 'status': 'online'},
          };

          final response = http.Response(jsonEncode(wrappedData), 200);

          when(
            () => mockHttpClient.get(any(), headers: any(named: 'headers')),
          ).thenAnswer((_) => Future.value(response));

          final result = await deviceService.getDeviceDetails(uuid);

          expect(result, equals(wrappedData['data']));
        },
      );

      test('includes Authorization header when token is available', () async {
        const uuid = 'test-device-uuid';
        const token = 'test_token_xyz';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => token);

        final response = http.Response(
          jsonEncode({'id': uuid, 'name': 'Test Device'}),
          200,
        );

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        await deviceService.getDeviceDetails(uuid);

        verify(
          () => mockHttpClient.get(
            any(),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        ).called(1);
      });

      test(
        'sends GET request without Authorization header when token is null',
        () async {
          const uuid = 'test-device-uuid';

          when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

          final response = http.Response(
            jsonEncode({'id': uuid, 'name': 'Test Device'}),
            200,
          );

          when(
            () => mockHttpClient.get(any(), headers: any(named: 'headers')),
          ).thenAnswer((_) => Future.value(response));

          await deviceService.getDeviceDetails(uuid);

          verify(
            () => mockHttpClient.get(
              any(),
              headers: {'Accept': 'application/json'},
            ),
          ).called(1);
        },
      );

      test('sends GET request to correct endpoint', () async {
        const uuid = 'test-device-uuid';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        final response = http.Response(jsonEncode({'id': uuid}), 200);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        await deviceService.getDeviceDetails(uuid);

        final captured = verify(
          () =>
              mockHttpClient.get(captureAny(), headers: any(named: 'headers')),
        ).captured;

        final uri = captured[0] as Uri;
        expect(uri.toString(), endsWith('/devices/$uuid'));
      });
    });

    group('HTTP error responses (4xx/5xx)', () {
      test('returns null on 404 Not Found', () async {
        const uuid = 'nonexistent-uuid';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        final response = http.Response(jsonEncode({'error': 'Not found'}), 404);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        final result = await deviceService.getDeviceDetails(uuid);

        expect(result, isNull);
      });

      test('returns null on 401 Unauthorized', () async {
        const uuid = 'test-device-uuid';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        final response = http.Response(
          jsonEncode({'error': 'Unauthorized'}),
          401,
        );

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        final result = await deviceService.getDeviceDetails(uuid);

        expect(result, isNull);
      });

      test('returns null on 403 Forbidden', () async {
        const uuid = 'test-device-uuid';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => 'token');

        final response = http.Response(jsonEncode({'error': 'Forbidden'}), 403);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        final result = await deviceService.getDeviceDetails(uuid);

        expect(result, isNull);
      });

      test('returns null on 500 Server Error', () async {
        const uuid = 'test-device-uuid';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        final response = http.Response(
          jsonEncode({'error': 'Internal server error'}),
          500,
        );

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        final result = await deviceService.getDeviceDetails(uuid);

        expect(result, isNull);
      });
    });

    group('Network and parsing errors', () {
      test('returns null when HTTP get throws an exception', () async {
        const uuid = 'test-device-uuid';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenThrow(Exception('Network error'));

        final result = await deviceService.getDeviceDetails(uuid);

        expect(result, isNull);
      });

      test('returns null on connection timeout', () async {
        const uuid = 'test-device-uuid';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenThrow(Exception('Connection timed out'));

        final result = await deviceService.getDeviceDetails(uuid);

        expect(result, isNull);
      });

      test('returns null when response body is not valid JSON', () async {
        const uuid = 'test-device-uuid';

        when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

        final response = http.Response('Invalid JSON {[}', 200);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        final result = await deviceService.getDeviceDetails(uuid);

        expect(result, isNull);
      });
    });
  });

  group('DeviceService - getDeviceEvents', () {
    late DeviceService deviceService;
    late MockHttpClient mockHttpClient;
    late MockAuthService mockAuthService;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockAuthService = MockAuthService();

      deviceService = DeviceService(
        httpClient: mockHttpClient,
        authService: mockAuthService,
      );
    });

    group('Success cases', () {
      test(
        'returns list of device events when response status is 200',
        () async {
          const uuid = 'test-device-uuid';

          final events = [
            {
              'id': 'event-1',
              'type': 'switch_on',
              'timestamp': '2024-01-01T10:00:00Z',
            },
            {
              'id': 'event-2',
              'type': 'switch_off',
              'timestamp': '2024-01-01T11:00:00Z',
            },
          ];

          final response = http.Response(jsonEncode(events), 200);

          when(
            () => mockHttpClient.get(any(), headers: any(named: 'headers')),
          ).thenAnswer((_) => Future.value(response));

          final result = await deviceService.getDeviceEvents(uuid);

          expect(result, equals(events));
        },
      );

      test('returns empty list when response contains empty array', () async {
        const uuid = 'test-device-uuid';

        final response = http.Response(jsonEncode([]), 200);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        final result = await deviceService.getDeviceEvents(uuid);

        expect(result, isEmpty);
      });

      test('sends GET request to correct events endpoint', () async {
        const uuid = 'test-device-uuid';

        final response = http.Response(jsonEncode([]), 200);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        await deviceService.getDeviceEvents(uuid);

        final captured = verify(
          () =>
              mockHttpClient.get(captureAny(), headers: any(named: 'headers')),
        ).captured;

        final uri = captured[0] as Uri;
        expect(uri.toString(), endsWith('/devices/$uuid/events'));
      });

      test('sends Accept header with application/json', () async {
        const uuid = 'test-device-uuid';

        final response = http.Response(jsonEncode([]), 200);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        await deviceService.getDeviceEvents(uuid);

        verify(
          () => mockHttpClient.get(
            any(),
            headers: {'Accept': 'application/json'},
          ),
        ).called(1);
      });
    });

    group('HTTP error responses (4xx/5xx)', () {
      test('throws exception on 404 Not Found', () async {
        const uuid = 'nonexistent-uuid';

        final response = http.Response(
          jsonEncode({'error': 'Device not found'}),
          404,
        );

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        expect(() => deviceService.getDeviceEvents(uuid), throwsException);
      });

      test('throws exception on 401 Unauthorized', () async {
        const uuid = 'test-device-uuid';

        final response = http.Response(
          jsonEncode({'error': 'Unauthorized'}),
          401,
        );

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        expect(() => deviceService.getDeviceEvents(uuid), throwsException);
      });

      test('throws exception on 500 Server Error', () async {
        const uuid = 'test-device-uuid';

        final response = http.Response(
          jsonEncode({'error': 'Internal server error'}),
          500,
        );

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        expect(() => deviceService.getDeviceEvents(uuid), throwsException);
      });

      test(
        'throws exception with meaningful message on error status codes',
        () async {
          const uuid = 'test-device-uuid';

          final response = http.Response(
            jsonEncode({'error': 'Failed to fetch'}),
            502,
          );

          when(
            () => mockHttpClient.get(any(), headers: any(named: 'headers')),
          ).thenAnswer((_) => Future.value(response));

          expect(
            () => deviceService.getDeviceEvents(uuid),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Nie udało się pobrać historii urządzenia'),
              ),
            ),
          );
        },
      );
    });

    group('Network and parsing errors', () {
      test('throws exception when HTTP get throws an exception', () async {
        const uuid = 'test-device-uuid';

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenThrow(Exception('Network error'));

        expect(
          () => deviceService.getDeviceEvents(uuid),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Błąd połączenia z serwerem'),
            ),
          ),
        );
      });

      test('throws exception on connection timeout', () async {
        const uuid = 'test-device-uuid';

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenThrow(Exception('Connection timed out'));

        expect(() => deviceService.getDeviceEvents(uuid), throwsException);
      });

      test('throws exception when response body is not valid JSON', () async {
        const uuid = 'test-device-uuid';

        final response = http.Response('Invalid JSON {[}', 200);

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) => Future.value(response));

        expect(() => deviceService.getDeviceEvents(uuid), throwsException);
      });
    });
  });
}
