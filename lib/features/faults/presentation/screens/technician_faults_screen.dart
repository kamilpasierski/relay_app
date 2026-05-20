import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/fault_service.dart';

class TechnicianFaultsScreen extends StatefulWidget {
  const TechnicianFaultsScreen({super.key});

  @override
  State<TechnicianFaultsScreen> createState() => _TechnicianFaultsScreenState();
}

class _TechnicianFaultsScreenState extends State<TechnicianFaultsScreen> {
  final FaultService _faultService = FaultService();
  String _selectedFilter = 'all';

  late Future<List<Map<String, dynamic>>> _faultsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFaults();
  }

  void _refreshFaults() {
    setState(() {
      _faultsFuture = _faultService.getFaults();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.alertRedText;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusTranslation(String status) {
    switch (status) {
      case 'pending':
        return 'Nowe';
      case 'in_progress':
        return 'W trakcie';
      case 'resolved':
        return 'Rozwiązane';
      default:
        return status;
    }
  }

  void _changeStatusDialog(int faultId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmień status zgłoszenia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Nowe'),
              leading: const Icon(
                Icons.fiber_new,
                color: AppTheme.alertRedText,
              ),
              onTap: () => _updateStatus(faultId, 'pending'),
            ),
            ListTile(
              title: const Text('W trakcie'),
              leading: const Icon(Icons.loop, color: Colors.orange),
              onTap: () => _updateStatus(faultId, 'in_progress'),
            ),
            ListTile(
              title: const Text('Rozwiązane'),
              leading: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
              ),
              onTap: () => _updateStatus(faultId, 'resolved'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    Navigator.pop(context);
    final success = await _faultService.updateFaultStatus(id, newStatus);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status został zaktualizowany.'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshFaults();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zmienić statusu.'),
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
        title: const Text('Zgłoszone usterki'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFaults,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'Wszystkie'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Nowe'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'W trakcie'),
                const SizedBox(width: 8),
                _buildFilterChip('resolved', 'Rozwiązane'),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _faultsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.brandOrange,
                    ),
                  );
                }

                var faults = snapshot.data ?? [];

                if (_selectedFilter != 'all') {
                  faults = faults
                      .where((f) => f['status'] == _selectedFilter)
                      .toList();
                }

                if (faults.isEmpty) {
                  return const Center(
                    child: Text('Brak zgłoszeń o tym statusie.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: faults.length,
                  itemBuilder: (context, index) {
                    final fault = faults[index];
                    final status = fault['status'] ?? 'pending';

                    final device = fault['device'] as Map<String, dynamic>?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(
                            status,
                          ).withOpacity(0.1),
                          child: Icon(
                            Icons.report_problem,
                            color: _getStatusColor(status),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          fault['title'] ?? 'Zgłoszenie bez tytułu',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${device?['name'] ?? 'Nieznane urządzenie'} • ${_getStatusTranslation(status)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit_note,
                            color: AppTheme.primaryDark,
                          ),
                          onPressed: () =>
                              _changeStatusDialog(fault['id'], status),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Opis błędu:',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fault['description'] ?? 'Brak opisu usterki.',
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Zgłosił: ${fault['reported_by'] ?? 'Anonimowo'} (${fault['contact'] ?? 'Brak kontaktu'})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'ID: #${fault['id']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterType, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == filterType,
      selectedColor: AppTheme.brandOrange.withOpacity(0.2),
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _selectedFilter = filterType);
        }
      },
    );
  }
}
