import 'package:flutter/material.dart';

class MyCertificatesScreen extends StatelessWidget {
  final String? userName;
  final String? userEmail;

  const MyCertificatesScreen({
    super.key,
    this.userName,
    this.userEmail,
  });

  String get _displayUserName {
    final rawName = (userName ?? '').trim();
    return rawName.isEmpty ? 'Name not set' : rawName;
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2F5F8);
    const navy = Color(0xFF061E2F);
    const cardNavy = Color(0xFF102D42);
    const blue = Color(0xFF33A9F4);
    const muted = Color(0xFF7D92A3);
    const border = Color(0xFFD8E2EC);

    final allCertificates = [
      {'title': 'Real Estate Principles', 'meta': '45 hrs · Mar 2025'},
      {'title': 'CE: Fair Housing', 'meta': '2 hrs · Jan 2026'},
      {'title': 'CE: Ethics & Conduct', 'meta': '3 hrs · Nov 2025'},
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: navy,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'My Certificates',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '12 certificates earned',
                    style: TextStyle(
                      color: Color(0xFF7D92A3),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                            decoration: const BoxDecoration(
                              color: cardNavy,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'CERTIFICATE OF COMPLETION',
                                        style: TextStyle(
                                          color: Color(0xFF67859E),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: blue.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'CA Approved',
                                        style: TextStyle(
                                          color: blue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Real Estate Finance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_displayUserName · 45 hrs · Jan 15, 2026',
                                  style: const TextStyle(
                                    color: Color(0xFF9AB0C1),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.stars_rounded, color: blue, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'RelStone Verified · #CA-45-2892',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.72),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'Download PDF',
                                    icon: Icons.download_rounded,
                                    blue: blue,
                                    filled: false,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'LinkedIn',
                                    icon: Icons.badge_rounded,
                                    blue: blue,
                                    filled: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ALL CERTIFICATES',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: List.generate(allCertificates.length, (index) {
                          final item = allCertificates[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: index == allCertificates.length - 1
                                  ? null
                                  : const Border(bottom: BorderSide(color: Color(0xFFE8EEF4))),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF8EE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title']!,
                                        style: const TextStyle(
                                          color: Color(0xFF1D2A36),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        item['meta']!,
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: blue),
                                  ),
                                  child: const Text(
                                    'View',
                                    style: TextStyle(
                                      color: blue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F2FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFB7D9F3)),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Submitting to State Commission',
                            style: TextStyle(
                              color: Color(0xFF2A3B4B),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Download your certificate and submit via the DRE eLicensing portal. Completion is also auto-reported to the state within 5 business days.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6D8294),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color blue;
  final bool filled;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.blue,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: filled ? blue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: filled ? Colors.white : blue,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : blue,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
