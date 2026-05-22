import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:relay_app/core/services/auth_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('AuthService - verifyTwoFactorCode', () {
    late AuthService authService;
    late MockHttpClient mockHttpClient;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockStorage = MockSecureStorage();

      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      authService = AuthService(
        httpClient: mockHttpClient,
        storage: mockStorage,
      );
    });

    group('HTTP error responses (4xx/5xx)', () {
      test('receives 200 status and calls mocked HTTP client', () async {
        const intermediateToken = 'test_intermediate_token';
        const code = '123456';

        final response = http.Response(
          jsonEncode({'access_token': 'test_access_token_xyz'}),
          200,
        );

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        await authService.verifyTwoFactorCode(intermediateToken, code);

        verify(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).called(1);
      });
    });

    group('HTTP error responses (4xx/5xx)', () {
      test('returns false on 401 Unauthorized response', () async {
        final response = http.Response(
          jsonEncode({'error': 'Unauthorized', 'message': 'Invalid code'}),
          401,
        );

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        final result = await authService.verifyTwoFactorCode(
          'invalid_token',
          '000000',
        );

        expect(result, isFalse);
      });

      test('returns false on 400 Bad Request', () async {
        final response = http.Response(
          jsonEncode({
            'error': 'Validation error',
            'message': 'Code must be 6 digits',
          }),
          400,
        );

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        final result = await authService.verifyTwoFactorCode(
          'test_token',
          'invalid_code',
        );

        expect(result, isFalse);
      });

      test('returns false on 403 Forbidden', () async {
        final response = http.Response(
          jsonEncode({'error': 'Forbidden', 'message': 'Token expired'}),
          403,
        );

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        final result = await authService.verifyTwoFactorCode(
          'expired_token',
          '123456',
        );

        expect(result, isFalse);
      });

      test('returns false on 500 Server Error', () async {
        final response = http.Response(
          jsonEncode({'error': 'Internal server error'}),
          500,
        );

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        final result = await authService.verifyTwoFactorCode(
          'test_token',
          '123456',
        );

        expect(result, isFalse);
      });

      test('returns false when response body missing access_token', () async {
        final response = http.Response(
          jsonEncode({'token_type': 'Bearer', 'expires_in': 3600}),
          200,
        );

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        final result = await authService.verifyTwoFactorCode(
          'test_token',
          '123456',
        );

        expect(result, isFalse);
      });

      test('returns false when access_token field is null', () async {
        final response = http.Response(jsonEncode({'access_token': null}), 200);

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        final result = await authService.verifyTwoFactorCode(
          'test_token',
          '123456',
        );

        expect(result, isFalse);
      });
    });

    group('Network and parsing errors', () {
      test('returns false when HTTP post throws an exception', () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('Network error'));

        final result = await authService.verifyTwoFactorCode(
          'test_token',
          '123456',
        );

        expect(result, isFalse);
      });

      test('returns false on connection timeout exception', () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('Connection timed out'));

        final result = await authService.verifyTwoFactorCode(
          'test_token',
          '123456',
        );

        expect(result, isFalse);
      });

      test('returns false when response body is not valid JSON', () async {
        final response = http.Response('Invalid JSON {[}', 200);

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        final result = await authService.verifyTwoFactorCode(
          'test_token',
          '123456',
        );

        expect(result, isFalse);
      });
    });

    group('HTTP request validation', () {
      test(
        'sends POST request with correct Accept and Content-Type headers',
        () async {
          final response = http.Response(
            jsonEncode({'access_token': 'token'}),
            200,
          );

          when(
            () => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) => Future.value(response));

          await authService.verifyTwoFactorCode('token', '123456');

          verify(
            () => mockHttpClient.post(
              any(),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: any(named: 'body'),
            ),
          ).called(1);
        },
      );

      test('sends POST request to /auth/2fa/verify endpoint', () async {
        final response = http.Response(
          jsonEncode({'access_token': 'token'}),
          200,
        );

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) => Future.value(response));

        await authService.verifyTwoFactorCode('token', '123456');

        final captured = verify(
          () => mockHttpClient.post(
            captureAny(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).captured;

        final uri = captured[0] as Uri;
        expect(uri.toString(), endsWith('/auth/2fa/verify'));
      });
    });
  });
}
