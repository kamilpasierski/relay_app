import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';

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
            onTap: () => Navigator.pop(context),
          ),
          _DrawerItem(
            icon: Icons.qr_code_scanner,
            title: 'Skaner kodów QR',
            onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(),
                  ),
                );
              },
          ),
          const Spacer(),
          const Divider(),
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