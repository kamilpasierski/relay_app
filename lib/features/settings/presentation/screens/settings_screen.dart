import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPingLoading = false;

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
