import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import '../../../../core/widgets/main_drawer.dart';
import '../../../../core/services/notification_service.dart';
import 'package:relay_app/features/devices/presentation/screens/device_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService().initNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Główny'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
      ),
      drawer: const MainDrawer(),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.qr_code_scanner, size: 28),
          label: const Text(
            'Skaner kodów QR',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            final String? scannedUuid = await Navigator.of(context)
                .push<String>(
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(),
                  ),
                );

            if (scannedUuid != null && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DeviceProfileScreen(
                    deviceId: scannedUuid,
                    isFromScanner: true,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
