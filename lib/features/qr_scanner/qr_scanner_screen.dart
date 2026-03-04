import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';

class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detekcja QR'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: AppTheme.surfaceWhite,
      ),
      body: Center(
        
            // TODO: Bindowanie natywnego interfejsu API kamery i dekodera strumienia
            

          ),
        );
  }
}