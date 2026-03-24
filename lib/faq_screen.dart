import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({Key? key}) : super(key: key);

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
          'Help Center',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Top section (customize as needed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              SizedBox(height: 10),
              Text(
                'COMMON QUESTIONS',
                style: TextStyle(
                  color: Color(0xFF2EABFE),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'COMMON ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF091925),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'QUESTIONS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2EABFE),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Everything you need to know about NMLS licensing education.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF091925),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
            ],
          ),
          // FAQ items (updated content)
          _FaqItem(
            question: 'What is the SAFE Act and why does it require 20 hours of education?',
            answer: 'The SAFE Mortgage Licensing Act (SAFE Act) is a federal law that established minimum standards for the licensing and registration of mortgage loan originators (MLOs). It requires all new MLOs to complete at least 20 hours of NMLS-approved pre-licensing education before sitting for the NMLS exam. This includes 3 hours of federal law, 3 hours of ethics, 2 hours of non-traditional lending, and 12 elective hours.',
          ),
          _FaqItem(
            question: 'How long does it take to complete the 20-hour PE course?',
            answer: 'The 20-hour PE course is self-paced, but NMLS requires that it be completed over a minimum of 3 days (you cannot rush through it faster than real time). Most students complete it within 1–2 weeks working a few hours per day. You have 6 months from enrollment to complete the course.',
          ),
          _FaqItem(
            question: 'Are you an accredited NMLS-approved education provider?',
            answer: 'Yes. RELSTONE is a fully accredited NMLS-approved education provider. Our Provider ID is listed in the NMLS Course Catalog and all completions are reported automatically to your NMLS record. You can verify our accreditation directly on the NMLS Resource Center website.',
          ),
          _FaqItem(
            question: 'What happens after I complete the PE course?',
            answer: 'Upon successful completion of the course, you will receive a downloadable certificate of completion that you can access immediately from your student portal. Additionally, your completion is automatically reported to NMLS within 1 business day. You\'ll receive a confirmation email once your NMLS record has been updated.',
          ),
          _FaqItem(
            question: 'Do I need to complete CE every year even if I haven’t originated any loans?',
            answer: 'Yes. NMLS requires 8 hours of CE annually for all licensed MLOs, regardless of production volume. Failure to complete CE by the deadline will result in your license being placed in an "approved-inactive" status, which prevents you from originating loans until the requirement is fulfilled and your license is renewed.',
          ),
          _FaqItem(
            question: 'I already completed CE with another provider. Can I retake it with RELSTONE?',
            answer: 'No. NMLS does not allow you to repeat CE coursework that has already been reported and accepted for the current calendar year. Each of the 8 required CE hours can only be counted once per year, regardless of the provider. If you have already fulfilled your CE for the year, no additional courses are needed until the following year.',
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _expanded ? const Color(0xFFEAF6FE) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _expanded ? const Color(0xFFB6E0FE) : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: _expanded
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: _expanded ? const Color(0xFFD2EDFC) : const Color(0xFFF7FBFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (_expanded)
                        GestureDetector(
                          onTap: () => setState(() => _expanded = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFB6E0FE),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        )
                      else
                        Icon(Icons.expand_more, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7FBFF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Text(
                    widget.answer,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ],
    );
  }
}