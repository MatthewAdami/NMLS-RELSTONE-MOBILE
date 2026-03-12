import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── Theme Constants ─────────────────────────────────────────────────
const kNavy = Color(0xFF091925);
const kNavyDark = Color(0xFF1A1A2E);
const kRedLight = Color(0xFFFDF0EF);
const kRedBorder = Color(0xFFF5C6C2);
const kDark = Color(0xFF1A1A1A);
const kGrey = Color(0xFF888888);
const kGreyLight = Color(0xFFF5F5F0);
const kGreyBorder = Color(0xFFE2E2E2);
const kWhite = Colors.white;
const kGold = Color(0xFFF9CA74);

const List<String> kUsStates = [
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
  'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
  'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
  'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
  'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nmlsController = TextEditingController();
  String _selectedState = '';
  bool _isLoading = false;
  String _error = '';

  Future<void> _register() async {
    setState(() { _isLoading = true; _error = ''; });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'nmls_id': _nmlsController.text,
          'state': _selectedState,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
      } else {
        final data = json.decode(response.body);
        setState(() { _error = data['message'] ?? 'Registration failed.'; });
      }
    } catch (e) {
      setState(() { _error = 'Connection failed. Please try again.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreyLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGradientHeader(),
            _buildFormCard(),
          ],
        ),
      ),
    );
  }

  // ── Gradient Header ───────────────────────────────────────────────
  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kNavyDark, kNavy, kNavy],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Text(
              'Start Your Journey Today',
              style: TextStyle(
                color: kWhite,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Headline
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: kWhite,
                height: 1.2,
              ),
              children: [
                TextSpan(text: 'Get NMLS\nLicensed &\n'),
                TextSpan(
                  text: 'Stay Compliant.',
                  style: TextStyle(color: kGold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Join thousands of mortgage professionals who trust Relstone for their NMLS pre-licensing and continuing education needs.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Feature list
          ...[
            '20-hour SAFE Act PE courses available',
            'Annual CE requirements by state',
            'Track your transcript & CE status anytime',
            'NMLS-compliant certificates on completion',
          ].map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.6), width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: kWhite,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _statItem('50+', 'States Approved'),
                Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15)),
                _statItem('10k+', 'Students Certified'),
                Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15)),
                _statItem('100%', 'NMLS Approved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: kWhite, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 9,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ── Form Card ─────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: kDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Start your NMLS education journey',
              style: TextStyle(fontSize: 13, color: kGrey),
            ),
            const SizedBox(height: 24),

            // Error box
            if (_error.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kRedLight,
                  border: Border.all(color: kRedBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error,
                    style: const TextStyle(color: kNavy, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            // Full Name
            _buildField(
              controller: _nameController,
              placeholder: 'Full name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            // Email
            _buildField(
              controller: _emailController,
              placeholder: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // Password
            _buildField(
              controller: _passwordController,
              placeholder: 'Create a password',
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 14),

            // NMLS ID + State row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _nmlsController,
                    placeholder: 'NMLS ID (optional)',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStateDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  disabledBackgroundColor: kNavy.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: kWhite, strokeWidth: 2),
                      )
                    : const Text(
                        'Create Account →',
                        style: TextStyle(
                            color: kWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Or divider
            Row(
              children: [
                const Expanded(
                    child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 12)),
                ),
                const Expanded(
                    child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
              ],
            ),
            const SizedBox(height: 20),

            // Sign in link
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, color: kGrey),
                    children: [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign in here',
                        style: TextStyle(
                            color: kNavy, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            const Center(
              child: Text(
                'By creating an account you agree to Relstone\'s\nTerms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBBBBBB),
                    height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Text Field ────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: kDark),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGreyBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kNavy, width: 1.5),
        ),
      ),
    );
  }

  // ── State Dropdown ────────────────────────────────────────────────
  Widget _buildStateDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGreyBorder, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              color: Color(0xFF999999), size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedState.isEmpty ? null : _selectedState,
                hint: const Text(
                  'State',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF999999), size: 18),
                style: const TextStyle(fontSize: 13, color: kDark),
                items: kUsStates
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedState = val ?? ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}