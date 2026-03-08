import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';

class AppBranding extends StatelessWidget {
  const AppBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandOrange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.sensors,
            size: 64,
            color: AppTheme.brandOrange,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'RELAY',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            color: AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }
}