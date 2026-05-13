import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/device_service.dart';
import 'package:relay_app/core/services/scan_history_service.dart';
import 'package:relay_app/features/faults/presentation/screens/fault_report_screen.dart';

class DeviceProfileScreen extends StatefulWidget {
  final String deviceId;
  final bool isFromScanner;

  const DeviceProfileScreen({
    super.key,
    required this.deviceId,
    this.isFromScanner = false,
  });

  @override
  State<DeviceProfileScreen> createState() => _DeviceProfileScreenState();
}

class _DeviceProfileScreenState extends State<DeviceProfileScreen> {
  late Future<Map<String, dynamic>?> _deviceFuture;
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _deviceFuture = _fetchAndLogDevice();
    _eventsFuture = DeviceService().getDeviceEvents(widget.deviceId);
  }

  Future<Map<String, dynamic>?> _fetchAndLogDevice() async {
    final device = await DeviceService().getDeviceDetails(widget.deviceId);

    if (device != null && widget.isFromScanner) {
      final deviceName = device['name'] ?? 'Nieznane urządzenie';
      await ScanHistoryService().addScan(widget.deviceId, deviceName);
    }

    return device;
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString).toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil urządzenia'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
      ),
      body: FutureBuilder(
        future: Future.wait([_deviceFuture, _eventsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.brandOrange),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data![0] == null) {
            return const Center(
              child: Text('Nie udało się załadować profilu urządzenia.'),
            );
          }

          final device = snapshot.data![0] as Map<String, dynamic>;
          final events = snapshot.data![1] as List<Map<String, dynamic>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Szczegóły',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                          device['location'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Historia zdarzeń',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ...events.map((event) => _buildTimelineItem(event)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brandOrange,
        icon: const Icon(Icons.report_problem, color: Colors.white),
        label: const Text(
          'Zgłoś usterkę',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FaultReportScreen(deviceId: widget.deviceId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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

  Widget _buildTimelineItem(Map<String, dynamic> event) {
    Color dotColor = Colors.blue;
    IconData dotIcon = Icons.info;
    if (event['type'] == 'fault') {
      dotColor = AppTheme.alertRedText;
      dotIcon = Icons.warning;
    } else if (event['type'] == 'fixed') {
      dotColor = Colors.green;
      dotIcon = Icons.check_circle;
    } else if (event['type'] == 'install') {
      dotColor = AppTheme.primaryDark;
      dotIcon = Icons.play_circle_filled;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Icon(dotIcon, color: dotColor, size: 24),
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(event['date']),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['description'],
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Użytkownik: ${event['user']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
