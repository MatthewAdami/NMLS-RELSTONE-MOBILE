import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // ── Brand colors (matching LoginScreen) ───────────────────
  static const Color primaryNavy = Color(0xFF1A3A5C);
  static const Color accentBlue = Color(0xFF2E7EBE);
  static const Color borderGray = Color(0xFFDDE2EA);
  static const Color textDark = Color(0xFF1C2B3A);
  static const Color textMuted = Color(0xFF6B7E92);
  static const Color errorRed = Color(0xFFE05252);
  static const Color successGreen = Color(0xFF2E9E6B);

  // ── API ────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // ── Step control (0 = email, 1 = code+password, 2 = success) ──
  int _step = 0;

  // ── Form keys ─────────────────────────────────────────────
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();


  // ── State ─────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isResending = false;
  bool _obscurePassword = true;

  String? _errorMessage;
  String? _successMessage;
  String? _userId;

  // ── Animation ─────────────────────────────────────────────
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ── Step 1: Request reset code ─────────────────────────────
  Future<void> _handleRequestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _userId = data['userId']?.toString();
          _step = 1;
          _errorMessage = null;
        });
        // Re-run animation for step 2
        _animController.reset();
        _animController.forward();
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to send reset code.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Cannot connect to server. Check your connection.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Step 2: Submit new password + code ────────────────────
  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId,
          'code': _codeController.text.trim(),
          'newPassword': _passwordController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _step = 2);
        _animController.reset();
        _animController.forward();
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to reset password.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Cannot connect to server. Check your connection.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Resend code ───────────────────────────────────────────
  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _userId}),
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _successMessage = 'A new code has been sent to your email.');
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Failed to resend code.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Cannot connect to server.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEF2F7),
              Color(0xFFF8FAFC),
              Color(0xFFE8EEF5),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── CARD ──────────────────────────────────
                    Container(
                      width: 420,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryNavy.withOpacity(0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: primaryNavy.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Top accent bar ──
                          Container(
                            height: 5,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              gradient: LinearGradient(
                                colors: [primaryNavy, accentBlue],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(40, 36, 40, 44),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: _step == 0
                                  ? _buildEmailStep()
                                  : _step == 1
                                      ? _buildResetStep()
                                      : _buildSuccessStep(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── FOOTER ──
                    const Text(
                      '© 2026 Relstone Real Estate License Services',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8FA3B8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── STEP 0: Email entry ────────────────────────────────────
  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('step_email'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          _buildIconBadge(Icons.lock_reset_rounded),
          const SizedBox(height: 24),

          const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your email and we\'ll send you a reset code',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textMuted),
          ),

          const SizedBox(height: 28),

          // Error banner
          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 16),
          ],

          _buildLabel('Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRequestCode(),
            style: const TextStyle(fontSize: 14, color: textDark),
            decoration: _inputDecoration(
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
            ),
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
            },
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Enter a valid email (e.g. name@example.com)';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          // Send Code button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRequestCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryNavy.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'Send Reset Code',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Back to login
          _buildBackToLogin(context),
        ],
      ),
    );
  }

  // ── STEP 1: Code + new password ────────────────────────────
  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('step_reset'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          _buildIconBadge(Icons.verified_user_outlined),
          const SizedBox(height: 24),

          const Text(
            'Check Your Email',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: textMuted),
              children: [
                const TextSpan(text: 'We sent a code to '),
                TextSpan(
                  text: _emailController.text.trim(),
                  style: const TextStyle(
                      color: accentBlue, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Error banner
          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 16),
          ],

          // Success banner (resend success)
          if (_successMessage != null) ...[
            _buildSuccessBanner(_successMessage!),
            const SizedBox(height: 16),
          ],

          // ── Verification code ──
          _buildLabel('Verification Code'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textDark,
              letterSpacing: 6,
            ),
            textAlign: TextAlign.center,
            decoration: _inputDecoration(
              hint: '000000',
              icon: Icons.tag_rounded,
            ).copyWith(
              hintStyle: const TextStyle(
                  color: Color(0xFFB0BCC9),
                  fontSize: 22,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w700),
              prefixIcon: null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
              if (_successMessage != null) setState(() => _successMessage = null);
            },
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter the code';
              if (value.length < 4) return 'Enter the full verification code';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // ── New password ──
          _buildLabel('New Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            style: const TextStyle(fontSize: 14, color: textDark),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: textMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
            },
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a new password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),

          const SizedBox(height: 28),

          // Reset Password button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryNavy.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'Reset Password',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Resend + back row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back to email step
              TextButton.icon(
                onPressed: () => setState(() {
                  _step = 0;
                  _errorMessage = null;
                  _successMessage = null;
                  _codeController.clear();
                  _passwordController.clear();
                }),
                icon: const Icon(Icons.arrow_back_rounded,
                    size: 15, color: textMuted),
                label: const Text('Change email',
                    style: TextStyle(fontSize: 13, color: textMuted)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),

              // Resend code
              _isResending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: accentBlue),
                    )
                  : TextButton(
                      onPressed: _resendCode,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text(
                        'Resend code',
                        style: TextStyle(
                            fontSize: 13,
                            color: accentBlue,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 2: Success ────────────────────────────────────────
  Widget _buildSuccessStep() {
    return Column(
      key: const ValueKey('step_success'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Success badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: successGreen.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: successGreen.withOpacity(0.3), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: successGreen, size: 36),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Password Reset!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your password has been successfully updated.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: textMuted, height: 1.5),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Widget _buildIconBadge(IconData icon) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F9),
        shape: BoxShape.circle,
        border: Border.all(color: borderGray, width: 1.5),
      ),
      child: Center(child: Icon(icon, color: primaryNavy, size: 28)),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 13,
                  color: errorRed,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: successGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: successGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 13,
                  color: successGreen,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLogin(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Remember your password? ',
            style: TextStyle(fontSize: 13, color: textMuted)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Sign in',
            style: TextStyle(
                fontSize: 13,
                color: accentBlue,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BCC9), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF8FA3B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
    );
  }
}