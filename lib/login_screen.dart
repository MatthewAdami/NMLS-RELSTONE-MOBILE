import 'dart:convert';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'sign_up_screen.dart';

// ─── Theme Constants ─────────────────────────────────────────────────
const kRed      = Color(0xFFC0392B);
const kRedDark  = Color(0xFF922B21);
const kRedLight = Color(0xFFFDF0EF);
const kRedBorder = Color(0xFFF5C6C2);
const kDark     = Color(0xFF1A1A1A);
const kDarkBg   = Color(0xFF1A1A2E);
const kGrey     = Color(0xFF888888);
const kGreyLight = Color(0xFFF5F5F0);
const kGreyBorder = Color(0xFFE2E2E2);
const kWhite    = Colors.white;

// ─── Login Screen ─────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading  = false;
  bool _obscure    = true;
  String _error    = '';

  Future<void> _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });

    // ✅ Uses AuthService → ApiConfig.login → http://10.0.2.2:8000/api/auth/login
    final result = await AuthService.login(email, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as Map<String, dynamic>?;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(user: user),
        ),
      );
      return;
    }

    // ── Handle specific backend responses ──────────────────────────
    final message = result['message'] ?? '';

    // Email not verified → go to verify screen
    if (result['needsVerification'] == true) {
      Navigator.pushNamed(
        context,
        '/verify-email',
        arguments: {'email': email},
      );
      return;
    }

    // Account deactivated
    if (result['isInactive'] == true) {
      setState(() => _error = 'Your account has been deactivated. Please contact support.');
      return;
    }

    setState(() => _error = message.isNotEmpty ? message : 'Login failed. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreyLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kDarkBg, kRed, kRedDark],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              padding: EdgeInsets.fromLTRB(28, 56, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'NMLS Approved Education',
                      style: TextStyle(
                        color: kWhite, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900,
                        color: kWhite, height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Advance your\nMortgage Career\n'),
                        TextSpan(
                          text: 'with Confidence.',
                          style: TextStyle(color: Color(0xFFF9CA74)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'NMLS-approved pre-licensing and continuing education courses for mortgage professionals.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13, height: 1.6,
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _statItem('50+', 'States'),
                        Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15)),
                        _statItem('10k+', 'Students'),
                        Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15)),
                        _statItem('100%', 'NMLS'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Form Card ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 24, offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome Back',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kDark)),
                    SizedBox(height: 4),
                    Text('Sign in to your student account',
                        style: TextStyle(fontSize: 13, color: kGrey)),
                    SizedBox(height: 24),

                    // Error box
                    if (_error.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: kRedLight,
                          border: Border.all(color: kRedBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error, style: TextStyle(color: kRed, fontSize: 13)),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontSize: 14, color: kDark),
                      decoration: _inputDecoration('Email address', Icons.email_outlined),
                    ),
                    SizedBox(height: 14),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      style: TextStyle(fontSize: 14, color: kDark),
                      decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Color(0xFF999999), size: 18,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onSubmitted: (_) => _login(),
                    ),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text('Forgot password?',
                            style: TextStyle(color: kRed, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(height: 8),

                    // Sign In button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          disabledBackgroundColor: kRed.withOpacity(0.7),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: kWhite, strokeWidth: 2),
                              )
                            : Text('Sign In →',
                                style: TextStyle(
                                  color: kWhite, fontSize: 15,
                                  fontWeight: FontWeight.w600, letterSpacing: 0.3,
                                )),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Divider
                    Row(children: [
                      Expanded(child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
                    ]),
                    SizedBox(height: 20),

                    // Register link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14, color: kGrey),
                            children: [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Create one here',
                                style: TextStyle(color: kRed, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Center(
                      child: Text(
                        'By signing in you agree to Relstone\'s\nTerms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB), height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
      prefixIcon: Icon(icon, color: Color(0xFF999999), size: 18),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Color(0xFFFAFAFA),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kGreyBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kRed, width: 1.5),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10, letterSpacing: 0.3,
            )),
      ]),
    );
  }
}