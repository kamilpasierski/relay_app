import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

import 'package:relay_app/features/faults/presentation/screens/fault_report_screen.dart';
import 'package:relay_app/core/services/device_service.dart';
import 'package:relay_app/core/services/auth_service.dart';

class MockDeviceService extends Mock implements DeviceService {}

class MockAuthService extends Mock implements AuthService {}

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockDeviceService mockDeviceService;
  late MockAuthService mockAuthService;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockDeviceService = MockDeviceService();
    mockAuthService = MockAuthService();
    mockHttpClient = MockHttpClient();
  });

  Widget createWidget() {
    return MaterialApp(
      home: FaultReportScreen(
        deviceId: '123',
        deviceService: mockDeviceService,
        authService: mockAuthService,
        httpClient: mockHttpClient,
      ),
    );
  }

  group('FaultReportScreen Tests', () {
    testWidgets('wyświetla błąd gdy nie pobierze urządzenia', (tester) async {
      final errorFuture = Future<Map<String, dynamic>?>.error(
        Exception('Błąd'),
      );
      errorFuture.catchError((_) => null);

      when(
        () => mockDeviceService.getDeviceDetails(any()),
      ).thenAnswer((_) => errorFuture);
      when(
        () => mockAuthService.getCurrentUser(),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Nie udało się pobrać danych urządzenia'),
        findsOneWidget,
      );
    });

    testWidgets('wysyła zgłoszenie pomyślnie (weryfikacja API)', (
      tester,
    ) async {
      when(() => mockDeviceService.getDeviceDetails('123')).thenAnswer(
        (_) async => {
          'name': 'Test Device',
          'type': 'Sensor',
          'brand': 'Acme',
          'model': 'X1',
        },
      );
      when(() => mockAuthService.getCurrentUser()).thenAnswer(
        (_) async => {'name': 'Jan Zgłaszacz', 'email': 'jan@test.pl'},
      );
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 201));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Wszystko się pali',
      );

      await tester.scrollUntilVisible(
        find.text('Wyślij zgłoszenie'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Wyślij zgłoszenie'));
      await tester.pumpAndSettle();

      verify(
        () => mockHttpClient.post(
          any(that: isA<Uri>()),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });
  });
}
