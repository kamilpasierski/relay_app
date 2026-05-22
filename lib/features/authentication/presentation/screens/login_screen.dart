import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/custom_text_field.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/features/home/presentation/screens/home_screen.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/features/authentication/presentation/screens/two_factor_screen.dart';
import 'package:relay_app/features/authentication/presentation/screens/forgot_password_screen.dart';

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

        if (data['requires_2fa'] == true &&
            data['intermediate_token'] != null) {
          final String tokenTymczasowy = data['intermediate_token'];

          debugPrint('Wymagane 2FA. Przekierowanie do ekranu kodu.');
          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TwoFactorScreen(intermediateToken: tokenTymczasowy),
            ),
          );
          return;
        }

        final token = data['access_token'];

        if (token != null) {
          debugPrint('System autoryzowany. Token: $token');
          await authService.saveToken(token);
          if (!mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          _showError('Błąd autoryzacji: Serwer nie zwrócił tokenu dostępu.');
        }
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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final bool success = await AuthService().signInWithGoogle();

      if (success) {
        if (!mounted) return;
        debugPrint('Zalogowano pomyślnie przez Google OAuth.');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        _showError('Logowanie Google zostało przerwane lub wystąpił błąd.');
      }
    } catch (e) {
      debugPrint('Wyjątek Google Auth w UI: $e');
      _showError('Wystąpił nieoczekiwany błąd podczas logowania Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Logowanie')),
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

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                  child: const Text('Zapomniałeś hasła? Resetuj'),
                ),
              ),
              const SizedBox(height: 16),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.brandOrange,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryButton(
                          label: 'Zaloguj się',
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                'lub',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? AppTheme.textSecondaryDark
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 30,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Zaloguj przez Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDarkMode
                                  ? AppTheme.borderDark
                                  : Colors.grey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                        ),
                      ],
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
