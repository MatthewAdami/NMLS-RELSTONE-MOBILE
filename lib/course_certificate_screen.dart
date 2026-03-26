import 'package:flutter/material.dart';

import 'my_certificates_screen.dart';

class CourseCertificateScreen extends StatelessWidget {
  final String certCourseId;

  const CourseCertificateScreen({
    super.key,
    required this.certCourseId,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2F5F8);
    const navy = Color(0xFF061E2F);
    const kBlue = Color(0xFF33A9F4);
    const muted = Color(0xFF7D92A3);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Certificate',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Certificate available',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: navy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'For course `$certCourseId`.',
                style: const TextStyle(color: muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EEF4)),
                ),
                child: Text(
                  'Open `My Certificates` to view and download your completion certificate.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyCertificatesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Open My Certificates',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Note: Certificate delivery may take a short time to appear.',
                style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

