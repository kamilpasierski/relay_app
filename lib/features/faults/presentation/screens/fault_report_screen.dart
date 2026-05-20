import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/core/services/device_service.dart';
import 'package:relay_app/core/services/auth_service.dart';

class FaultReportScreen extends StatefulWidget {
  final String deviceId;

  const FaultReportScreen({super.key, required this.deviceId});

  @override
  State<FaultReportScreen> createState() => _FaultReportScreenState();
}

class _FaultReportScreenState extends State<FaultReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reportedByController = TextEditingController();
  final _contactController = TextEditingController();

  bool _isLoadingReport = false;
  bool _isFetchingUser = true;
  Map<String, dynamic>? _currentUser;

  late Future<Map<String, dynamic>?> _deviceFuture;

  @override
  void initState() {
    super.initState();
    _deviceFuture = DeviceService().getDeviceDetails(widget.deviceId);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        if (user != null) {
          _reportedByController.text = user['name'] ?? '';
          _contactController.text = user['email'] ?? '';
        }
        _isFetchingUser = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reportedByController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoadingReport = true);

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/public/devices/${widget.deviceId}/faults',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'reported_by': _currentUser != null
              ? _currentUser!['name']
              : 'Anonim',
          'contact': _currentUser != null ? _currentUser!['email'] : null,
          'status': 'pending',
        }),
      );

      setState(() => _isLoadingReport = false);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zgłoszenie wysłane!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd serwera: ${response.statusCode}'),
            backgroundColor: AppTheme.alertRedText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReport = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Błąd połączenia. Spróbuj ponownie.'),
            backgroundColor: AppTheme.alertRedText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zgłoszenie usterki'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _deviceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isFetchingUser) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.brandOrange),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Nie udało się pobrać danych urządzenia.\nSprawdź kod QR lub połączenie.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final device = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rozpoznane urządzenie:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.memory,
                          'Nazwa:',
                          device['name'] ?? 'Brak nazwy',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          Icons.category,
                          'Typ:',
                          device['type'] ?? 'N/A',
                        ),
                        _buildInfoRow(
                          Icons.build,
                          'Model:',
                          '${device['brand']} ${device['model']}',
                        ),
                        _buildInfoRow(
                          Icons.qr_code,
                          'Numer seryjny:',
                          device['serial_number'] ?? 'N/A',
                        ),
                        _buildInfoRow(
                          Icons.location_on,
                          'Lokalizacja:',
                          device['location'] ?? 'Brak lokalizacji',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Szczegóły zgłoszenia:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_currentUser != null) ...[
                        TextFormField(
                          controller: _reportedByController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Osoba zgłaszająca',
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactController,
                          readOnly: true, // Blokada edycji
                          decoration: InputDecoration(
                            labelText: 'E-mail kontaktowy',
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tytuł usterki *',
                          hintText: 'Np. Brak zasilania',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Proszę podać tytuł usterki'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Opis problemu',
                          hintText: 'Opisz dokładnie, co nie działa...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _isLoadingReport
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.brandOrange,
                        ),
                      )
                    : PrimaryButton(
                        label: 'Wyślij zgłoszenie',
                        onPressed: _submitReport,
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
