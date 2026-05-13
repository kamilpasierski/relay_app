import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/scan_history_service.dart';
import 'package:relay_app/features/faults/presentation/screens/fault_report_screen.dart';
import 'package:relay_app/core/widgets/confirmation_dialog.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = ScanHistoryService().getHistory();
    });
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Wyczyść historię',
        message:
            'Czy na pewno chcesz usunąć wszystkie zapisane skany? Tej operacji nie można cofnąć.',
        confirmLabel: 'Usuń',
        confirmColor: AppTheme.alertRedText,
        onConfirm: () async {
          await ScanHistoryService().clearHistory();
          _loadHistory();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Historia została wyczyszczona')),
            );
          }
        },
      ),
    );
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString).toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia skanów'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Wyczyść historię',
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(
              child: Text(
                'Brak historii skanów.\nZeskanuj kod Q urządzenia, aby się tu pojawiło.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryDark,
                  child: Icon(Icons.qr_code, color: Colors.white, size: 20),
                ),
                title: Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${item['uuid']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(item['timestamp']),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FaultReportScreen(deviceId: item['uuid']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
