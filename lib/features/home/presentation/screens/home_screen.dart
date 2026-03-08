import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import '../../../../core/widgets/main_drawer.dart';
import '../../../../core/widgets/nav_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        child: NavButton(
          icon: Icons.qr_code_scanner,
          label: 'Skaner kodów QR',
          destination: const QrScannerScreen(),
        ),
      ),
    );
  }
}