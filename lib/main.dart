import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nmls_mobile/login_screen.dart';
import 'package:nmls_mobile/sign_up_screen.dart';
import 'package:nmls_mobile/verify_email_screen.dart';
import 'package:nmls_mobile/forgot_password_screen.dart';
import 'package:nmls_mobile/states_screen.dart';
import 'package:nmls_mobile/dashboard_screen.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // ← add this
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        iconTheme: const IconThemeData(color: Colors.black),
        textTheme: const TextTheme(),
      ),
      // ✅ SplashGate checks token — goes to Dashboard or Login
      home: const _SplashGate(),
      routes: {
        '/login':           (context) => LoginScreen(),
        '/signup':          (context) => const RegisterScreen(),
        '/verify-email':    (context) => const VerifyEmailScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/states':          (context) => const StatesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final user = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => DashboardScreen(user: user),
          );
        }
        return null;
      },
    );
  }
}

// ── Splash Gate ────────────────────────────────────────────────────
// Checks SharedPreferences on startup:
// - Has token → go to Dashboard (auto-login)
// - No token  → go to Login
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userStr = prefs.getString('user');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Has token → restore user and go to Dashboard
      Map<String, dynamic>? user;
      if (userStr != null) {
        try {
          user = jsonDecode(userStr) as Map<String, dynamic>;
        } catch (_) {}
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(user: user),
        ),
      );
    } else {
      // No token → go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen while checking
    return const Scaffold(
      backgroundColor: Color(0xFF091925),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NMLS',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                fontSize: 36,
                color: Color(0xFF2EABFE),
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Mortgage Licensing Education',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Color(0xFF2EABFE),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}