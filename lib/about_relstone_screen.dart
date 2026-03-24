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
              // Redesigned Top Section: Badge, Headline, Subheading, Feature Tags
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkBlue, Colors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                ),
                padding: EdgeInsets.all(28),
                margin: EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lightBlue, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        'NMLS-Approved Education Provider',
                        style: TextStyle(
                          color: lightBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Headline
                    Text(
                      'Your Path to Mortgage Licensure.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cardBg,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    // Subheading
                    Text(
                      'Relstone delivers NMLS-Approved pre-licensing and continuing education courses built for mortgage professionals. Study at your own pace, stay compliant, and earn your certificates.',
                      style: TextStyle(
                        fontSize: 18,
                        color: lightBlue,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 20),
                    // Feature Tags
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _featureTag('SAFE Act Compliant', Colors.transparent, lightBlue, borderColor: lightBlue),
                        _featureTag('50+ States Approved', Colors.transparent, lightBlue, borderColor: lightBlue),
                        _featureTag('Instant Certificates', Colors.transparent, lightBlue, borderColor: lightBlue),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Platform Overview (now inside the main card, under Instant Certificates)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lightBlue, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      padding: EdgeInsets.all(20),
                      constraints: BoxConstraints(
                        minWidth: 0,
                        maxWidth: 400,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('PLATFORM OVERVIEW', style: TextStyle(color: lightBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 12),
                          ...[
                            _platformOverviewRowFixed(Icons.computer, 'Online Self-Study (OES)', cardBg),
                            _platformOverviewRowFixed(Icons.devices, '24/7 — Any Device', cardBg),
                            _platformOverviewRowFixed(Icons.school, '20-Hour SAFE Act PE Course', cardBg),
                            _platformOverviewRowFixed(Icons.update, '8-Hour Annual CE Renewal', cardBg),
                            _platformOverviewRowFixed(Icons.verified, 'Issued Instantly on Completion', cardBg),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Mission, Story, Team
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                margin: EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Text('ABOUT RELSTONE', style: TextStyle(
                      color: lightBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    )),
                    SizedBox(height: 18),
                    // Headline
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Mission, Story, and the Team Behind ',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Relstone.',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: lightBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Description
                    Text(
                      'Relstone was built to make mortgage licensing education more reliable, less fragmented, and more supportive for professionals balancing work and certification requirements.',
                      style: TextStyle(
                        fontSize: 18,
                        color: textDark,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Our mission is simple: give learners a compliant, high-clarity path from first enrollment to long-term license renewal, with real instructional support along the way.',
                      style: TextStyle(
                        fontSize: 18,
                        color: textDark,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 32),
                    // Stats Cards inside Mission Card
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;
                        double cardWidth = isMobile ? double.infinity : 320;
                        Widget statsCard(String title, String subtitle, String desc, {double? width}) {
                          return Container(
                            width: width,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: lightBlue, width: 1),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                            ),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                                Text(subtitle, style: TextStyle(fontSize: 13, color: lightBlue, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                SizedBox(height: 8),
                                Text(desc, style: TextStyle(fontSize: 14, color: textDark), softWrap: true),
                              ],
                            ),
                          );
                        }
                        if (isMobile) {
                          return Column(
                            children: [
                              statsCard('50 States', 'COVERAGE', 'NMLS-approved education tracks with broad state readiness and elective support where required.', width: cardWidth),
                              SizedBox(height: 12),
                              statsCard('94%', 'FIRST-TRY PASS RATE', 'Practice quizzes, exam prep checkpoints, and progress coaching designed around outcomes.', width: cardWidth),
                              SizedBox(height: 12),
                              statsCard('24/7', 'LEARNER SUPPORT', 'Student help, course guidance, and technical assistance available when learners actually need it.', width: cardWidth),
                            ],
                          );
                        } else {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                statsCard('50 States', 'COVERAGE', 'NMLS-approved education tracks with broad state readiness and elective support where required.', width: cardWidth),
                                SizedBox(width: 12),
                                statsCard('94%', 'FIRST-TRY PASS RATE', 'Practice quizzes, exam prep checkpoints, and progress coaching designed around outcomes.', width: cardWidth),
                                SizedBox(width: 12),
                                statsCard('24/7', 'LEARNER SUPPORT', 'Student help, course guidance, and technical assistance available when learners actually need it.', width: cardWidth),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Instructor and Leadership Team
              Text('Instructor and Leadership Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cardBg)),
              SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;
                  final team = [
                    {
                      'photo': 'Photo',
                      'name': 'Mr. Adrian Zubia',
                      'role': 'PRESIDENT / CEO / DIRECTOR',
                      'desc': 'Holds ultimate responsibility for the leadership and strategic direction of REL, overseeing program development, financial management, and compliance with state and federal regulations.'
                    },
                    {
                      'photo': 'Photo',
                      'name': 'Ms. Amina Ahmed',
                      'role': 'SCHOOL ADMINISTRATOR',
                      'desc': 'Oversees student services, ensures smooth delivery of educational programs, and maintains compliance with accreditation standards. Manages course scheduling, student progress, and instructor leadership.'
                    },
                    {
                      'photo': 'Photo',
                      'name': 'Ms. Rosa Peralta',
                      'role': 'OFFICE ADMINISTRATOR',
                      'desc': 'Manages student enrollment, student account records, and ensures all courses meet accreditation and certification standards. Facilitates communication between instructors and students.'
                    },
                    {
                      'photo': 'Photo',
                      'name': 'Mr. Dean Clayton',
                      'role': 'MARKETING DIRECTOR',
                      'desc': 'Develops and implements strategic marketing initiatives to increase brand awareness, student enrollment, and digital campaigns and promotional strategies.'
                    },
                  ];
                  List<Widget> teamCards = team.map((member) => _teamCard(
                    member['photo']!,
                    member['name']!,
                    member['role']!,
                    member['desc']!,
                    cardBg,
                    textDark,
                    isMobile,
                    null,
                    null
                  )).toList();
                  if (isMobile) {
                    return Column(
                      children: teamCards.map((card) => Padding(padding: EdgeInsets.only(bottom: 8), child: card)).toList(),
                    );
                  } else {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: teamCards.map((card) => Container(
                          width: 320,
                          constraints: BoxConstraints(maxWidth: 320),
                          child: card,
                        )).toList(),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 24),
              // State Approvals & Accreditations
              _sectionCard(
                cardBg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // State Approvals Title inside the card
                    Text('State Approvals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...['Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','Florida','Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland','Massachusetts','Michigan','Minnesota','Mississippi','Missouri','Montana','Nebraska','Nevada','New Hampshire','New Jersey','New Mexico','New York','North Carolina','North Dakota','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont','Virginia','Washington','West Virginia','Wisconsin','Wyoming'].map((state) => Container(
                          margin: EdgeInsets.only(bottom: 4),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cardAltBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: lightBlue, width: 1),
                          ),
                          child: Text(state, style: TextStyle(color: textDark)),
                        )).toList(),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Accreditations and Standards Card inside State Approvals Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardAltBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(top: 8),
                      // Remove any fixed height, let content determine height
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Accreditations and Standards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                          SizedBox(height: 8),
                          ...['NMLS-approved course provider','SAFE Act aligned curriculum standards','8xSig-ID identity verification enabled','ROCS V4 rules of conduct workflow','7-day credit banking operations'].map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle, color: lightBlue, size: 18),
                                SizedBox(width: 6),
                                Expanded(child: Text(item, style: TextStyle(color: textDark))),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
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
              Container(
                decoration: BoxDecoration(
                  color: cardBg, // Solid white background
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ABOUT THE PLATFORM', style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2)),
                    SizedBox(height: 18),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'NMLS-Approved Education\n',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkBlue, letterSpacing: 0.5),
                          ),
                          TextSpan(
                            text: 'Built for Compliance.',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: lightBlue, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    // Justified text for description
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Relstone is an NMLS-approved education provider offering fully online, self-paced mortgage licensing courses. Our platform is designed to meet every technical requirement set by the SAFE Act and NMLS — from identity authentication to time tracking and module sequencing.',
                        style: TextStyle(fontSize: 14, color: darkBlue, height: 1.5, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Whether you\'re a first-time MLO applicant completing your 20-hour pre-licensing requirement or a licensed professional renewing with your annual 8-hour CE, Relstone has the course you need — available anytime, from any device.',
                        style: TextStyle(fontSize: 14, color: darkBlue, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                    ),
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

  Widget _platformOverviewItem(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: lightBlue, size: 20), // Icon is now blue
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: cardBg, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _platformOverviewRow(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: lightBlue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: cardBg, fontSize: 15),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper below _platformOverviewRow
  Widget _platformOverviewRowFixed(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: lightBlue, size: 20),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: cardBg, fontSize: 14),
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

  Widget _teamCard(String photo, String name, String role, String desc, Color bg, Color textColor, bool isMobile, double? height, double? width) {
    return Container(
      margin: EdgeInsets.only(right: isMobile ? 0 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBlue, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: 120,
            decoration: BoxDecoration(
              color: darkBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(photo, style: TextStyle(color: lightBlue, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: cardBg)),
                Text(role, style: TextStyle(color: lightBlue, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(color: cardBg, fontSize: 13),
                  softWrap: true,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pressCard(String title, String desc, String year, Color bg, Color accent, Color textColor, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBlue, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title in blue
          Text(title, style: TextStyle(color: lightBlue, fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 8),
          // Description in white
          Text(desc, style: TextStyle(color: cardBg, fontSize: 15)),
          SizedBox(height: 8),
          // Year with blue border
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(32), // More rounded
              border: Border.all(color: lightBlue, width: 2),
            ),
            child: Text(year, style: TextStyle(color: lightBlue, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _featureTag(String text, Color bg, Color textColor, {Color? borderColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? bg),
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

