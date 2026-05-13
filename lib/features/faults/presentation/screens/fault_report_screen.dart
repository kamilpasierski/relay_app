import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/primary_button.dart';
import 'package:relay_app/core/services/device_service.dart';
import 'package:relay_app/features/devices/presentation/screens/device_profile_screen.dart';

class FaultReportScreen extends StatefulWidget {
  final String deviceId;

  const FaultReportScreen({super.key, required this.deviceId});

  @override
  State<FaultReportScreen> createState() => _FaultReportScreenState();
}

class _FaultReportScreenState extends State<FaultReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  bool _isLoadingReport = false;
  late Future<Map<String, dynamic>?> _deviceFuture;

  @override
  void initState() {
    super.initState();
    _deviceFuture = DeviceService().getDeviceDetails(widget.deviceId);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoadingReport = true);

    // TODO: Zapis zgłoszenia do API (POST /api/faults)
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoadingReport = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zgłoszenie wysłane!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
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
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                  'Opis problemu:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Opisz dokładnie, co nie działa...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Proszę opisać problem'
                        : null,
                  ),
                ),
                const SizedBox(height: 32),

                _isLoadingReport
                    ? const Center(child: CircularProgressIndicator())
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
