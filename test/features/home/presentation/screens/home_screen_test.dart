import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:relay_app/features/home/presentation/screens/home_screen.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/core/services/notification_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockAuthService mockAuthService;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockNotificationService = MockNotificationService();

    when(
      () => mockNotificationService.initNotifications(),
    ).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: HomeScreen(
        authService: mockAuthService,
        notificationService: mockNotificationService,
      ),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('wywołuje inicjalizację powiadomień przy starcie ekranu', (
      tester,
    ) async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => null);
      when(
        () => mockAuthService.getCurrentUser(),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      verify(() => mockNotificationService.initNotifications()).called(1);
    });

    testWidgets('wyświetla tryb gościa (niezalogowanego)', (tester) async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => null);
      when(
        () => mockAuthService.getCurrentUser(),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Skaner kodów'), findsOneWidget);
      expect(find.text('Historia'), findsOneWidget);
      expect(find.text('Ustawienia'), findsOneWidget);

      expect(find.text('Zaloguj się'), findsOneWidget);
      expect(find.text('Profil'), findsNothing);

      expect(find.byIcon(Icons.engineering_outlined), findsNothing);
    });

    testWidgets(
      'wyświetla tryb zalogowanego użytkownika (bez uprawnień serwisanta)',
      (tester) async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'fake_token');
        when(
          () => mockAuthService.getCurrentUser(),
        ).thenAnswer((_) async => {'is_service': false, 'is_admin': false});

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Zaloguj się'), findsNothing);
        expect(find.text('Profil'), findsOneWidget);

        expect(find.byIcon(Icons.engineering_outlined), findsNothing);
      },
    );

    testWidgets(
      'wyświetla przycisk panelu serwisanta dla autoryzowanej obsługi',
      (tester) async {
        when(
          () => mockAuthService.getToken(),
        ).thenAnswer((_) async => 'fake_token');
        when(
          () => mockAuthService.getCurrentUser(),
        ).thenAnswer((_) async => {'is_service': true, 'is_admin': false});

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.engineering_outlined), findsOneWidget);
        expect(find.byTooltip('Panel Serwisanta'), findsOneWidget);
      },
    );

    testWidgets('wyświetla przycisk panelu serwisanta dla administratora', (
      tester,
    ) async {
      when(
        () => mockAuthService.getToken(),
      ).thenAnswer((_) async => 'fake_token');
      when(
        () => mockAuthService.getCurrentUser(),
      ).thenAnswer((_) async => {'is_service': false, 'is_admin': true});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.engineering_outlined), findsOneWidget);
    });
  });
}
