import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:relay_app/features/account/presentation/screens/account_screen.dart';
import 'package:relay_app/core/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      routes: {
        '/welcome': (context) => const Scaffold(body: Text('Ekran Powitalny')),
        '/change-password': (context) =>
            const Scaffold(body: Text('Zmień Hasło')),
      },
      home: AccountScreen(authService: mockAuthService),
    );
  }

  group('AccountScreen Widget Tests', () {
    testWidgets('wyświetla loader podczas pobierania profilu', (
      WidgetTester tester,
    ) async {
      when(
        () => mockAuthService.getUserProfile(),
      ).thenAnswer((_) => Completer<Map<String, dynamic>?>().future);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('wyświetla adres e-mail po udanym pobraniu danych', (
      WidgetTester tester,
    ) async {
      final fakeUserData = {'email': 'test@relay.pl'};

      when(
        () => mockAuthService.getUserProfile(),
      ).thenAnswer((_) async => fakeUserData);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('test@relay.pl'), findsOneWidget);
    });

    testWidgets('wyświetla "Nie zalogowano" gdy API zwraca null lub błąd', (
      WidgetTester tester,
    ) async {
      when(
        () => mockAuthService.getUserProfile(),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Nie zalogowano'), findsOneWidget);
    });

    testWidgets(
      'obsługuje pełny proces wylogowania (Dialog + czyszczenie sesji + nawigacja)',
      (WidgetTester tester) async {
        when(
          () => mockAuthService.getUserProfile(),
        ).thenAnswer((_) async => {'email': 'test@relay.pl'});

        when(() => mockAuthService.clearSession()).thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wyloguj się'));
        await tester.pumpAndSettle();

        expect(find.text('Czy na pewno chcesz się wylogować?'), findsOneWidget);

        await tester.tap(find.text('Wyloguj'));
        await tester.pumpAndSettle();

        verify(() => mockAuthService.clearSession()).called(1);

        expect(find.text('Ekran Powitalny'), findsOneWidget);
      },
    );
  });
}
