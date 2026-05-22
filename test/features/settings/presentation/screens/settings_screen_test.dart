import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:relay_app/core/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockAuthService mockAuthService;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockHttpClient = MockHttpClient();
  });

  Widget createWidget({bool isAdmin = true}) {
    return MaterialApp(
      home: SettingsScreen(
        isAdmin: isAdmin,
        authService: mockAuthService,
        httpClient: mockHttpClient,
      ),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets(
      'ukrywa sekcję BEZPIECZEŃSTWO jeśli użytkownik nie jest adminem',
      (tester) async {
        when(() => mockAuthService.getUserProfile()).thenAnswer(
          (_) async => {'is_admin': false, 'has_2fa_enabled': false},
        );

        await tester.pumpWidget(createWidget(isAdmin: false));
        await tester.pumpAndSettle();

        expect(find.text('BEZPIECZEŃSTWO'), findsNothing);
        expect(find.text('Dwustopniowa autentykacja (2FA)'), findsNothing);
      },
    );

    testWidgets('wyświetla zielony SnackBar po udanym pingu do serwera', (
      tester,
    ) async {
      when(
        () => mockAuthService.getUserProfile(),
      ).thenAnswer((_) async => null);

      when(
        () => mockHttpClient.get(any(that: isA<Uri>())),
      ).thenAnswer((_) async => http.Response('pong', 200));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final pingButton = find.text('Testuj połączenie (Ping)');
      await tester.ensureVisible(pingButton);
      await tester.tap(pingButton);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHttpClient.get(any(that: isA<Uri>()))).called(1);
      expect(
        find.text('Połączenie nawiązane. Serwer odpowiada poprawnie.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'wyświetla okno dialogowe z kluczami po pomyślnym włączeniu 2FA',
      (tester) async {
        when(
          () => mockAuthService.getUserProfile(),
        ).thenAnswer((_) async => {'is_admin': true, 'has_2fa_enabled': false});

        final fakeSetupData = {
          'secret': 'TAJNY_KOD_123',
          'recovery_codes': ['CODE-1', 'CODE-2'],
        };

        when(
          () => mockAuthService.enable2FA(),
        ).thenAnswer((_) async => fakeSetupData);

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final twoFaSwitch = find.descendant(
          of: find.ancestor(
            of: find.text('Dwustopniowa autentykacja (2FA)'),
            matching: find.byType(ListTile),
          ),
          matching: find.byType(Switch),
        );

        await tester.tap(twoFaSwitch);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Konfiguracja 2FA'), findsOneWidget);
        expect(find.text('TAJNY_KOD_123'), findsOneWidget);
        expect(find.text('- CODE-1'), findsOneWidget);
        expect(find.text('- CODE-2'), findsOneWidget);
      },
    );

    testWidgets('wyświetla SnackBar z błędem przy nieudanym wyłączeniu 2FA', (
      tester,
    ) async {
      when(
        () => mockAuthService.getUserProfile(),
      ).thenAnswer((_) async => {'is_admin': true, 'has_2fa_enabled': true});

      when(() => mockAuthService.disable2FA()).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final twoFaSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Dwustopniowa autentykacja (2FA)'),
          matching: find.byType(ListTile),
        ),
        matching: find.byType(Switch),
      );

      await tester.tap(twoFaSwitch);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockAuthService.disable2FA()).called(1);
      expect(find.text('Błąd podczas wyłączania 2FA'), findsOneWidget);
    });
  });
}
