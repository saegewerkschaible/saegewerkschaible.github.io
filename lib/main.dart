import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart'; // <-- Hinzufügen!
import 'core/theme/theme_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/home/start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // <-- Hinzufügen!
    );
    debugPrint('✅ Firebase initialisiert');
  } catch (e) {
    debugPrint('❌ Firebase Fehler: $e');
  }

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final isLoggedIn = AuthService().currentUser != null;

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: SchaibleApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class SchaibleApp extends StatelessWidget {
  final bool isLoggedIn;

  const SchaibleApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Schaible Sägewerk',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      initialRoute: isLoggedIn ? StartScreen.id : LoginScreen.id,
      routes: {
        LoginScreen.id: (context) => const LoginScreen(),
        RegistrationScreen.id: (context) => const RegistrationScreen(),
        StartScreen.id: (context) => const StartScreen(),
      },
    );
  }
}