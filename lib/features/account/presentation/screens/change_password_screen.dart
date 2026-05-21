import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/core/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await AuthService().changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasło zostało pomyślnie zmienione.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się zmienić hasła. Sprawdź obecne hasło.'),
          backgroundColor: AppTheme.alertRedText,
        ),
      );
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zmień hasło'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordField(
                label: 'Obecne hasło',
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                onToggleVisibility: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Podaj obecne hasło' : null,
              ),
              _buildPasswordField(
                label: 'Nowe hasło',
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onToggleVisibility: () =>
                    setState(() => _obscureNew = !_obscureNew),
                validator: (val) {
                  if (val == null || val.length < 8) {
                    return 'Hasło musi mieć min. 8 znaków';
                  }
                  return null;
                },
              ),
              _buildPasswordField(
                label: 'Powtórz nowe hasło',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val != _newPasswordController.text) {
                    return 'Hasła nie pasują do siebie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.brandOrange,
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Zapisz nowe hasło',
                        onPressed: _submit,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
