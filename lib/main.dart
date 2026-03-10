import 'package:flutter/material.dart';
import 'package:nmls_mobile/login_screen.dart';
import 'package:nmls_mobile/sign_up_screen.dart';
import 'package:nmls_mobile/verify_email_screen.dart';
import 'package:nmls_mobile/forgot_password_screen.dart';
import 'package:nmls_mobile/states_screen.dart';
import 'package:nmls_mobile/dashboard_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login':           (context) => LoginScreen(),
        '/signup':          (context) => const RegisterScreen(),
        '/verify-email':    (context) => const VerifyEmailScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/states':          (context) => const StatesScreen(),
        '/dashboard': (context) {
          final user = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return DashboardScreen(user: user);
        },
      },
    );
  }
}