import 'package:flutter/material.dart';

// Import theme constants from dashboard_screen.dart
const kDark        = Color(0xFF091925);
const kBlue        = Color(0xFF2EABFE);
const kBlueFaint   = Color(0x1A2EABFE);
const kBlack       = Colors.black;
const kWhite       = Colors.white;
const kMuted       = Color(0x990B1220);
const kBg          = Color(0xFF0B2A3A); // dark blue background
const kCardBg      = Color(0xFF091925); // dark blue card
const kCardBorder  = Color(0xFF2EABFE); // blue border
const kCardText    = Color(0xFF2EABFE); // lighter blue text
const kHeaderText  = Color(0xFF2EABFE); // lighter blue for header
const kHeaderDesc  = Color(0xFFB3D8FF); // even lighter blue for description
const kCardMinHeight = 140.0;
const kCardMinWidth = 380.0;

class HowItWorksScreen extends StatelessWidget {
  final List<_StepData> steps = [
    _StepData(icon: Icons.person_add_alt_1, title: 'Create account', description: 'Sign up with your details to start your NMLS journey.'),
    _StepData(icon: Icons.menu_book_outlined, title: 'Enroll in pre-licensing course', description: 'Choose and enroll in a state-approved pre-licensing course.'),
    _StepData(icon: Icons.access_time_outlined, title: 'Complete required hours', description: 'Attend and complete all required course hours.'),
    _StepData(icon: Icons.quiz_outlined, title: 'Take chapter quizzes & final exam', description: 'Pass quizzes and the final exam to demonstrate your knowledge.'),
    _StepData(icon: Icons.workspace_premium_outlined, title: 'Receive completion certificate', description: 'Get your official course completion certificate.'),
    _StepData(icon: Icons.event_available, title: 'Schedule & pass state licensing exam', description: 'Book and pass your state exam via Pearson VUE/PSI.'),
    _StepData(icon: Icons.assignment_turned_in_outlined, title: 'Apply for license', description: 'Submit your application to the state commission.'),
    _StepData(icon: Icons.refresh_outlined, title: 'Complete annual CE for renewal', description: 'Finish continuing education each year to renew your license.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text('How It Works', style: TextStyle(color: kHeaderText, fontWeight: FontWeight.w900)),
        iconTheme: const IconThemeData(color: kHeaderText),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 420,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('The Full Licensing Journey',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kHeaderText)),
                    const SizedBox(height: 8),
                    const Text(
                      'A clear 8-step path from account creation to annual renewal, presented in the same guided flow students follow in real life.',
                      style: TextStyle(fontSize: 15, color: kHeaderDesc, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              ...steps.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final step = entry.value;
                return _StepCard(idx: idx, step: step);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String description;
  const _StepData({required this.icon, required this.title, required this.description});
}

class _StepCard extends StatelessWidget {
  final int idx;
  final _StepData step;
  const _StepCard({required this.idx, required this.step});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        width: 420,
        constraints: BoxConstraints(
          minHeight: kCardMinHeight,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kCardBorder, width: 2),
          boxShadow: [BoxShadow(color: kCardBorder.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kCardBorder, width: 2),
                color: kCardBorder.withOpacity(0.18),
              ),
              width: 40,
              height: 40,
              child: Center(
                child: Text('$idx', style: const TextStyle(color: kCardText, fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 16),
            Icon(step.icon, color: kCardText, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: const TextStyle(fontWeight: FontWeight.w900, color: kCardText, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(step.description, style: const TextStyle(fontSize: 13, color: kHeaderDesc)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
