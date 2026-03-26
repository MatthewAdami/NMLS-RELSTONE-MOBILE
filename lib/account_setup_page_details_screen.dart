import 'package:flutter/material.dart';

class AccountSetupPageDetailsScreen extends StatelessWidget {
  const AccountSetupPageDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Account Setup Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: const AccountSetupPageDetailsGuide(),
    );
  }
}

class AccountSetupPageDetailsGuide extends StatelessWidget {
  const AccountSetupPageDetailsGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _Heading(text: 'Account Setup page'),
        const _BodyText(
          text:
              'Route: `client/src/pages/auth_page/AccountSetupStep.jsx` (/account-setup)',
        ),
        const SizedBox(height: 16),
        _ExpSection(
          title: 'Fields shown / validated in the UI',
          children: const [
            _BodyText(
              text:
                  'Required for Save & Go to Portal:\n- `firstName`\n- `lastName`\n- `email` (validated, but not sent to the server in this page\'s save call)\n- `street`\n- `city`\n- `addrState` (UI label: "License State")\n- `zip`\n- `mobile` (used as "phone")\n',
            ),
            SizedBox(height: 12),
            _BodyText(
              text:
                  'Optional (collected in UI, but not saved by this page):\n- `company`\n- `work`\n- `home`\n\nOptional fields that affect saving:\n- `nmlsId` ("NMLS ID (if you have one)")\n- `password` (if provided, triggers password change)',
            ),
          ],
        ),
        _ExpSection(
          title: 'What it sends to the backend when saving',
          children: const [
            _BodyText(
              text:
                  'When you click Save, it calls:\n'
                  '1) `PUT /api/auth/profile`\n'
                  '   - `name`: built from `firstName + lastName`\n'
                  '   - `phone`: from `mobile`\n'
                  '   - `address`: single formatted string: `street, city, state zip`\n'
                  '   - `nmls_id`: from `nmlsId` (or `null`)\n'
                  '   - `state`: from `licenseState` (or `null`)\n',
            ),
            SizedBox(height: 12),
            _BodyText(
              text: 'Example payload shape (conceptual):',
            ),
            _CodeBlock(
              code:
                  '{\n'
                  '  name: "First Last",\n'
                  '  phone: mobile || null,\n'
                  '  address: "123 Main St, City, ST ZIP",\n'
                  '  nmls_id: nmlsId || null,\n'
                  '  state: licenseState || null\n'
                  '}',
            ),
          ],
        ),
        _ExpSection(
          title: 'Optional: change password (bcrypt currentPassword check)',
          children: const [
            _BodyText(
              text:
                  'If `password` is filled, it also calls `PUT /api/auth/change-password` with:\n'
                  '- `currentPassword: "__setup__"`\n'
                  '- `newPassword: password`\n\n'
                  'IMPORTANT: server verifies `currentPassword` using bcrypt, so this succeeds only if the user\'s existing password really matches `"__setup__"`.',
            ),
          ],
        ),
        _ExpSection(
          title: 'Client save logic (reference)',
          children: const [
            _CodeBlock(
              code:
                  'const handleSave = async () => {\n'
                  '  if (!validate()) return;\n'
                  '  setSaving(true); setError("");\n'
                  '  try {\n'
                  '    const fullName = `\${firstName.trim()} \${lastName.trim()}`.trim();\n'
                  '    const address  = [street, city, `\${addrState} \${zip}`].filter(Boolean).join(", ");\n'
                  '    await API.put("/auth/profile", {\n'
                  '      name: fullName,\n'
                  '      phone: mobile || null,\n'
                  '      address: address || null,\n'
                  '      nmls_id: nmlsId || null,\n'
                  '      state: licenseState || null,\n'
                  '    });\n'
                  '    if (password) {\n'
                  '      await API.put("/auth/change-password", {\n'
                  '        currentPassword: "__setup__",\n'
                  '        newPassword: password,\n'
                  '      });\n'
                  '    }\n'
                  '    ...\n'
                  '  } catch (e) {\n'
                  '    ...\n'
                  '  }\n'
                  '};',
            ),
          ],
        ),
        _ExpSection(
          title: 'How it stores / updates in the database',
          children: const [
            _BodyText(
              text:
                  'Mongo/Mongoose model (`server/models/User.js`) defines the relevant fields updated by this page:\n'
                  '- `name`\n'
                  '- `phone`\n'
                  '- `address`\n'
                  '- `nmls_id`\n'
                  '- `state`\n\n'
                  'It also defines (but AccountSetupStep does not send):\n'
                  '- `license_type`, `target_state`, `target_date`, `experience`\n'
                  '- `notification_prefs` (email/sms booleans)',
            ),
            SizedBox(height: 12),
            _Subheading(text: 'Schema fields (reference)'),
            _CodeBlock(
              code:
                  "const userSchema = new mongoose.Schema({\n"
                  "  name:       { type: String, required: true, trim: true },\n"
                  "  email:      { type: String, required: true, unique: true, lowercase: true, trim: true },\n"
                  "  password:   { type: String, required: true },\n"
                  "  ...\n"
                  "  nmls_id:  { type: String, trim: true, default: null },\n"
                  "  state:    { type: String, default: null },\n"
                  "  phone:    { type: String, trim: true, default: null },\n"
                  "  address:  { type: String, trim: true, default: null },\n"
                  "  ...\n"
                  "  license_type:  { type: String, default: null },\n"
                  "  target_state:  { type: String, default: null },\n"
                  "  target_date:   { type: String, default: null },\n"
                  "  experience:    { type: String, default: null },\n"
                  "  notification_prefs: {\n"
                  "    email_course_updates: { type: Boolean, default: true  },\n"
                  "    email_promotions:     { type: Boolean, default: false },\n"
                  "    ...\n"
                  "  },\n"
                  "});",
            ),
          ],
        ),
        _ExpSection(
          title: 'Server route doing the update (reference)',
          children: const [
            _BodyText(
              text:
                  'PUT `/api/auth/profile` is implemented in `server/routes/auth.js`.\n\n'
                  '- Requires a valid JWT (`authMiddleware`) and uses `req.user.id`\n'
                  '- Updates user via `User.findByIdAndUpdate(req.user.id, update, { new: true })`\n'
                  '- Because the update logic checks `field !== undefined`, passing `null` from the frontend sets the DB field to `null`.',
            ),
            SizedBox(height: 12),
            _Subheading(text: 'Server update logic (reference)'),
            _CodeBlock(
              code:
                  "router.put('/profile', authMiddleware, async (req, res) => {\n"
                  "  try {\n"
                  "    const {\n"
                  "      name, phone, address, nmls_id, state,\n"
                  "      license_type, target_state, target_date, experience,\n"
                  "    } = req.body;\n"
                  "    const updated = await User.findByIdAndUpdate(\n"
                  "      req.user.id,\n"
                  "      {\n"
                  "        ...(name         && { name }),\n"
                  "        ...(phone        !== undefined && { phone }),\n"
                  "        ...(address      !== undefined && { address }),\n"
                  "        ...(nmls_id      !== undefined && { nmls_id }),\n"
                  "        ...(state        !== undefined && { state }),\n"
                  "        ...(license_type !== undefined && { license_type }),\n"
                  "        ...(target_state !== undefined && { target_state }),\n"
                  "        ...(target_date  !== undefined && { target_date }),\n"
                  "        ...(experience   !== undefined && { experience }),\n"
                  "      },\n"
                  "      { new: true }\n"
                  "    ).select('-password -otp -otpExpires');\n"
                  "    ...\n"
                  "  } catch (e) {\n"
                  "    ...\n"
                  "  }\n"
                  "});",
            ),
          ],
        ),
        _ExpSection(
          title: '"License goals & notifications" note',
          children: const [
            _BodyText(
              text:
                  'The text in `Layout.jsx` mentions those, but they are not saved by `AccountSetupStep.jsx`.\n\n'
                  'Those are handled on the Profile/Settings page `client/src/pages/profile/Profile.jsx`:\n'
                  '- License goals saved via `PUT /auth/profile` (sends `license_type`, `target_state`, `target_date`, `experience`)\n'
                  '- Notification preferences saved via `PUT /auth/notifications` (writes to `User.notification_prefs`)',
            ),
            SizedBox(height: 6),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/account-setup');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF091925),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Complete Account Setup',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ExpSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ExpSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFB6E0FE), width: 1.2),
      ),
      child: ExpansionTile(
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        tilePadding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2EABFE),
          ),
        ),
        children: children,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Color(0xFF091925),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _Subheading extends StatelessWidget {
  final String text;
  const _Subheading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Color(0xFF2EABFE),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF091925),
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB6E0FE), width: 1.2),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF091925),
          fontFamily: 'JetBrains Mono',
          height: 1.45,
        ),
      ),
    );
  }
}

