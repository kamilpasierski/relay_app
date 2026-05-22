import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'package:relay_app/core/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPingLoading = false;
  bool _is2FALoading = false;
  bool? _isAdmin;
  bool? _is2FAEnabled;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();

    if (profile != null && mounted) {
      setState(() {
        _is2FAEnabled = profile['has_2fa_enabled'] == true;
        _isAdmin = profile['is_admin'] == true;
      });
    } else if (mounted) {
      setState(() {
        _is2FAEnabled = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isPingLoading = true);
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/ping'))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnackBar(
          'Połączenie nawiązane. Serwer odpowiada poprawnie.',
          Colors.green,
        );
      } else {
        _showSnackBar(
          'Błąd serwera: Status ${response.statusCode}',
          Colors.orange,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Brak połączenia z serwerem: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isPingLoading = false);
    }
  }

  Future<void> _toggle2FA(bool value) async {
    setState(() => _is2FALoading = true);
    try {
      if (value) {
        final setupData = await _authService.enable2FA();

        if (!mounted) return;

        if (setupData != null) {
          setState(() => _is2FAEnabled = true);

          _showSetupDialog(setupData['secret'], setupData['recovery_codes']);
          _showSnackBar('2FA zostało zainicjalizowane', Colors.green);
        } else {
          _showSnackBar('Nie udało się wygenerować klucza 2FA', Colors.red);
        }
      } else {
        final success = await _authService.disable2FA();
        if (!mounted) return;
        if (success) {
          setState(() => _is2FAEnabled = false);
          _showSnackBar('2FA wyłączone', Colors.green);
        } else {
          _showSnackBar('Błąd podczas wyłączania 2FA', Colors.red);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Błąd: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _is2FALoading = false);
    }
  }

  void _showSetupDialog(String secret, List<dynamic> recoveryCodes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Konfiguracja 2FA'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wpisz poniższy klucz w aplikacji Google Authenticator:',
              ),
              const SizedBox(height: 12),
              SelectableText(
                secret,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.brandOrange,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Kody zapasowe (zapisz je!):'),
              ...recoveryCodes.map((code) => Text('- $code')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij i zapisz'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'INTERFEJS',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Tryb ciemny'),
            subtitle: const Text('Zmień motyw aplikacji'),
            value: isDarkMode,
            onChanged: (bool value) async {
              await AppTheme.toggleTheme(value);
            },
          ),
          if (_isAdmin == true) ...[
            const SizedBox(height: 24),
            const Text(
              'BEZPIECZEŃSTWO',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.security_outlined),
              title: const Text('Dwustopniowa autentykacja (2FA)'),
              value: _is2FAEnabled ?? false,
              onChanged: _is2FALoading ? null : _toggle2FA,
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'SERWER I DIAGNOSTYKA',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Testuj połączenie (Ping)'),
            subtitle: Text('Aktualny adres: ${ApiConfig.baseUrl}'),
            trailing: _isPingLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            onTap: _isPingLoading ? null : _testConnection,
          ),
        ],
      ),
    );
  }
}
