import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:relay_app/features/account/presentation/screens/change_password_screen.dart';
import 'package:relay_app/core/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangePasswordScreen(authService: mockAuthService),
    );
  }

  group('ChangePasswordScreen Widget Tests', () {
    testWidgets('wyświetla błędy walidacji przy pustym formularzu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final submitButton = find.text('Zapisz nowe hasło');
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Podaj obecne hasło'), findsOneWidget);
      expect(find.text('Hasło musi mieć min. 8 znaków'), findsOneWidget);

      verifyNever(() => mockAuthService.changePassword(any(), any(), any()));
    });

    testWidgets('wyświetla błąd gdy hasła się nie zgadzają', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);

      await tester.enterText(textFields.at(0), 'stareHaslo123');
      await tester.enterText(textFields.at(1), 'noweHaslo123');
      await tester.enterText(textFields.at(2), 'noweHaslo456');
      await tester.tap(find.text('Zapisz nowe hasło'));
      await tester.pump();

      expect(find.text('Hasła nie pasują do siebie'), findsOneWidget);
      verifyNever(() => mockAuthService.changePassword(any(), any(), any()));
    });

    testWidgets('wyświetla loader podczas wysyłania zapytania do API', (
      WidgetTester tester,
    ) async {
      when(
        () => mockAuthService.changePassword(any(), any(), any()),
      ).thenAnswer((_) => Completer<bool>().future);

      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'stareHaslo123');
      await tester.enterText(textFields.at(1), 'noweHaslo123');
      await tester.enterText(textFields.at(2), 'noweHaslo123');

      await tester.tap(find.text('Zapisz nowe hasło'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Zapisz nowe hasło'), findsNothing);
    });

    testWidgets('wyświetla zielony SnackBar i wraca po udanej zmianie', (
      WidgetTester tester,
    ) async {
      when(
        () => mockAuthService.changePassword(any(), any(), any()),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'stareHaslo123');
      await tester.enterText(textFields.at(1), 'noweHaslo123');
      await tester.enterText(textFields.at(2), 'noweHaslo123');

      await tester.tap(find.text('Zapisz nowe hasło'));

      await tester.pump();
      await tester.pump();

      verify(
        () => mockAuthService.changePassword(
          'stareHaslo123',
          'noweHaslo123',
          'noweHaslo123',
        ),
      ).called(1);

      expect(find.text('Hasło zostało pomyślnie zmienione.'), findsOneWidget);
    });

    testWidgets(
      'wyświetla czerwony SnackBar po błędzie (np. złe stare hasło)',
      (WidgetTester tester) async {
        when(
          () => mockAuthService.changePassword(any(), any(), any()),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createWidgetUnderTest());

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'stareZLEhaslo');
        await tester.enterText(textFields.at(1), 'noweHaslo123');
        await tester.enterText(textFields.at(2), 'noweHaslo123');

        await tester.tap(find.text('Zapisz nowe hasło'));

        await tester.pump();
        await tester.pump();

        expect(
          find.text('Nie udało się zmienić hasła. Sprawdź obecne hasło.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'wyświetla czerwony SnackBar po błędzie (np. złe stare hasło)',
      (WidgetTester tester) async {
        when(
          () => mockAuthService.changePassword(any(), any(), any()),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createWidgetUnderTest());

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'stareZLEhaslo');
        await tester.enterText(textFields.at(1), 'noweHaslo123');
        await tester.enterText(textFields.at(2), 'noweHaslo123');

        await tester.tap(find.text('Zapisz nowe hasło'));
        await tester.pumpAndSettle();

        expect(
          find.text('Nie udało się zmienić hasła. Sprawdź obecne hasło.'),
          findsOneWidget,
        );
      },
    );
  });
}
