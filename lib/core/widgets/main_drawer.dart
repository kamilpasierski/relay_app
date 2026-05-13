import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/auth_service.dart'; // Dodany import serwisu
import 'package:relay_app/features/account/presentation/screens/account_screen.dart';
import 'package:relay_app/features/authentication/presentation/screens/login_screen.dart'; // Dodany import ekranu logowania
import 'package:relay_app/features/devices/presentation/screens/device_profile_screen.dart';
import 'package:relay_app/features/home/presentation/screens/home_screen.dart';
import 'package:relay_app/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import 'package:relay_app/features/scan_history/presentation/screens/scan_history_screen.dart';
import 'package:relay_app/features/faults/presentation/screens/fault_report_screen.dart';

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
            title: 'Skaner kodów QR (Test)',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeviceProfileScreen(
                    deviceId: '019e209b-51e8-73cb-88b6-886757298f5b',
                    isFromScanner: true,
                  ),
                ),
              );
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
