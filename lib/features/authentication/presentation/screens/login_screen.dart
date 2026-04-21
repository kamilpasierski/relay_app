import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/custom_text_field.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/features/home/presentation/screens/home_screen.dart';
import 'package:relay_app/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Proszę wypełnić wszystkie pola.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(ApiConfig.login);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final AuthService authService = AuthService();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        debugPrint('System autoryzowany. Token: $token');

        await authService.saveToken(token);
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (response.statusCode == 401) {
        _showError('Nieprawidłowe dane logowania.');
      } else {
        _showError('Błąd serwera: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Błąd sieci: $e');
      _showError('Nie udało się połączyć z serwerem.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.brandOrange,
                      ),
                    )
                  : PrimaryButton(
                      label: 'Zaloguj się',
                      onPressed: _handleLogin,
                    ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Powrót do ekranu powitalnego'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
