import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/custom_text_field.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/features/authentication/presentation/screens/verify_pin_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitRequest() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Proszę podać prawidłowy adres e-mail.');
      return;
    }

    setState(() => _isLoading = true);

    final success = await AuthService().sendMobileResetPin(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kod PIN został wysłany na Twój adres e-mail.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VerifyPinScreen(email: email)),
      );
    } else {
      _showError(
        'Nie udało się wysłać kodu. Sprawdź e-mail lub spróbuj później.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('Reset hasła'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: AppTheme.brandOrange,
              ),
              const SizedBox(height: 32),
              const Text(
                'Zapomniałeś hasła?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Podaj adres e-mail przypisany do Twojego konta. Wyślemy na niego 6-cyfrowy kod PIN.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: CustomTextField(
                  label: 'Adres E-mail',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),

              const SizedBox(height: 32),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.brandOrange,
                      ),
                    )
                  : PrimaryButton(
                      label: 'Wyślij kod PIN',
                      onPressed: _submitRequest,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
