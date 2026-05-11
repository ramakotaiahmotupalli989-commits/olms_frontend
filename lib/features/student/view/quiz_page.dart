/// EduCinema LMS — Quiz Page (Student)
/// MCQ quiz with timer, immediate feedback, score card.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_repository.dart';

class QuizPage extends StatefulWidget {
  final int quizId;
  const QuizPage({super.key, required this.quizId});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _repo = ApiRepository();
  Map<String, dynamic>? _quiz;
  List<int> _answers = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _submitted = false;
  Map<String, dynamic>? _result;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() { super.initState(); _loadQuiz(); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _loadQuiz() async {
    try {
      final data = await _repo.get('/student/quiz/${widget.quizId}');
      final questions = (data['questions'] as List?) ?? [];
      setState(() {
        _quiz = data;
        _answers = List.filled(questions.length, -1);
        _loading = false;
      });
      _startTimer();
    } catch (e) { setState(() => _loading = false); }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsElapsed++);
    });
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    try {
      final result = await _repo.post('/student/quiz/${widget.quizId}/submit', data: {
        'answers': _answers,
        'time_taken_secs': _secondsElapsed,
      });
      setState(() { _result = result; _submitted = true; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit quiz')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_submitted && _result != null) return _buildScoreCard();
    return _buildQuizView();
  }

  Widget _buildQuizView() {
    final questions = (_quiz?['questions'] as List?) ?? [];
    if (questions.isEmpty) return const Scaffold(body: Center(child: Text('No questions')));
    final q = questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${questions.length}'),
        actions: [
          Center(child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(_formatTime(_secondsElapsed), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ]),
          )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Progress indicators
          Row(children: List.generate(questions.length, (i) => Expanded(
                child: Container(
                  height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _answers[i] >= 0 ? AppColors.primary : i == _currentIndex ? AppColors.primary.withValues(alpha: 0.4) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ))),
          const SizedBox(height: 24),
          // Question
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q['question'] ?? '', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)),
            const SizedBox(height: 24),
            // Options
            ...(q['options'] as List? ?? []).asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              final selected = _answers[_currentIndex] == i;
              return GestureDetector(
                onTap: () => setState(() => _answers[_currentIndex] = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade200, width: selected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade400),
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : Center(
                        child: Text(String.fromCharCode(65 + i), style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(opt.toString(), style: GoogleFonts.inter(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
                  ]),
                ),
              );
            }),
          ]))),
          // Navigation buttons
          Row(children: [
            if (_currentIndex > 0)
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _currentIndex--),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Previous'),
              )),
            if (_currentIndex > 0) const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _currentIndex < questions.length - 1
                  ? () => setState(() => _currentIndex++)
                  : _answers.contains(-1) ? null : _submitQuiz,
              child: Text(_currentIndex < questions.length - 1 ? 'Next' : 'Submit'),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = _result?['score'] ?? 0;
    final total = _result?['total_marks'] ?? 0;
    final pct = _result?['percentage'] ?? 0;
    final correct = _result?['correct_count'] ?? 0;
    final totalQ = _result?['total_questions'] ?? 0;
    final passed = (pct as num) >= 50;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Emoji + Score
          Text(passed ? '\u{1F389}' : '\u{1F4AA}', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(passed ? 'Well Done!' : 'Keep Trying!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(passed ? 'Great performance on this quiz' : 'Review the explanations and try again', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          // Score circle
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: passed ? [AppColors.success, const Color(0xFF43E97B)] : [AppColors.warning, AppColors.secondary],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: (passed ? AppColors.success : AppColors.warning).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$score/$total', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('$pct%', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildStatBox('\u{2705}', '$correct', 'Correct'),
            const SizedBox(width: 20),
            _buildStatBox('\u{274C}', '${totalQ - correct}', 'Wrong'),
            const SizedBox(width: 20),
            _buildStatBox('\u{23F1}', _formatTime(_secondsElapsed), 'Time'),
          ]),
          const SizedBox(height: 32),
          // Results list
          if ((_result?['results'] as List?) != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text('Question Review', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...(_result!['results'] as List).map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (r['is_correct'] ?? false) ? AppColors.success.withValues(alpha: 0.05) : AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ((r['is_correct'] ?? false) ? AppColors.success : AppColors.error).withValues(alpha: 0.2)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon((r['is_correct'] ?? false) ? Icons.check_circle : Icons.cancel, color: (r['is_correct'] ?? false) ? AppColors.success : AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r['question'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500))),
                    ]),
                    if (!(r['is_correct'] ?? false) && r['explanation'] != null && r['explanation'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r['explanation'], style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
                        ]),
                      ),
                    ],
                  ]),
                )),
          ],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Chapters'),
          )),
        ]),
      )),
    );
  }

  Widget _buildStatBox(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
