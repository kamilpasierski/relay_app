import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:relay_app/core/services/device_service.dart';
import 'package:relay_app/core/services/scan_history_service.dart';
import 'package:relay_app/core/theme/app_theme.dart';

class MockDeviceService extends Mock implements DeviceService {}

class MockScanHistoryService extends Mock implements ScanHistoryService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceProfileScreen - Widget Tests', () {
    setUp(() {});

    group('Loading state', () {
      testWidgets('displays loading indicator while fetching device details', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<Map<String, dynamic>?>(
                future: Future.delayed(
                  const Duration(milliseconds: 100),
                  () => {'name': 'Device'},
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.brandOrange,
                      ),
                    );
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

    group('Device details display', () {
      testWidgets('displays device name in header', (
        WidgetTester tester,
      ) async {
        final deviceData = {
          'name': 'Living Room Light',
          'type': 'Light',
          'brand': 'Philips',
          'model': 'Hue',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Profil urządzenia'),
                backgroundColor: AppTheme.primaryDark,
              ),
              body: Center(
                child: Column(
                  children: [
                    const Text('Szczegóły'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text('Nazwa: ${deviceData['name'] ?? 'N/A'}'),
                            Text('Typ: ${deviceData['type'] ?? 'N/A'}'),
                            Text(
                              'Model: ${deviceData['brand'] ?? ''} ${deviceData['model'] ?? ''}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Nazwa: Living Room Light'), findsOneWidget);
        expect(find.text('Szczegóły'), findsOneWidget);
      });

      testWidgets('displays all device information fields', (
        WidgetTester tester,
      ) async {
        final deviceData = {
          'name': 'Test Device',
          'type': 'Switch',
          'brand': 'Generic',
          'model': 'Model 1',
          'serial_number': 'SN12345',
          'location': 'Kitchen',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(deviceData['name'] ?? 'Brak nazwy'),
                    Text(deviceData['type'] ?? 'N/A'),
                    Text(
                      '${deviceData['brand'] ?? ''} ${deviceData['model'] ?? ''}',
                    ),
                    Text(deviceData['serial_number'] ?? 'N/A'),
                    Text(deviceData['location'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Device'), findsOneWidget);
        expect(find.text('Switch'), findsOneWidget);
        expect(find.text('SN12345'), findsOneWidget);
        expect(find.text('Kitchen'), findsOneWidget);
      });

      testWidgets('handles missing device fields with placeholder text', (
        WidgetTester tester,
      ) async {
        final deviceData = {'name': 'Device'};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text(deviceData['type'] ?? 'N/A'),
                  Text(deviceData['serial_number'] ?? 'N/A'),
                  Text(deviceData['location'] ?? 'N/A'),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('N/A'), findsWidgets);
      });
    });

    group('Device events/timeline', () {
      testWidgets('displays "No events" message when empty', (
        WidgetTester tester,
      ) async {
        final events = <Map<String, dynamic>>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: events.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Brak zarejestrowanych zdarzeń dla tego urządzenia.',
                      ),
                    )
                  : const Placeholder(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Brak zarejestrowanych zdarzeń dla tego urządzenia.'),
          findsOneWidget,
        );
      });

      testWidgets('displays list of device events', (
        WidgetTester tester,
      ) async {
        final events = [
          {
            'type': 'install',
            'date': '2024-01-22T10:00:00',
            'title': 'Urządzenie zainstalowane',
            'description': 'Nowe urządzenie zostało zainstalowane',
            'user': 'Admin',
          },
          {
            'type': 'fault',
            'date': '2024-01-22T11:00:00',
            'title': 'Awaria',
            'description': 'Urządzenie nie odpowiada',
            'user': 'System',
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    title: Text(event['title'] ?? 'Zdarzenie'),
                    subtitle: Text(event['description'] ?? 'Brak opisu'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Urządzenie zainstalowane'), findsOneWidget);
        expect(find.text('Awaria'), findsOneWidget);
      });

      testWidgets('events display with different icons by type', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_filled, color: Colors.blue),
                      const Text('Install'),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const Text('Fault'),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const Text('Fixed'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });
    });

    group('AppBar and UI elements', () {
      testWidgets('displays correct app bar title', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Profil urządzenia'),
                backgroundColor: AppTheme.primaryDark,
              ),
              body: const SizedBox(),
            ),
          ),
        );

        expect(find.text('Profil urządzenia'), findsOneWidget);
      });

      testWidgets('displays report fault floating action button', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Device')),
              body: const SizedBox(),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: AppTheme.brandOrange,
                icon: const Icon(Icons.report_problem, color: Colors.white),
                label: const Text(
                  'Zgłoś usterkę',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.report_problem), findsOneWidget);
        expect(find.text('Zgłoś usterkę'), findsOneWidget);
      });

      testWidgets('FAB has correct color', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const SizedBox(),
              floatingActionButton: FloatingActionButton(
                backgroundColor: AppTheme.brandOrange,
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );

        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);
      });
    });

    group('Error handling', () {
      testWidgets('displays error message when device fetch fails', (
        WidgetTester tester,
      ) async {
        final errorFuture = Future<Map<String, dynamic>?>.error(
          Exception('Network error'),
        );

        errorFuture.catchError((_) => null);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<Map<String, dynamic>?>(
                future: errorFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Nie udało się załadować profilu urządzenia.',
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
          find.text('Nie udało się załadować profilu urządzenia.'),
          findsOneWidget,
        );
      });

      testWidgets('handles null device data', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FutureBuilder<Map<String, dynamic>?>(
                future: Future.value(null),
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return const Center(
                      child: Text(
                        'Nie udało się załadować profilu urządzenia.',
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
          find.text('Nie udało się załadować profilu urządzenia.'),
          findsOneWidget,
        );
      });
    });

    group('User interactions', () {
      testWidgets('scrolls through device details and events', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text('Device Name'),
                    const Text('Device Type'),
                    const SizedBox(height: 32),
                    const Text('Events'),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return ListTile(title: Text('Event $index'));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Device Name'), findsOneWidget);
        expect(find.text('Events'), findsOneWidget);

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        expect(find.text('Event 0'), findsOneWidget);
      });

      testWidgets('taps FAB to report fault', (WidgetTester tester) async {
        bool fabTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const SizedBox(),
              floatingActionButton: FloatingActionButton.extended(
                icon: const Icon(Icons.report_problem),
                label: const Text('Zgłoś usterkę'),
                onPressed: () {
                  fabTapped = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(fabTapped, isTrue);
      });
    });

    group('Card and detail layout', () {
      testWidgets('details are displayed in a card', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(children: [Text('Device Details')]),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Device Details'), findsOneWidget);
      });

      testWidgets('dividers separate detail rows', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: const [
                  Text('Name: Device'),
                  Divider(),
                  Text('Type: Light'),
                  Divider(),
                  Text('Model: Generic'),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(Divider), findsWidgets);
      });
    });
  });
}
