import 'package:flutter/material.dart';

class AboutRelstonePage extends StatelessWidget {
  // Color palette based on web design
  final Color darkBlue = Color(0xFF0A1A2F);
  final Color lightBlue = Color(0xFF3B82F6);
  final Color cardBg = Colors.white;
  final Color cardAltBg = Color(0xFFF5F8FF);
  final Color textDark = Color(0xFF1A2236);
  final Color textLight = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        title: Text('About Relstone', style: TextStyle(color: cardBg)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Badge, Headline, Subheading, Feature Tags
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('NMLS-Approved Education Provider', style: TextStyle(color: cardBg, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 16),
                    // Headline
                    Text('Your Path to Mortgage Licensure', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                    SizedBox(height: 8),
                    // Subheading
                    Text('Join thousands of successful professionals who chose Relstone for their mortgage licensing education.', style: TextStyle(fontSize: 16, color: textDark)),
                    SizedBox(height: 16),
                    // Feature Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _featureTag('SAFE Act Compliant', lightBlue, cardBg),
                        _featureTag('50+ States Approved', lightBlue, cardBg),
                        _featureTag('Instant Certificates', lightBlue, cardBg),
                      ],
                    ),
                  ],
                ),
              ),
              // Platform Overview
              _sectionCard(
                cardBg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLATFORM OVERVIEW', style: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 8),
                    _platformOverviewItem(Icons.computer, 'Online Self-Study (OES)'),
                    _platformOverviewItem(Icons.devices, '24/7 — Any Device'),
                    _platformOverviewItem(Icons.school, '20-Hour SAFE Act PE Course'),
                    _platformOverviewItem(Icons.update, '8-Hour Annual CE Renewal'),
                    _platformOverviewItem(Icons.verified, 'Issued Instantly on Completion'),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Mission, Story, Team
              _sectionCard(
                cardAltBg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mission, Story, and the Team Behind ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                    RichText(
                      text: TextSpan(
                        text: 'Relstone.',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textLight),
                        children: [
                          TextSpan(
                            text: '\nRelstone was built to make mortgage licensing education more reliable, less fragmented, and more supportive for professionals balancing work and certification requirements. Our mission is simple: give learners a compliant, high-clarity path from first enrollment to long-term license renewal, with real instructional support along the way.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Stats Cards Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;
                  double cardWidth = isMobile ? double.infinity : 220;
                  double cardHeight = 180; // Set consistent height for all cards
                  return isMobile
                      ? Column(
                          children: [
                            _statsCard('50 States', 'NMLS-approved education tracks with broad state readiness and elective support where required.', cardBg, textDark, width: cardWidth, height: cardHeight),
                            SizedBox(height: 8),
                            _statsCard('94%', 'Practice quizzes, exam prep checkpoints, and progress coaching designed around outcomes.', cardBg, textDark, subtitle: 'FIRST-TRY PASS RATE', width: cardWidth, height: cardHeight),
                            SizedBox(height: 8),
                            _statsCard('24/7', 'Student help, course guidance, and technical assistance available when learners actually need it.', cardBg, textDark, subtitle: 'LEARNER SUPPORT', width: cardWidth, height: cardHeight),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _statsCard('50 States', 'NMLS-approved education tracks with broad state readiness and elective support where required.', cardBg, textDark, width: cardWidth, height: cardHeight)),
                            SizedBox(width: 8),
                            Expanded(child: _statsCard('94%', 'Practice quizzes, exam prep checkpoints, and progress coaching designed around outcomes.', cardBg, textDark, subtitle: 'FIRST-TRY PASS RATE', width: cardWidth, height: cardHeight)),
                            SizedBox(width: 8),
                            Expanded(child: _statsCard('24/7', 'Student help, course guidance, and technical assistance available when learners actually need it.', cardBg, textDark, subtitle: 'LEARNER SUPPORT', width: cardWidth, height: cardHeight)),
                          ],
                        );
                },
              ),
              SizedBox(height: 24),
              // Instructor and Leadership Team
              Text('Instructor and Leadership Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cardBg)),
              SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _teamCard('Photo', 'Mr. Adrian Zubia', 'PRESIDENT / CEO / DIRECTOR', 'Holds ultimate responsibility for the leadership and strategic direction of REL, overseeing program development, financial management, and compliance with state and federal regulations.', cardBg, textDark, isMobile),
                      _teamCard('Photo', 'Ms. Amina Ahmed', 'SCHOOL ADMINISTRATOR', 'Oversees student services, ensures smooth delivery of educational programs, and maintains compliance with accreditation standards. Manages course scheduling, student progress, and instructor leadership.', cardBg, textDark, isMobile),
                      _teamCard('Photo', 'Ms. Rosa Peralta', 'OFFICE ADMINISTRATOR', 'Manages student enrollment, student account records, and ensures all courses meet accreditation and certification standards. Facilitates communication between instructors and students.', cardBg, textDark, isMobile),
                      _teamCard('Photo', 'Mr. Dean Clayton', 'MARKETING DIRECTOR', 'Develops and implements strategic marketing initiatives to increase brand awareness, student enrollment, and digital campaigns and promotional strategies.', cardBg, textDark, isMobile),
                    ],
                  );
                },
              ),
              SizedBox(height: 24),
              // State Approvals & Accreditations
              Text('State Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
              SizedBox(height: 8),
              _sectionCard(
                cardBg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...['Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','Florida','Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland','Massachusetts','Michigan','Minnesota','Mississippi','Missouri','Montana','Nebraska','Nevada','New Hampshire','New Jersey','New Mexico','New York','North Carolina','North Dakota','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont','Virginia','Washington','West Virginia','Wisconsin','Wyoming'].map((state) => Chip(label: Text(state, style: TextStyle(color: textDark)), backgroundColor: cardAltBg)).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionCard(
                cardBg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Accreditations and Standards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                    SizedBox(height: 8),
                    ...['NMLS-approved course provider','SAFE Act aligned curriculum standards','8xSig-ID identity verification enabled','ROCS V4 rules of conduct workflow','7-day credit banking operations'].map((item) => Row(
                      children: [
                        Icon(Icons.check_circle, color: lightBlue, size: 18),
                        SizedBox(width: 6),
                        Text(item, style: TextStyle(color: textDark)),
                      ],
                    )).toList(),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Press Mentions and Awards
              Text('Press Mentions and Awards', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cardBg)),
              SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pressCard('MORTGAGE INDUSTRY TODAY', 'Top Digital Licensing Platform to Watch', '2025', darkBlue, lightBlue, cardBg, isMobile),
                      _pressCard('NATIONAL LENDING REVIEW', 'Excellence in Compliance-First Education', '2024', darkBlue, lightBlue, cardBg, isMobile),
                      _pressCard('FINED AWARDS', 'Best Learner Experience in Licensing Education', '2025', darkBlue, lightBlue, cardBg, isMobile),
                      _pressCard('BROKER PARTNER SUMMIT', 'Student Support Team of the Year', '2024', darkBlue, lightBlue, cardBg, isMobile),
                    ],
                  );
                },
              ),
              SizedBox(height: 24),
              // About the Platform
              _sectionCard(
                cardAltBg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ABOUT THE PLATFORM', style: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        text: 'NMLS-Approved Education\n',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                        children: [
                          TextSpan(
                            text: 'Built for Compliance.',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textLight),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Relstone is an NMLS-approved education provider offering fully online, self-paced mortgage licensing courses. Our platform is designed to meet every technical requirement set by the SAFE Act and NMLS — from identity authentication to time tracking and module sequencing.\n\nWhether you\'re a first-time MLO applicant completing your 20-hour pre-licensing requirement or a licensed professional renewing with your annual 8-hour CE, Relstone has the course you need — available anytime, from any device.', style: TextStyle(fontSize: 16, color: textDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(Color bg, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _platformOverviewItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: lightBlue, size: 20),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: textDark, fontSize: 16)),
        ],
      ),
    );
  }

  // Update _statsCard to accept width and height
  Widget _statsCard(String title, String desc, Color bg, Color textColor, {String? subtitle, double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          if (subtitle != null)
            Text(subtitle, style: TextStyle(fontSize: 12, color: lightBlue, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(desc, style: TextStyle(fontSize: 14, color: textColor)),
        ],
      ),
    );
  }

  Widget _teamCard(String photo, String name, String role, String desc, Color bg, Color textColor, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 220,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: darkBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(photo, style: TextStyle(color: lightBlue, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: 8),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          Text(role, style: TextStyle(color: lightBlue, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(desc, style: TextStyle(color: textColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _pressCard(String title, String desc, String year, Color bg, Color accent, Color textColor, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 220,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(desc, style: TextStyle(color: textColor)),
          SizedBox(height: 8),
          Text(year, style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _featureTag(String text, Color bg, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
