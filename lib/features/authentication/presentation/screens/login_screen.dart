import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/custom_text_field.dart';
import 'package:relay_app/core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text;
    final password = _passwordController.text;

    debugPrint('Inicjacja procesu autoryzacji dla wektora: $email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('Logowanie'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: AppTheme.brandOrange,
              ),
              const SizedBox(height: 32),
              
              CustomTextField(
                label: 'Adres E-mail',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              
              CustomTextField(
                label: 'Hasło',
                icon: Icons.password_outlined,
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 32),
              
              PrimaryButton(
                label: 'Zaloguj system',
                onPressed: _handleLogin,
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Powrót do ekranu powitalnego'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}