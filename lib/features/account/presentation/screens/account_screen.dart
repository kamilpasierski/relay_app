import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/core/widgets/confirmation_dialog.dart'; // Nowy import

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Wylogowanie',
        message: 'Czy na pewno chcesz wylogować się z systemu?',
        confirmLabel: 'Wyloguj',
        onConfirm: () async {
          await AuthService().clearSession();
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/welcome', (route) => false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Wyloguj się',
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
