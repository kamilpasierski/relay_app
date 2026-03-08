import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/widgets/app_branding.dart';
import 'package:relay_app/core/widgets/nav_button.dart';
import 'package:relay_app/features/home/presentation/screens/home_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppBranding(),
                const SizedBox(height: 60),
                
                const NavButton(
                  icon: Icons.login,
                  label: 'Zaloguj się',
                  destination: LoginScreen(),
                ),
                
                const SizedBox(height: 16),
                
                const NavButton(
                  icon: Icons.person_outline,
                  label: 'Korzystaj jako gość',
                  destination: HomeScreen(),
                  isInverted: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}