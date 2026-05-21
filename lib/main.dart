import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:relay_app/core/theme/app_theme.dart';
import 'package:relay_app/core/services/auth_service.dart';
import 'package:relay_app/features/authentication/presentation/screens/welcome_screen.dart';
import 'package:relay_app/features/home/presentation/screens/home_screen.dart';
import 'package:relay_app/features/account/presentation/screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AppTheme.initTheme();

  final authService = AuthService();
  final String? token = await authService.getToken();

  final Widget initialScreen = (token != null)
      ? const HomeScreen()
      : const WelcomeScreen();

  runApp(RelayApp(startScreen: initialScreen));
}

class RelayApp extends StatelessWidget {
  final Widget startScreen;

  const RelayApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'Relay Mobile',
          debugShowCheckedModeBanner: true,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,

          home: startScreen,
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/home': (context) => const HomeScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
          },
        );
      },
    );
  }
}
