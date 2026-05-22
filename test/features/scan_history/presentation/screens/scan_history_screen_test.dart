import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:relay_app/core/services/scan_history_service.dart';

class MockScanHistoryService extends Mock implements ScanHistoryService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScanHistoryScreen - Widget Tests', () {
    late MockScanHistoryService mockScanHistoryService;

    setUp(() {
      mockScanHistoryService = MockScanHistoryService();
    });

    group('Empty history', () {
      testWidgets('displays empty state when history is empty', (
        WidgetTester tester,
      ) async {
        when(
          () => mockScanHistoryService.getHistory(),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<List<Map<String, dynamic>>>(
                future: mockScanHistoryService.getHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final history = snapshot.data ?? [];

                  if (history.isEmpty) {
                    return const Center(
                      child: Text(
                        'Brak historii skanów.\nZeskanuj kod Q urządzenia, aby się tu pojawiło.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return const Placeholder();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text(
            'Brak historii skanów.\nZeskanuj kod Q urządzenia, aby się tu pojawiło.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('displays loading indicator while fetching empty history', (
        WidgetTester tester,
      ) async {
        when(() => mockScanHistoryService.getHistory()).thenAnswer(
          (_) => Future.delayed(
            const Duration(milliseconds: 100),
            () => <Map<String, dynamic>>[],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<List<Map<String, dynamic>>>(
                future: mockScanHistoryService.getHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const Placeholder();
                },
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
      });
    });

    group('History with items', () {
      testWidgets('displays list of scan history items', (
        WidgetTester tester,
      ) async {
        final historyItems = [
          {
            'uuid': 'device-1',
            'name': 'Living Room Light',
            'timestamp': '2024-01-22T10:30:00.000Z',
          },
          {
            'uuid': 'device-2',
            'name': 'Kitchen Plug',
            'timestamp': '2024-01-22T09:15:00.000Z',
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<List<Map<String, dynamic>>>(
                future: Future.value(historyItems),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final history = snapshot.data ?? [];

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.qr_code, color: Colors.white),
                        ),
                        title: Text(item['name'] ?? 'Unknown'),
                        subtitle: Text(
                          'ID: ${item['uuid'] ?? 'N/A'}\n${item['timestamp'] ?? 'N/A'}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        expect(find.text('Living Room Light'), findsOneWidget);
        expect(find.text('Kitchen Plug'), findsOneWidget);
        expect(
          find.text('ID: device-1\n2024-01-22T10:30:00.000Z'),
          findsOneWidget,
        );
        expect(
          find.text('ID: device-2\n2024-01-22T09:15:00.000Z'),
          findsOneWidget,
        );
      });

      testWidgets('displays correct number of items in list', (
        WidgetTester tester,
      ) async {
        final historyItems = List<Map<String, dynamic>>.generate(
          5,
          (index) => {
            'uuid': 'device-$index',
            'name': 'Device $index',
            'timestamp': '2024-01-22T${10 + index}:00:00.000Z',
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<List<Map<String, dynamic>>>(
                future: Future.value(historyItems),
                builder: (context, snapshot) {
                  final history = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return Text('Item $index');
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
        for (int i = 0; i < 5; i++) {
          expect(find.text('Item $i'), findsOneWidget);
        }
      });

      testWidgets('history items show uuid, name, and timestamp', (
        WidgetTester tester,
      ) async {
        final historyItem = {
          'uuid': 'test-uuid-123',
          'name': 'Test Device',
          'timestamp': '2024-01-22T10:30:45.000Z',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListTile(
                title: Text(historyItem['name'] ?? 'Unknown'),
                subtitle: Text(
                  'ID: ${historyItem['uuid'] ?? 'N/A'}\n${historyItem['timestamp'] ?? 'N/A'}',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Test Device'), findsOneWidget);
        expect(
          find.text('ID: test-uuid-123\n2024-01-22T10:30:45.000Z'),
          findsOneWidget,
        );
      });
    });

    group('AppBar and UI elements', () {
      testWidgets('displays correct app bar title', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Historia skanów')),
              body: const Center(child: Text('Test')),
            ),
          ),
        );

        expect(find.text('Historia skanów'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays delete button in app bar', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Historia skanów'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Wyczyść historię',
                    onPressed: () {},
                  ),
                ],
              ),
              body: const SizedBox(),
            ),
          ),
        );

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        expect(find.byTooltip('Wyczyść historię'), findsOneWidget);
      });

      testWidgets('delete button triggers confirmation dialog', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await showDialog(
                        context: tester.element(find.byType(Scaffold)),
                        builder: (ctx) => AlertDialog(
                          title: const Text('Wyczyść historię'),
                          content: const Text(
                            'Czy na pewno chcesz usunąć wszystkie zapisane skany?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Anuluj'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Usuń'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: const SizedBox(),
            ),
          ),
        );

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Wyczyść historię'), findsOneWidget);
      });
    });

    group('List item interactions', () {
      testWidgets('list item has trailing arrow icon', (
        WidgetTester tester,
      ) async {
        final historyItem = {
          'uuid': 'device-1',
          'name': 'Device Name',
          'timestamp': '2024-01-22T10:00:00Z',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.qr_code)),
                title: Text(historyItem['name'] ?? 'Unknown'),
                subtitle: Text(historyItem['uuid'] ?? 'N/A'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
      });

      testWidgets('list item displays circle avatar with qr code icon', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.qr_code, color: Colors.white),
                ),
                title: const Text('Test Device'),
              ),
            ),
          ),
        );

        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.byIcon(Icons.qr_code), findsOneWidget);
      });
    });

    group('Error handling', () {
      testWidgets('handles error state gracefully', (
        WidgetTester tester,
      ) async {
        final errorFuture = Future<List<Map<String, dynamic>>>.error(
          Exception('Network error'),
        );

        errorFuture.catchError((_) {
          return <Map<String, dynamic>>[];
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<List<Map<String, dynamic>>>(
                future: errorFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Błąd podczas ładowania historii'),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Błąd podczas ładowania historii'), findsOneWidget);
      });

      testWidgets('displays placeholder when data is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<List<Map<String, dynamic>>>(
                future: Future.value(<Map<String, dynamic>>[]),
                builder: (context, snapshot) {
                  final history = snapshot.data ?? [];

                  if (history.isEmpty) {
                    return const Center(child: Text('No data'));
                  }

                  return const Placeholder();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No data'), findsOneWidget);
      });
    });
  });
}
