import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/features/account/presentation/screens/account_screen.dart';
import 'package:relay_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:relay_app/features/devices/presentation/screens/device_profile_screen.dart';
import 'package:relay_app/features/home/presentation/screens/home_screen.dart';
import 'package:relay_app/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import 'package:relay_app/features/scan_history/presentation/screens/scan_history_screen.dart';
import 'package:relay_app/features/faults/presentation/screens/technician_faults_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const _DrawerHeader(),
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            title: 'Strona główna',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          _DrawerItem(
            icon: Icons.qr_code_scanner,
            title: 'Skaner kodów QR',
            onTap: () async {
              final String? scannedUuid = await Navigator.of(context)
                  .push<String>(
                    MaterialPageRoute(
                      builder: (context) => const QrScannerScreen(),
                    ),
                  );

              if (!context.mounted) return;

              Navigator.of(context).pop();

              if (scannedUuid != null) {
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
          _DrawerItem(
            icon: Icons.history_rounded,
            title: 'Historia skanowania',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ScanHistoryScreen(),
                ),
              );
            },
          ),
          FutureBuilder<Map<String, dynamic>?>(
            future: AuthService().getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              final userData = snapshot.data;

              final bool hasServiceAccess =
                  userData != null &&
                  (userData['is_service'] == true ||
                      userData['is_service'] == 1 ||
                      userData['is_admin'] == true ||
                      userData['is_admin'] == 1);

              if (!hasServiceAccess) {
                return const SizedBox.shrink();
              }

              return _DrawerItem(
                icon: Icons.engineering_outlined,
                title: 'Panel Serwisanta',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TechnicianFaultsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const Spacer(),
          const Divider(),

          FutureBuilder<String?>(
            future: AuthService().getToken(),
            builder: (context, snapshot) {
              final bool isLoggedIn = snapshot.hasData && snapshot.data != null;

              if (isLoggedIn) {
                return _DrawerItem(
                  icon: Icons.account_circle_rounded,
                  title: 'Profil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AccountScreen(),
                      ),
                    );
                  },
                );
              } else {
                return _DrawerItem(
                  icon: Icons.login_rounded,
                  title: 'Zaloguj się',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                );
              }
            },
          ),

          const SizedBox(height: 16),
          _DrawerItem(
            icon: Icons.settings_outlined,
            title: 'Ustawienia',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: AppTheme.primaryDark),
      child: const Center(
        child: Text(
          'Relay App',
          style: TextStyle(
            color: AppTheme.surfaceWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryDark),
      title: Text(title),
      onTap: onTap,
    );
  }
}
