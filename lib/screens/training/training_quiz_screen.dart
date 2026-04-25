import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/training_service.dart';

class TrainingQuizScreen extends StatefulWidget {
  final String role;

  const TrainingQuizScreen({super.key, required this.role});

  @override
  State<TrainingQuizScreen> createState() => _TrainingQuizScreenState();
}

enum _Stage { loading, quiz, submitting, result }

class _TrainingQuizScreenState extends State<TrainingQuizScreen> {
  _Stage _stage = _Stage.loading;
  String? _errorMessage;

  List<TrainingQuestion> _questions = [];
  final Map<int, String> _answers = {};
  int _currentIndex = 0;

  TrainingResult? _result;

  Color get _themeColor =>
      widget.role == 'rider' ? AppColors.accent : AppColors.primary;

  String get _homeRoute =>
      widget.role == 'rider' ? '/rider/home' : '/shopper/home';

  String get _quizTitle => widget.role == 'rider'
      ? 'Safe rides, happy customers'
      : 'Picking the best, talking the best';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _stage = _Stage.loading;
      _errorMessage = null;
    });
    try {
      final questions = await TrainingService.fetchQuestions(widget.role);
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() {
          _errorMessage = 'No questions found. Please contact support.';
        });
        return;
      }
      setState(() {
        _questions = questions;
        _answers.clear();
        _currentIndex = 0;
        _stage = _Stage.quiz;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load the quiz. Please check your internet and try again.';
      });
    }
  }

  void _selectOption(String option) {
    final question = _questions[_currentIndex];
    setState(() {
      _answers[question.id] = option;
    });

    if (_currentIndex < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _currentIndex += 1);
      });
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _stage = _Stage.submitting);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Not signed in');

      final result = await TrainingService.submitAttempt(
        role: widget.role,
        answers: _answers,
        token: token,
      );

      if (!mounted) return;

      if (result.passed) {
        await context.read<AuthProvider>().refreshProfile();
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        _stage = _Stage.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not submit your answers. Please try again.';
        _stage = _Stage.quiz;
      });
    }
  }

  void _retake() {
    setState(() {
      _answers.clear();
      _currentIndex = 0;
      _result = null;
      _errorMessage = null;
      _stage = _Stage.quiz;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && _stage == _Stage.loading) {
      return _buildErrorView();
    }
    switch (_stage) {
      case _Stage.loading:
        return const Center(child: CircularProgressIndicator());
      case _Stage.submitting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _themeColor),
              const SizedBox(height: 16),
              Text('Checking your answers...', style: AppTextStyles.bodyMedium),
            ],
          ),
        );
      case _Stage.quiz:
        return _buildQuizView();
      case _Stage.result:
        return _buildResultView();
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    final question = _questions[_currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(_quizTitle,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        _ProgressDots(
          total: _questions.length,
          current: _currentIndex,
          color: _themeColor,
        ),
        const SizedBox(height: 32),
        Text(
          'Question ${_currentIndex + 1} of ${_questions.length}',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Text(question.prompt, style: AppTextStyles.h2),
        const SizedBox(height: 32),
        _OptionButton(
          label: 'A. ${question.optionA}',
          color: _themeColor,
          onTap: () => _selectOption('a'),
        ),
        const SizedBox(height: 12),
        _OptionButton(
          label: 'B. ${question.optionB}',
          color: _themeColor,
          onTap: () => _selectOption('b'),
        ),
        const SizedBox(height: 12),
        _OptionButton(
          label: 'C. ${question.optionC}',
          color: _themeColor,
          onTap: () => _selectOption('c'),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(_errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.red.shade700),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    final passed = result.passed;
    final headlineColor = passed ? Colors.green : Colors.orange.shade700;
    final headlineIcon =
        passed ? Icons.check_circle_rounded : Icons.refresh_rounded;
    final headline = passed
        ? 'You passed!'
        : 'Almost there — try again';
    final subline = passed
        ? 'You got ${result.score} out of ${result.total}. Welcome to the team!'
        : 'You got ${result.score} out of ${result.total}. You need ${result.passMark} to pass — you got this!';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(child: Icon(headlineIcon, size: 72, color: headlineColor)),
          const SizedBox(height: 16),
          Text(headline, style: AppTextStyles.h1, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subline,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.grey.shade700, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (!passed) ...[
            Text('Review your answers',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ..._buildFeedbackCards(),
            const SizedBox(height: 24),
          ],
          ElevatedButton.icon(
            onPressed: passed ? () => context.go(_homeRoute) : _retake,
            icon: Icon(
                passed ? Icons.arrow_forward_rounded : Icons.refresh_rounded),
            label: Text(passed ? 'Continue' : 'Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildFeedbackCards() {
    final feedback = _result!.feedback;
    return [
      for (var i = 0; i < feedback.length; i++)
        _FeedbackCard(
          index: i,
          question: _questions.firstWhere(
            (q) => q.id == feedback[i].questionId,
            orElse: () => _questions[i.clamp(0, _questions.length - 1)],
          ),
          feedback: feedback[i],
        ),
    ];
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;
  final Color color;

  const _ProgressDots({
    required this.total,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i <= current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 28,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final int index;
  final TrainingQuestion question;
  final TrainingFeedback feedback;

  const _FeedbackCard({
    required this.index,
    required this.question,
    required this.feedback,
  });

  String _optionText(String key) {
    switch (key) {
      case 'a':
        return question.optionA;
      case 'b':
        return question.optionB;
      case 'c':
        return question.optionC;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = feedback.correct;
    final accent = isCorrect ? Colors.green : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(question.prompt, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          if (!isCorrect)
            Text(
              'Correct answer: ${feedback.correctOption.toUpperCase()}. ${_optionText(feedback.correctOption)}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade800),
            ),
          if (feedback.explanation != null && feedback.explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              feedback.explanation!,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
