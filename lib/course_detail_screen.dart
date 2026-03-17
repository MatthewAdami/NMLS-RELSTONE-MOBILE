import 'package:flutter/material.dart';

const kDark = Color(0xFF091925);
const kBlue = Color(0xFF2EABFE);
const kBlueFaint = Color(0x1A2EABFE);
const kBlueBorder = Color(0x382EABFE);
const kTeal = Color(0xFF00B4B4);
const kTealFaint = Color(0x1A00B4B4);
const kTealBorder = Color(0x3300B4B4);
const kAmber = Color(0xFFF59E0B);
const kAmberFaint = Color(0x1AF59E0B);
const kAmberBorder = Color(0x38F59E0B);
const kBg = Color(0xFFF6F7FB);
const kWhite = Colors.white;
const kMuted = Color(0x990B1220);
const kBorder = Color(0x1A020817);

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool inCart;
  final VoidCallback onEnroll;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.inCart,
    required this.onEnroll,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<int> _expandedModules = {0};
  final Map<int, int> _helpfulVotes = {};
  late bool _enrolled;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _enrolled = widget.inCart;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CourseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inCart != widget.inCart) {
      _enrolled = widget.inCart;
    }
  }

  double _num(dynamic value) => value is num ? value.toDouble() : 0.0;

  String get _title => widget.course['title'] as String? ?? 'Untitled Course';
  String get _description => widget.course['description'] as String? ?? '';
  String get _type =>
      widget.course['catalog_type'] as String? ??
      widget.course['type'] as String? ??
      'Course';
  String get _format => widget.course['format'] as String? ?? 'Self-Paced';
  double get _price => _num(widget.course['price']);
  double get _textbookPrice => _num(widget.course['textbook_price']);
  double get _rating => _num(widget.course['rating']);
  int get _reviewCount => (widget.course['review_count'] as num?)?.toInt() ?? 0;
  double get _duration =>
      _num(widget.course['duration_hours']).clamp(1, 99).toDouble();
  double get _creditHours => _num(widget.course['credit_hours']);
  bool get _hasTextbook => widget.course['has_textbook'] == true;

  List<String> get _states =>
      (widget.course['states_approved'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  List<String> get _badges =>
      (widget.course['badges'] as List?)?.map((e) => e.toString()).toList() ??
      [];

  List<Map<String, dynamic>> get _modules {
    final raw =
        (widget.course['modules'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    if (raw.isNotEmpty) return raw;

    final totalHours =
        (_duration > 0 ? _duration : (_creditHours > 0 ? _creditHours : 8))
            .clamp(3, 24)
            .toDouble();
    final moduleCount = totalHours <= 6
        ? 3
        : totalHours <= 12
        ? 4
        : 5;
    final each = (totalHours / moduleCount).clamp(1, 5).toDouble();

    return List.generate(moduleCount, (i) {
      return {'title': 'Module ${i + 1}', 'hours': each};
    });
  }

  int get _hash => _title.codeUnits.fold(0, (sum, item) => sum + item);

  List<String> get _whatYouLearn => [
    'Understand ${_type.toLowerCase()} requirements for ${_states.isEmpty ? 'multi-state licensing' : _states.join(', ')}.',
    'Build confidence with step-by-step lessons on regulations, ethics, and practical workflow.',
    'Prepare for exam and compliance checkpoints with guided reinforcement.',
    'Track completion and next steps with a course structure designed for working professionals.',
  ];

  List<String> get _whoItIsFor => [
    'New mortgage professionals starting their licensing track.',
    'Students who want a structured, state-aware learning path.',
    'Originators who need CE or exam prep without guesswork.',
  ];

  List<String> get _included => [
    '${_modules.length} guided modules with lesson breakdowns',
    '${_duration.toStringAsFixed(_duration % 1 == 0 ? 0 : 1)} hours estimated study time',
    'Free preview on the first 2 lessons',
    if (_hasTextbook)
      'Optional textbook add-on for \$${_textbookPrice.toStringAsFixed(2)}',
    'Certificate/progress-ready curriculum structure',
  ];

  Map<String, dynamic> get _instructor {
    final index = _hash % 3;
    final explicitPhoto =
        widget.course['instructor_photo']?.toString() ??
        widget.course['instructor_image']?.toString();

    final data = [
      {
        'name': 'Alex Morgan',
        'title': 'NMLS Compliance Instructor',
        'photo':
            explicitPhoto ??
            'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=160&q=80',
        'credentials': [
          'NMLS Educator',
          'Former MLO Trainer',
          '15+ Years Industry',
        ],
        'bio':
            'Alex specializes in converting licensing requirements into practical, easy-to-finish study plans for new mortgage professionals.',
      },
      {
        'name': 'Priya Bennett',
        'title': 'SAFE Act Curriculum Lead',
        'photo':
            explicitPhoto ??
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=160&q=80',
        'credentials': [
          'SAFE Act Specialist',
          'Instructional Designer',
          'Exam Readiness Coach',
        ],
        'bio':
            'Priya builds state-aware curriculum that balances regulatory depth with high-completion learning design.',
      },
      {
        'name': 'Daniel Reyes',
        'title': 'Mortgage Education Director',
        'photo':
            explicitPhoto ??
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=160&q=80',
        'credentials': [
          'Licensed Educator',
          'Former Branch Trainer',
          'Student Success Lead',
        ],
        'bio':
            'Daniel focuses on applied examples, compliance retention, and helping students move from study hours to licensing outcomes.',
      },
    ];
    return data[index];
  }

  List<Map<String, dynamic>> get _reviews {
    final names = ['Jordan M.', 'Taylor R.', 'Chris L.', 'Morgan D.'];
    final comments = [
      'Clear breakdown and easy pacing. The module flow made the requirements feel manageable.',
      'I liked the structure and the quick previews before committing. Good for busy schedules.',
      'Helpful explanations and practical examples. I would have liked even more practice drills.',
      'Solid course with a clean flow from basics to state-specific material.',
    ];

    return List.generate(4, (index) {
      final stars = 4 + ((_hash + index) % 2);
      return {
        'name': names[index],
        'stars': stars,
        'headline': index == 0
            ? 'Exactly what I needed'
            : index == 1
            ? 'Well structured'
            : index == 2
            ? 'Useful and practical'
            : 'Strong overall experience',
        'comment': comments[index],
        'helpful': _helpfulVotes[index] ?? (7 + ((_hash + index * 3) % 24)),
      };
    });
  }

  List<double> get _starBreakdown {
    final total = _reviewCount == 0 ? 1 : _reviewCount;
    final five = (total * 0.56).clamp(1, total).toDouble();
    final four = (total * 0.24).clamp(0, total).toDouble();
    final three = (total * 0.11).clamp(0, total).toDouble();
    final two = (total * 0.06).clamp(0, total).toDouble();
    final one = (total * 0.03).clamp(0, total).toDouble();
    return [five, four, three, two, one];
  }

  List<Map<String, dynamic>> get _faqItems => [
    {
      'question': 'How long do I have access to this course?',
      'answer':
          'You can work through the material on your own schedule during the active access window associated with your enrollment.',
    },
    {
      'question': 'Does this course satisfy state approval requirements?',
      'answer': _states.isEmpty
          ? 'This course supports multi-state learners. Review your exact state rules before enrollment.'
          : 'This course is aligned for ${_states.join(', ')} approval coverage shown in the catalog.',
    },
    {
      'question': 'Is there a preview before I enroll?',
      'answer':
          'Yes. The first 2 lessons are marked as free preview inside the curriculum tab.',
    },
    {
      'question': 'What happens after I enroll?',
      'answer':
          'The course can be added to your cart now, and checkout will provision it through the existing order flow.',
    },
  ];

  List<Map<String, dynamic>> _lessonsForModule(
    Map<String, dynamic> module,
    int moduleIndex,
  ) {
    final moduleTitle = module['title']?.toString() ?? 'Module';
    final hours = _num(module['hours']);
    final baseMinutes = (hours * 60 / 3).round().clamp(12, 55);

    return [
      {
        'title': '$moduleTitle Foundations',
        'preview': moduleIndex == 0,
        'minutes': baseMinutes,
      },
      {
        'title': '$moduleTitle In Practice',
        'preview': moduleIndex == 0 || moduleIndex == 1,
        'minutes': baseMinutes + 8,
      },
      {
        'title': '$moduleTitle Knowledge Check',
        'preview': false,
        'minutes': baseMinutes - 2,
      },
    ];
  }

  void _voteHelpful(int index) {
    setState(() {
      _helpfulVotes[index] =
          (_helpfulVotes[index] ?? (7 + ((_hash + index * 3) % 24))) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final desktop = width >= 1100;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: desktop ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  void _handleEnroll() {
    if (_enrolled) return;
    widget.onEnroll();
    setState(() => _enrolled = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course added to cart.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handlePreviewLesson(String lessonTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preview unlocked: $lessonTitle'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInstructorAvatar(Map<String, dynamic> instructor) {
    final name = (instructor['name'] as String? ?? 'I').trim();
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join();

    final photoUrl = instructor['photo']?.toString() ?? '';
    final hasPhoto = photoUrl.startsWith('http');

    return CircleAvatar(
      radius: 34,
      backgroundColor: kBlueFaint,
      foregroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
      child: hasPhoto
          ? null
          : Text(
              initials,
              style: const TextStyle(
                color: kBlue,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackBar(),
                      const SizedBox(height: 14),
                      _buildHero(desktop: true),
                      const SizedBox(height: 16),
                      _buildTabsCard(desktop: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 356,
          padding: const EdgeInsets.fromLTRB(8, 82, 20, 24),
          child: _buildStickySidebar(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackBar(),
                const SizedBox(height: 12),
                _buildHero(desktop: false),
                const SizedBox(height: 14),
                _buildStickySidebar(),
                const SizedBox(height: 14),
                _buildTabsCard(desktop: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackBar() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: kBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_rounded, size: 16, color: kDark),
            SizedBox(width: 6),
            Text(
              'Back to catalog',
              style: TextStyle(fontWeight: FontWeight.w900, color: kDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero({required bool desktop}) {
    final stateLabel = _states.isEmpty ? 'Multi-State' : _states.join(', ');
    final approvalBadge = _badges.contains('State Approved')
        ? 'State Approved'
        : 'Relstone Eligible';

    return Container(
      padding: EdgeInsets.all(desktop ? 20 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2030), Color(0xFF114C7D), Color(0xFF2EABFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kDark.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroBadge(_type, Colors.white.withOpacity(0.16), Colors.white),
              _heroBadge(
                stateLabel,
                Colors.white.withOpacity(0.12),
                const Color(0xFFD7EEFF),
              ),
              _heroBadge(
                approvalBadge,
                const Color(0x1A86EFAC),
                const Color(0xFFC4FFD7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _title,
            style: TextStyle(
              color: kWhite,
              fontSize: desktop ? 30 : 24,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '\$${_price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              ElevatedButton(
                onPressed: _handleEnroll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC857),
                  foregroundColor: const Color(0xFF0B2030),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _enrolled ? 'Already Added' : 'Enroll Now',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildTabsCard({required bool desktop}) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: kDark,
              unselectedLabelColor: kMuted,
              indicator: BoxDecoration(
                color: kBlueFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBlueBorder),
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Curriculum'),
                Tab(text: 'Instructor'),
                Tab(text: 'Reviews'),
                Tab(text: 'FAQ'),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),
          SizedBox(
            height: desktop ? 980 : 1120,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCurriculumTab(),
                _buildInstructorTab(),
                _buildReviewsTab(),
                _buildFaqTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'What you learn',
            'Practical outcomes students can expect from this course.',
          ),
          const SizedBox(height: 10),
          ..._whatYouLearn.map((item) => _bulletRow(item)),
          const SizedBox(height: 18),
          _sectionHeader(
            'Who it is for',
            'Ideal learner profile for this catalog item.',
          ),
          const SizedBox(height: 10),
          ..._whoItIsFor.map(
            (item) => _bulletRow(item, icon: Icons.people_alt_outlined),
          ),
          const SizedBox(height: 18),
          _sectionHeader(
            'What is included',
            'Everything packaged with the enrollment experience.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _included
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          'Curriculum',
          'Expandable module structure, lesson list, time, and preview access.',
        ),
        const SizedBox(height: 12),
        ..._modules.asMap().entries.map((entry) {
          final index = entry.key;
          final module = entry.value;
          final lessons = _lessonsForModule(module, index);
          final expanded = _expandedModules.contains(index);
          final hours = _num(module['hours']);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (expanded) {
                          _expandedModules.remove(index);
                        } else {
                          _expandedModules.add(index);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: kBlueFaint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBlueBorder),
                            ),
                            child: Center(
                              child: Text(
                                'M${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: kDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module['title']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: kDark,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} hours • ${lessons.length} lessons',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: kMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: kMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        children: lessons.asMap().entries.map((lessonEntry) {
                          final lesson = lessonEntry.value;
                          final preview = lesson['preview'] == true;
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: preview
                                        ? kTealFaint
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: preview ? kTealBorder : kBorder,
                                    ),
                                  ),
                                  child: Icon(
                                    preview
                                        ? Icons.play_circle_outline_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 16,
                                    color: preview ? kTeal : kMuted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson['title']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: kDark,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${lesson['minutes']} min${preview ? ' • Free preview' : ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: kMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (preview)
                                  TextButton(
                                    onPressed: () => _handlePreviewLesson(
                                      lesson['title']?.toString() ?? 'Lesson',
                                    ),
                                    child: const Text('Preview'),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInstructorTab() {
    final instructor = _instructor;
    final credentials = (instructor['credentials'] as List).cast<String>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Instructor',
            'Subject-matter guidance and student-facing teaching profile.',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructorAvatar(instructor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructor['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: kDark,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instructor['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        instructor['bio'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kDark,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: credentials
                            .map(
                              (item) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: kDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                _statTile('Instructor Rating', _rating.toStringAsFixed(1)),
                const SizedBox(width: 10),
                _statTile('Students', '${_reviewCount + 120}'),
                const SizedBox(width: 10),
                _statTile('Completion Score', '${86 + (_hash % 9)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    final breakdown = _starBreakdown;
    final maxValue = breakdown.reduce((a, b) => a > b ? a : b);
    final reviews = _reviews;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Student Reviews',
            'Ratings summary, breakdown, and learner feedback.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: kDark,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _stars(_rating),
                    const SizedBox(height: 6),
                    Text(
                      '$_reviewCount ratings',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final star = 5 - index;
                      final value = breakdown[index];
                      final widthFactor = maxValue == 0
                          ? 0.0
                          : value / maxValue;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$star★',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: kDark,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 10,
                                  value: widthFactor,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        kBlue,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 34,
                              child: Text(
                                value.round().toString(),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: kMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...reviews.asMap().entries.map((entry) {
            final index = entry.key;
            final review = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: kBlueFaint,
                        child: Text(
                          (review['name'] as String).substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: kBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: kDark,
                              ),
                            ),
                            _stars(
                              (review['stars'] as num).toDouble(),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    review['headline'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: kDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review['comment'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kDark,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _voteHelpful(index),
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                    label: Text('Helpful (${review['helpful']})'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          'Course FAQ',
          'Course-specific questions before enrollment.',
        ),
        const SizedBox(height: 12),
        ..._faqItems.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                title: Text(
                  item['question'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kDark,
                  ),
                ),
                children: [
                  Text(
                    item['answer'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStickySidebar() {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Course Access',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: kDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: kDark,
              fontSize: 28,
            ),
          ),
          if (_hasTextbook)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Optional textbook + \$${_textbookPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kMuted,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleEnroll,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: kWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _enrolled ? 'Already Added to Cart' : 'Enroll Now',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sidebarBadge(
            Icons.schedule_outlined,
            '${_duration.toStringAsFixed(_duration % 1 == 0 ? 0 : 1)} hours total',
          ),
          const SizedBox(height: 8),
          _sidebarBadge(
            Icons.menu_book_outlined,
            '${_modules.length} modules included',
          ),
          const SizedBox(height: 8),
          _sidebarBadge(Icons.desktop_windows_outlined, 'Format: $_format'),
          const SizedBox(height: 8),
          _sidebarBadge(Icons.verified_user_outlined, '7-day money-back badge'),
          const SizedBox(height: 8),
          _sidebarBadge(
            Icons.card_giftcard_outlined,
            'Gift this course option',
          ),
          const SizedBox(height: 8),
          _sidebarBadge(Icons.lock_clock_outlined, 'Learn at your own pace'),
        ],
      ),
    );
  }

  Widget _sidebarBadge(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: kDark,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: kDark,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: kMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _bulletRow(
    String label, {
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kBlue),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kDark,
                height: 1.42,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: kDark,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: kMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stars(double rating, {double size = 16}) {
    final full = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < full ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: kAmber,
        ),
      ),
    );
  }
}
