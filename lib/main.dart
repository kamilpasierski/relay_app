import 'package:flutter/material.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/features/authentication/presentation/screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RelayApp());
}

class RelayApp extends StatelessWidget {
  const RelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relay Mobile',
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(), 
      debugShowCheckedModeBanner: true,
    );
  }
}