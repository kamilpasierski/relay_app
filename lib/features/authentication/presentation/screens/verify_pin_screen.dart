import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/custom_text_field.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/core/services/auth_service.dart';

class VerifyPinScreen extends StatefulWidget {
  final String email;

  const VerifyPinScreen({super.key, required this.email});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (pin.length != 6) {
      _showError('PIN musi składać się z 6 cyfr.');
      return;
    }

    if (password.length < 8) {
      _showError('Hasło musi mieć co najmniej 8 znaków.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Hasła nie pasują do siebie.');
      return;
    }

    setState(() => _isLoading = true);

    final success = await AuthService().resetPasswordWithPin(
      widget.email,
      pin,
      password,
      confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hasło zostało pomyślnie zmienione! Możesz się zalogować.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showError('Błędny lub wygasły kod PIN. Spróbuj ponownie.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Wprowadź kod PIN')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.lock_reset,
                size: 80,
                color: AppTheme.brandOrange,
              ),
              const SizedBox(height: 24),
              Text(
                'Ustaw nowe hasło',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Wysłaliśmy 6-cyfrowy kod PIN na adres:\n${widget.email}',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.brightness == Brightness.dark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              CustomTextField(
                label: '6-cyfrowy kod PIN',
                icon: Icons.numbers,
                controller: _pinController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Nowe hasło',
                icon: Icons.password,
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Powtórz nowe hasło',
                icon: Icons.password_outlined,
                controller: _confirmPasswordController,
                isPassword: true,
              ),

              const SizedBox(height: 40),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.brandOrange,
                      ),
                    )
                  : PrimaryButton(label: 'Zmień hasło', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
