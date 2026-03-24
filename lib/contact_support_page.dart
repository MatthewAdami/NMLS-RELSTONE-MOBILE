import 'package:flutter/material.dart';
import 'faq_screen.dart';

// Theme constants
const kDark = Color(0xFF091925);
const kBlue = Color(0xFF2EABFE);
const kBlueFaint = Color(0x1A2EABFE);
const kBlueBorder = Color(0x382EABFE);
const kTeal = Color(0xFF00B4B4);
const kBg = Color(0xFFF6F7FB);
const kWhite = Colors.white;
const kMuted = Color(0x990B1220);
const kBorder = Color(0x1A020817);

class ContactSupportPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  const ContactSupportPage({Key? key, required this.userName, required this.userEmail}) : super(key: key);

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  final _formKey = GlobalKey<FormState>();
  String subject = 'General Inquiry';
  String message = '';

  final List<String> subjects = [
    'General Inquiry',
    'Technical Issue',
    'Account Support',
    'Course Question',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        title: const Text('Contact Support', style: TextStyle(color: kDark, fontWeight: FontWeight.w900)),
        iconTheme: const IconThemeData(color: kDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with black background and blue title, single contact info card with border, matching bg
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
              decoration: BoxDecoration(
                color: kDark,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Support',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: kBlue,
                          letterSpacing: -0.2)),
                  const SizedBox(height: 8),
                  const Text('Need help? Our support team is here to assist you with any questions or concerns.',
                      style: TextStyle(
                          fontSize: 13,
                          color: kWhite,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  // Single contact info card with border, matching header bg
                  Container(
                    decoration: BoxDecoration(
                      color: kDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBlueBorder, width: 2),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent, color: kBlue, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('support@nmls-relstone.com', style: TextStyle(fontWeight: FontWeight.w900, color: kWhite, fontSize: 15)),
                              SizedBox(height: 4),
                              Text('+1 (800) 123-4567', style: TextStyle(fontSize: 13, color: kBlue, fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('Mon-Fri, 9am-5pm EST', style: TextStyle(fontSize: 13, color: kWhite, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Link to FAQ
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FaqScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: kBlueFaint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBlueBorder),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.help_outline, color: kBlue),
                    SizedBox(width: 8),
                    Text('Visit Help Center / FAQ', style: TextStyle(color: kBlue, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Contact form card in dark theme, matching header, with same font size for all fields
            Container(
              decoration: BoxDecoration(
                color: kDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBlueBorder, width: 2),
              ),
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: kWhite, fontSize: 15),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBlue)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBlue)),
                      ),
                      initialValue: widget.userName,
                      readOnly: true,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: kWhite, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: kWhite, fontSize: 15),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBlue)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBlue)),
                      ),
                      initialValue: widget.userEmail,
                      readOnly: true,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: kWhite, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        labelStyle: TextStyle(color: kWhite, fontSize: 15),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBlue)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBlue)),
                      ),
                      dropdownColor: kDark,
                      style: const TextStyle(color: kWhite, fontSize: 15),
                      iconEnabledColor: kBlue,
                      initialValue: subject,
                      items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: kWhite, fontSize: 15)))).toList(),
                      onChanged: (val) => setState(() => subject = val ?? subjects[0]),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        labelStyle: TextStyle(color: kWhite, fontSize: 15),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBlue)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBlue)),
                      ),
                      maxLines: 4,
                      onChanged: (val) => message = val,
                      validator: (val) => val == null || val.isEmpty ? 'Enter your message' : null,
                      style: const TextStyle(color: kWhite, fontSize: 15),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          foregroundColor: kWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message sent!')),
                            );
                          }
                        },
                        child: const Text('Send', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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
}
