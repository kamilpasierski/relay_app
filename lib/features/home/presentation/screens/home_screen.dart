import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/core/services/notification_service.dart';
import 'package:relay_app/core/widgets/dashboard_tile.dart';
import 'package:relay_app/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import 'package:relay_app/features/devices/presentation/screens/device_profile_screen.dart';
import 'package:relay_app/features/scan_history/presentation/screens/scan_history_screen.dart';
import 'package:relay_app/features/account/presentation/screens/account_screen.dart';
import 'package:relay_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:relay_app/features/faults/presentation/screens/technician_faults_screen.dart';
import 'package:relay_app/features/settings/presentation/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final NotificationService notificationService;

  HomeScreen({
    super.key,
    AuthService? authService,
    NotificationService? notificationService,
  }) : authService = authService ?? AuthService(),
       notificationService = notificationService ?? NotificationService();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.notificationService.initNotifications();
  }

  void _refreshScreen() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relay App'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
        automaticallyImplyLeading: false,
        actions: [
          FutureBuilder<Map<String, dynamic>?>(
            future: widget.authService.getCurrentUser(),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              final bool hasServiceAccess =
                  userData != null &&
                  (userData['is_service'] == true ||
                      userData['is_service'] == 1 ||
                      userData['is_admin'] == true ||
                      userData['is_admin'] == 1);

              if (!hasServiceAccess) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.engineering_outlined),
                tooltip: 'Panel Serwisanta',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TechnicianFaultsScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              DashboardTile(
                icon: Icons.qr_code_scanner,
                title: 'Skaner kodów',
                backgroundColor: AppTheme.primaryDark,
                textColor: Colors.white,
                iconColor: Colors.white,
                onTap: () async {
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
              DashboardTile(
                icon: Icons.history_rounded,
                title: 'Historia',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ScanHistoryScreen(),
                    ),
                  );
                },
              ),
              FutureBuilder<String?>(
                future: widget.authService.getToken(),
                builder: (context, snapshot) {
                  final bool isLoggedIn =
                      snapshot.hasData && snapshot.data != null;

                  return DashboardTile(
                    icon: isLoggedIn
                        ? Icons.account_circle_rounded
                        : Icons.login_rounded,
                    title: isLoggedIn ? 'Profil' : 'Zaloguj się',
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => isLoggedIn
                                  ? AccountScreen()
                                  : const LoginScreen(),
                            ),
                          )
                          .then((_) => _refreshScreen());
                    },
                  );
                },
              ),
              FutureBuilder<Map<String, dynamic>?>(
                future: widget.authService.getCurrentUser(),
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  final bool isAdmin =
                      userData != null &&
                      (userData['is_admin'] == true ||
                          userData['is_admin'] == 1);

                  return DashboardTile(
                    icon: Icons.settings_outlined,
                    title: 'Ustawienia',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingsScreen(isAdmin: isAdmin),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
