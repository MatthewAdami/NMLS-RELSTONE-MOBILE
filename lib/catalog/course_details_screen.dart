import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import 'catalog_theme.dart';
import 'courses_catalog_controller.dart';
import 'models/course_model.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool loading = false;
  String? errorMessage;
  CourseModel? course;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch();
    });
  }

  Future<void> _fetch() async {
    final controller = context.read<CoursesCatalogController>();
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final fetched = await controller.courseRepository.fetchCourseById(
        widget.courseId,
      );
      setState(() => course = fetched);
    } on UnauthorizedException catch (_) {
      setState(() {
        errorMessage = 'Your session has expired. Please sign in again.';
      });
      controller.onUnauthorized?.call();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: kCatalogMuted,
      fontWeight: FontWeight.w600,
    );
    final descStyle = theme.textTheme.bodyMedium?.copyWith(
      color: kCatalogDark,
      height: 1.4,
    );
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      color: kCatalogDark,
      fontWeight: FontWeight.w800,
    );
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: kCatalogBlue,
      foregroundColor: kCatalogWhite,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      disabledBackgroundColor: Colors.grey.shade400,
      disabledForegroundColor: Colors.white,
    );

    return Scaffold(
      backgroundColor: kCatalogBg,
      appBar: AppBar(
        backgroundColor: kCatalogDark,
        foregroundColor: kCatalogWhite,
        title: const Text('Course Details'),
      ),
      body: Builder(
        builder: (_) {
          final controller = context.watch<CoursesCatalogController>();
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null) {
            return _ErrorView(message: errorMessage!, onRetry: _fetch);
          }

          if (course == null) {
            return const Center(child: Text('No course loaded.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                course!.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: kCatalogDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (_) {
                  final inCart = controller.isInCart(course!.id);
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: inCart
                          ? null
                          : () {
                              controller.addToCart(
                                course!,
                                persistImmediately: true,
                              );
                            },
                      style: buttonStyle,
                      child: Text(
                        inCart ? 'Added to Cart' : 'Add to Cart',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: kCatalogWhite,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text('Type: ${course!.type}', style: metaStyle),
              Text('Credit hours: ${course!.creditHours}', style: metaStyle),
              Text('Price: \$${course!.price}', style: metaStyle),
              const SizedBox(height: 8),
              Text(
                'States: ${course!.statesApproved.join(', ')}',
                style: metaStyle,
              ),
              const SizedBox(height: 12),
              Text(course!.description, style: descStyle),
              const SizedBox(height: 16),
              if (course!.modules.isNotEmpty) ...[
                Text('Modules', style: sectionTitleStyle),
                const SizedBox(height: 8),
                ...course!.modules.map((m) => _ModuleTile(module: m)),
              ],
              if (course!.finalExamQuestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Final Exam', style: sectionTitleStyle),
                const SizedBox(height: 8),
                _QuizQuestionsList(questions: course!.finalExamQuestions),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final CourseModuleModel module;

  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moduleTitleStyle = theme.textTheme.titleMedium?.copyWith(
      color: kCatalogDark,
      fontWeight: FontWeight.w700,
    );
    final moduleSubtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: kCatalogMuted,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
    final quizLabelStyle = theme.textTheme.bodySmall?.copyWith(
      color: kCatalogMuted,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );

    return ExpansionTile(
      title: Text(module.title, style: moduleTitleStyle),
      subtitle: module.description.isNotEmpty
          ? Text(module.description, style: moduleSubtitleStyle)
          : null,
      iconColor: kCatalogBlue,
      collapsedIconColor: kCatalogBlue,
      textColor: kCatalogDark,
      collapsedTextColor: kCatalogMuted,
      collapsedBackgroundColor: kCatalogWhite,
      backgroundColor: kCatalogWhite,
      children: [
        if (module.quiz.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Module Quiz', style: quizLabelStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _QuizQuestionsList(questions: module.quiz),
          ),
          const SizedBox(height: 8),
        ] else ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'No quiz for this module.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: kCatalogMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuizQuestionsList extends StatelessWidget {
  final List<QuizQuestionModel> questions;

  const _QuizQuestionsList({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...questions.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final q = entry.value;

          return _QuizQuestionCard(questionNumber: index, question: q);
        }),
      ],
    );
  }
}

class _QuizQuestionCard extends StatelessWidget {
  final int questionNumber;
  final QuizQuestionModel question;

  const _QuizQuestionCard({
    required this.questionNumber,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionStyle = theme.textTheme.bodyMedium?.copyWith(
      color: kCatalogDark,
      fontWeight: FontWeight.w800,
      height: 1.35,
    );
    final optionBaseStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.4,
      fontWeight: FontWeight.w500,
    );

    return Card(
      color: kCatalogWhite,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q$questionNumber. ${question.question}',
              style: questionStyle,
            ),
            const SizedBox(height: 8),
            ...question.options.asMap().entries.map((e) {
              final optIndex = e.key;
              final opt = e.value;
              final isCorrect = optIndex == question.correctIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${optIndex + 1}. $opt${isCorrect ? ' (Correct)' : ''}',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : kCatalogMuted,
                    fontWeight: isCorrect ? FontWeight.w800 : FontWeight.w500,
                    height: optionBaseStyle?.height,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kCatalogMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: kCatalogPrimaryButtonStyle(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
