import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/core/widgets/confirmation_dialog.dart';

class AccountScreen extends StatelessWidget {
  final AuthService authService;

  AccountScreen({super.key, AuthService? authService})
    : authService = authService ?? AuthService();

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Wylogowanie',
        message: 'Czy na pewno chcesz się wylogować?',
        confirmLabel: 'Wyloguj',
        onConfirm: () async {
          await authService.clearSession();
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
      appBar: AppBar(title: const Text('Profil'), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: authService.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.brandOrange),
            );
          }

          final userData = snapshot.data;
          final email = userData?['email'] ?? 'Nie zalogowano';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  Icon(
                    Icons.account_circle_rounded,
                    size: 120,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 48),

                  PrimaryButton(
                    label: 'Zmień hasło',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/change-password'),
                  ),
                  const SizedBox(height: 16),

                  PrimaryButton(
                    label: 'Wyloguj się',
                    onPressed: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
