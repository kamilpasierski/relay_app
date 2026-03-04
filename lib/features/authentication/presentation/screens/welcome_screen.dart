import 'package:relay_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/features/authentication/presentation/screens/login_screen.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              const Icon(
                Icons.bolt, //logo aplikacji
                size: 80,
                color: AppTheme.brandOrange,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Relay',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'System zgłoszeń',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const Spacer(),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Zaloguj się'),
              ),
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () {
                  // Destrukcja bieżącego widoku i zastąpienie go węzłem głównym
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
                child: const Text('Korzystaj jako gość'),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}