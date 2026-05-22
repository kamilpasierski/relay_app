import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:relay_app/features/faults/presentation/screens/technician_faults_screen.dart';
import 'package:relay_app/core/services/fault_service.dart';

class MockFaultService extends Mock implements FaultService {}

void main() {
  late MockFaultService mockFaultService;

  setUp(() {
    mockFaultService = MockFaultService();
  });

  Widget createWidget() {
    return MaterialApp(
      home: TechnicianFaultsScreen(faultService: mockFaultService),
    );
  }

  group('TechnicianFaultsScreen Tests', () {
    testWidgets('wyświetla pustą listę zgłoszeń', (tester) async {
      when(() => mockFaultService.getFaults()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Brak zgłoszeń o tym statusie.'), findsOneWidget);
    });

    testWidgets('filtrowanie listy po kliknięciu w Chip', (tester) async {
      final mockFaults = [
        {'id': 1, 'title': 'Zepsuty kabel', 'status': 'pending'},
        {'id': 2, 'title': 'Zalana płyta', 'status': 'resolved'},
      ];

      when(
        () => mockFaultService.getFaults(),
      ).thenAnswer((_) async => mockFaults);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Zepsuty kabel'), findsOneWidget);
      expect(find.text('Zalana płyta'), findsOneWidget);

      await tester.tap(find.text('Rozwiązane').first);
      await tester.pumpAndSettle();

      expect(find.text('Zepsuty kabel'), findsNothing);
      expect(find.text('Zalana płyta'), findsOneWidget);
    });

    testWidgets('obsługuje zmianę statusu przez dialog', (tester) async {
      final mockFaults = [
        {'id': 1, 'title': 'Zepsuty kabel', 'status': 'pending'},
      ];

      when(
        () => mockFaultService.getFaults(),
      ).thenAnswer((_) async => mockFaults);
      when(
        () => mockFaultService.updateFaultStatus(1, 'in_progress'),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zepsuty kabel'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      await tester.tap(find.text('W trakcie').last);

      await tester.pump();
      await tester.pump();

      verify(
        () => mockFaultService.updateFaultStatus(1, 'in_progress'),
      ).called(1);
      expect(find.text('Status został zaktualizowany.'), findsOneWidget);
    });
  });
}
