import 'package:flutter/material.dart';
import 'package:nmls_mobile/widgets/app_bottom_nav.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const kDark        = Color(0xFF091925);
const kBlue        = Color(0xFF2EABFE);
const kBlueFaint   = Color(0x1A2EABFE);
const kBlueBorder  = Color(0x382EABFE);
const kBg          = Color(0xFFF6F7FB);
const kWhite       = Colors.white;
const kMuted       = Color(0x990B1220);
const kBorder      = Color(0x1A020817);
const kSurface     = Color(0xD0FFFFFF);

class ExamPrepScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  const ExamPrepScreen({Key? key, this.userName = 'User', this.userEmail = 'user@example.com'}) : super(key: key);

  @override
  State<ExamPrepScreen> createState() => _ExamPrepScreenState();
}

class _ExamPrepScreenState extends State<ExamPrepScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTopSection(),
                    _buildBottomSection(),
                  ],
                ),
              ),
            ),
            AppBottomNav(
              activeTab: AppNavTab.examPrep,
              userName: widget.userName,
              userEmail: widget.userEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      color: kDark,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, bottom: 24, left: 16, right: 16),
      child: Column(
        children: [
          const Text(
            'Exam Prep Center',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'California Real Estate License Exam',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: const Color(0xFF7D92A3),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF102436),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 0.70,
                        strokeWidth: 6,
                        color: kBlue,
                        backgroundColor: kBlue.withValues(alpha: 0.15),
                      ),
                      Center(
                        child: Text(
                          '70%',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Readiness Score',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Good progress! Focus on Agency Law and Contracts to push above 80%.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: const Color(0xFF7D92A3),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Practice Modes
          const Text(
            'PRACTICE MODES',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Color(0xFF7D92A3),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description_outlined, color: kBlue, size: 20),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Full Exam',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '150 Q · 3 hrs',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: const Color(0xFF7D92A3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kBlue.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.access_time, color: Color(0xFF6B8397), size: 20),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Topic Drill',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: kDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'One topic',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Flashcard Tool
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.style_outlined, color: kBlue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flashcard Tool',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: kDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '248 key terms & definitions',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF6B8397)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Performance By Topic
          const Text(
            'PERFORMANCE BY TOPIC',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Color(0xFF7D92A3),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPerformanceRow('Property Ownership', 0.88, kBlue),
                const SizedBox(height: 20),
                _buildPerformanceRow('Finance & Loans', 0.74, kBlue),
                const SizedBox(height: 20),
                _buildPerformanceRow('Agency Law', 0.58, const Color(0xFFF59E0B)),
                const SizedBox(height: 20),
                _buildPerformanceRow('Contracts', 0.52, const Color(0xFFFF6B6B)),
                const SizedBox(height: 20),
                _buildPerformanceRow('Fair Housing', 0.98, kBlue),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: kDark,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

}
