// verify_email_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';
import 'services/api_client.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;

  // Relstone brand colors
  static const Color primaryNavy = Color(0xFF1A3A5C);
  static const Color accentBlue = Color(0xFF2E7EBE);
  static const Color borderGray = Color(0xFFDDE2EA);
  static const Color textDark = Color(0xFF1C2B3A);
  static const Color textMuted = Color(0xFF6B7E92);

  // Passed via Navigator arguments
  String? _userId;
  String? _email;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Expecting:
    // Navigator.pushNamed(context, '/verify-email', arguments: {'userId': ..., 'email': ...})
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _userId ??= args['userId']?.toString();
      _email ??= args['email']?.toString();
    }
  }

  // ✅ Backend endpoints based on your auth.js
  String get _verifyUrl => "${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/auth/verify";
  String get _resendUrl =>
      "${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/auth/resend-code";

  Future<void> _verifyCode() async {
    if (_userId == null || _userId!.isEmpty) {
      _toast("Missing userId. Please sign up again.");
      return;
    }

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _isLoading = true);

    final result = await ApiClient.post(
      _verifyUrl,
      body: {
        'userId': _userId,
        'code': _codeController.text.trim(),
      },
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final status = result['statusCode'] as int;
    final data = result['data'] as Map<String, dynamic>;

    if (status == 200) {
      // ✅ Save token + user (your verify route returns token + user)
      final token = data['token'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString('token', token.toString());
      if (user != null) await prefs.setString('user', user.toString());

      _toast(data['message']?.toString() ?? "Email verified!");

      // ✅ Go to your Home route (you said you use /homescreen)
      Navigator.pushNamedAndRemoveUntil(context, '/homescreen', (_) => false);
      return;
    }

    // Show backend message (Invalid code / expired / user not found / etc.)
    _toast(data['message']?.toString() ?? "Verification failed.");
  }

  Future<void> _resendCode() async {
    if (_userId == null || _userId!.isEmpty) {
      _toast("Missing userId. Please sign up again.");
      return;
    }

    setState(() => _isResending = true);

    final result = await ApiClient.post(
      _resendUrl,
      body: {'userId': _userId},
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    final data = result['data'] as Map<String, dynamic>;
    _toast(data['message']?.toString() ?? "New code sent.");
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Verify Email",
          style: TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: primaryNavy),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 460,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryNavy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: primaryNavy,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Check your email",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _email == null || _email!.isEmpty
                        ? "Enter the 6-digit code we sent to your email."
                        : "Enter the 6-digit code we sent to\n$_email",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),

                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 18,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w800,
                        color: primaryNavy,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "123456",
                        hintStyle: const TextStyle(
                          color: Color(0xFFB0BCC9),
                          letterSpacing: 6,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
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
                          borderSide:
                              const BorderSide(color: accentBlue, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: Color(0xFF8FA3B8)),
                      ),
                      validator: (v) {
                        final value = (v ?? "").trim();
                        if (value.isEmpty) return "Please enter the code";
                        if (value.length != 6) return "Code must be 6 digits";
                        if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                          return "Code must be numbers only";
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Verify",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _isResending ? null : _resendCode,
                    child: _isResending
                        ? const Text(
                            "Resending...",
                            style: TextStyle(
                              color: accentBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : const Text(
                            "Resend code",
                            style: TextStyle(
                              color: accentBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Back",
                      style: TextStyle(
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}