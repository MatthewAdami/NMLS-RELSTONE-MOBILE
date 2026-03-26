import 'package:flutter/material.dart';

import 'services/auth_service.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  static const Color _borderColor = Color(0xFFE6EEF6);
  static const Color _focusedBorderColor = Color(0xFF2EABFE);
  static const double _cornerRadius = 12.0;

  // Contact info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  // Optional company + phone fields
  final _companyController = TextEditingController();
  final _workPhoneController = TextEditingController();
  final _homePhoneController = TextEditingController();

  // Mailing address + required phone
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _mobilePhoneController = TextEditingController();

  // Optional
  final _nmlsIdController = TextEditingController();

  // License state
  String _licenseState = '';

  // Mailing address state (always required)
  String _mailingState = '';

  // Area of study (UI only; Account Setup page does not save this).
  String _areaOfStudy = 'Mortgage / NMLS';

  // Password (optional; if provided triggers password change)
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _saving = false;
  String _error = '';

  static const List<String> _usStateAbbr = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final email = args['email']?.toString();
      if (email != null && email.isNotEmpty && _emailController.text.isEmpty) {
        _emailController.text = email;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _workPhoneController.dispose();
    _homePhoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _mobilePhoneController.dispose();
    _nmlsIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, {String? fieldName}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '${fieldName ?? 'This field'} is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? value, {bool required = true}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return required ? 'Phone is required' : null;

    // Accept "(xxx) xxx-xxxx" or "xxxxxxxxxx"
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return 'Enter a 10-digit phone number';
    return null;
  }

  String? _validateZip(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'ZIP is required';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 5) return 'Enter a valid ZIP code';
    return null;
  }

  String? _validateOptionalPassword(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: _focusedBorderColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cornerRadius),
        borderSide: const BorderSide(color: _borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cornerRadius),
        borderSide: const BorderSide(color: _borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cornerRadius),
        borderSide: const BorderSide(color: _focusedBorderColor, width: 1.7),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) {
        setState(() => _saving = false);
        return;
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();

      final street = _streetController.text.trim();
      final city = _cityController.text.trim();
      final zip = _zipController.text.trim();
      final mailingState = _mailingState.trim();

      final addressParts = <String>[
        if (street.isNotEmpty) street,
        if (city.isNotEmpty) city,
        if (mailingState.isNotEmpty || zip.isNotEmpty) '$mailingState $zip'.trim(),
      ];
      final address = addressParts.where((e) => e.isNotEmpty).join(', ');

      final mobile = _mobilePhoneController.text.trim();
      final nmlsId = _nmlsIdController.text.trim();

      final bool isMortgageNmls = _areaOfStudy == 'Mortgage / NMLS';
      final state = isMortgageNmls && _licenseState.isNotEmpty ? _licenseState.trim() : null;
      final nmlsValue = isMortgageNmls && nmlsId.isNotEmpty ? nmlsId : null;
      final phoneValue = mobile.isNotEmpty ? mobile : null;
      final addressValue = address.isNotEmpty ? address : null;

      final profileRes = await AuthService.updateProfile(
        name: fullName,
        phone: phoneValue,
        address: addressValue,
        nmlsId: nmlsValue,
        state: state,
      );

      if (!mounted) return;

      if (!profileRes['success'] as bool) {
        setState(() {
          _error = profileRes['message']?.toString() ?? 'Profile save failed';
          _saving = false;
        });
        return;
      }

      final password = _passwordController.text.trim();
      if (password.isNotEmpty) {
        final passRes = await AuthService.changePassword(newPassword: password);
        if (!mounted) return;
        if (!passRes['success'] as bool) {
          setState(() {
            _error = passRes['message']?.toString() ?? 'Password change failed';
            _saving = false;
          });
          return;
        }
      }

      final token = await AuthService.getToken();
      if (!mounted) return;

      // "Go to Portal" -> Dashboard in this app.
      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
        arguments: {
          'token': token,
          'name': fullName,
          'email': _emailController.text.trim(),
          'nmls_id': nmlsValue,
          'state': state,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: const Text(
          'Account Setup',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _SectionCard(
                  icon: Icons.person,
                  title: 'Contact Information',
                  description: 'Your personal and contact details.',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: _fieldDecoration(
                                labelText: 'First Name',
                                icon: Icons.person_outline,
                              ),
                              validator: (v) =>
                                  _validateRequired(v, fieldName: 'First Name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: _fieldDecoration(
                                labelText: 'Last Name',
                                icon: Icons.person_outline,
                              ),
                              validator: (v) =>
                                  _validateRequired(v, fieldName: 'Last Name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        decoration: _fieldDecoration(
                          labelText: 'Email Address',
                          icon: Icons.email_outlined,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _companyController,
                        decoration: _fieldDecoration(
                          labelText: 'Company / Brokerage Name (optional)',
                          icon: Icons.business_outlined,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Mailing Address',
                  description: 'Used for certificate and document delivery.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _streetController,
                        decoration: _fieldDecoration(
                          labelText: 'Street Address',
                          icon: Icons.home_outlined,
                        ),
                        validator: (v) => _validateRequired(v, fieldName: 'Street Address'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: _fieldDecoration(
                                labelText: 'City',
                                icon: Icons.location_city_outlined,
                              ),
                              validator: (v) => _validateRequired(v, fieldName: 'City'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _mailingState.isEmpty ? null : _mailingState,
                              decoration: _fieldDecoration(
                                labelText: 'State',
                                icon: Icons.map_outlined,
                              ),
                              items: _usStateAbbr
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _mailingState = v ?? ''),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'State is required';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _zipController,
                        decoration: _fieldDecoration(
                          labelText: 'ZIP Code',
                          icon: Icons.pin_drop_outlined,
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validateZip,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  icon: Icons.phone_android_outlined,
                  title: 'Phone Numbers',
                  description: 'At least one phone number is required.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _mobilePhoneController,
                        decoration: _fieldDecoration(
                          labelText: 'Mobile Phone',
                          icon: Icons.phone_outlined,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => _validatePhone(v, required: true),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _workPhoneController,
                              decoration: _fieldDecoration(
                                labelText: 'Work Phone (optional)',
                                icon: Icons.work_outline,
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) => _validatePhone(v, required: false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _homePhoneController,
                              decoration: _fieldDecoration(
                                labelText: 'Home Phone (optional)',
                                icon: Icons.home_outlined,
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) => _validatePhone(v, required: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Please provide at least one phone number for account verification and support contact.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6B5B00)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  icon: Icons.badge_outlined,
                  title: 'Area of Study',
                  description: 'Select your primary course area (UI only in this step).',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _StudyChoice(
                            label: 'Mortgage / NMLS',
                            selected: _areaOfStudy == 'Mortgage / NMLS',
                            icon: Icons.account_balance_outlined,
                            onTap: () => setState(() => _areaOfStudy = 'Mortgage / NMLS'),
                          ),
                          _StudyChoice(
                            label: 'Real Estate',
                            selected: _areaOfStudy == 'Real Estate',
                            icon: Icons.location_city_outlined,
                            onTap: () => setState(() {
                              _areaOfStudy = 'Real Estate';
                              _licenseState = '';
                              _nmlsIdController.clear();
                            }),
                          ),
                          _StudyChoice(
                            label: 'Insurance CE',
                            selected: _areaOfStudy == 'Insurance CE',
                            icon: Icons.school_outlined,
                            onTap: () => setState(() {
                              _areaOfStudy = 'Insurance CE';
                              _licenseState = '';
                              _nmlsIdController.clear();
                            }),
                          ),
                          _StudyChoice(
                            label: 'CFP / Financial',
                            selected: _areaOfStudy == 'CFP / Financial',
                            icon: Icons.account_balance_wallet_outlined,
                            onTap: () => setState(() {
                              _areaOfStudy = 'CFP / Financial';
                              _licenseState = '';
                              _nmlsIdController.clear();
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_areaOfStudy == 'Mortgage / NMLS')
                        TextFormField(
                          controller: _nmlsIdController,
                          decoration: _fieldDecoration(
                            labelText: 'NMLS ID (if you have one)',
                            icon: Icons.tag_outlined,
                          ),
                        ),
                      if (_areaOfStudy == 'Mortgage / NMLS') ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _licenseState.isEmpty ? null : _licenseState,
                          decoration: _fieldDecoration(
                            labelText: 'License State',
                            icon: Icons.map_outlined,
                          ),
                          items: _usStateAbbr
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _licenseState = v ?? ''),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'License State is required';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Set Your Password',
                  description: 'Secure your student portal account (optional in this step).',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _passwordController,
                        decoration: _fieldDecoration(
                          labelText: 'Password',
                          icon: Icons.lock_outline_rounded,
                        ),
                        obscureText: true,
                        validator: _validateOptionalPassword,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: _fieldDecoration(
                          labelText: 'Confirm Password',
                          icon: Icons.lock_outline_rounded,
                        ),
                        obscureText: true,
                        validator: (v) {
                          final password = _passwordController.text.trim();
                          if (password.isEmpty) return null; // optional step
                          final confirm = (v ?? '').trim();
                          if (confirm.isEmpty) return 'Please confirm your password';
                          if (confirm != password) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Use at least 8 characters with a mix of letters, numbers, and symbols.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7E92), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      border: Border.all(color: const Color(0xFFFFC2C2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF091925),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save & Go to Portal',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE6EEF6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFE1FF)),
                  ),
                  child: Icon(icon, size: 22, color: const Color(0xFF2EABFE)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF091925),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7E92)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StudyChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _StudyChoice({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2EABFE) : const Color(0xFFE6EEF6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: selected ? const Color(0xFF2EABFE) : const Color(0xFF6B7E92)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: selected ? const Color(0xFF091925) : const Color(0xFF6B7E92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

