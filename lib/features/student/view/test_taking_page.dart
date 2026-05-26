/// EduCinema LMS — Test Taking Page
/// Scheduled exam session taking UI with countdown timer, progression layout, and result scorecard.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_repository.dart';
import 'package:go_router/go_router.dart';

class TestTakingPage extends StatefulWidget {
  final int sessionId;
  const TestTakingPage({super.key, required this.sessionId});

  @override
  State<TestTakingPage> createState() => _TestTakingPageState();
}

class _TestTakingPageState extends State<TestTakingPage> {
  final _repo = ApiRepository();
  Map<String, dynamic>? _sessionData;
  List<int> _answers = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _submitted = false;
  Map<String, dynamic>? _result;
  
  int _secondsRemaining = 0;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTest() async {
    try {
      final data = await _repo.get('/student/test-sessions/${widget.sessionId}');
      final questions = (data['questions'] as List?) ?? [];
      
      // Calculate remaining time based on due_at
      final dueTime = DateTime.parse(data['due_at']);
      final diff = dueTime.difference(DateTime.now());
      
      setState(() {
        _sessionData = data;
        _answers = List.filled(questions.length, -1);
        _secondsRemaining = diff.inSeconds > 0 ? diff.inSeconds : 0;
        _loading = false;
      });

      if (_secondsRemaining > 0) {
        _startTimer();
      } else {
        _autoSubmit();
      }
    } catch (e) {
      debugPrint('[TestTaking] Load test error: $e');
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _autoSubmit();
        }
      });
    });
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    
    // Check if there are unanswered questions
    if (_answers.contains(-1)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unanswered Questions'),
          content: Text('You have left ${ _answers.where((a) => a == -1).length } questions blank. Are you sure you want to submit?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      );
      if (confirm != true) {
        _startTimer();
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final res = await _repo.post('/student/test-sessions/${widget.sessionId}/submit', data: {
        'answers': _answers,
        'time_taken_secs': _secondsElapsed,
      });
      setState(() {
        _result = res;
        _submitted = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit test: $e'), backgroundColor: AppColors.error));
        _startTimer();
      }
    }
  }

  Future<void> _autoSubmit() async {
    if (_submitted) return;
    _timer?.cancel();
    setState(() => _loading = true);
    
    // Fill remaining questions with -1
    for (int i = 0; i < _answers.length; i++) {
      if (_answers[i] == -1) _answers[i] = -1;
    }
    
    try {
      final res = await _repo.post('/student/test-sessions/${widget.sessionId}/submit', data: {
        'answers': _answers,
        'time_taken_secs': _secondsElapsed,
      });
      setState(() {
        _result = res;
        _submitted = true;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time\'s up! Your test has been submitted automatically.'), backgroundColor: AppColors.warning));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_submitted && _result != null) return _buildScoreCard();
    return _buildQuizView();
  }

  Widget _buildQuizView() {
    final questions = (_sessionData?['questions'] as List?) ?? [];
    if (questions.isEmpty) return const Scaffold(body: Center(child: Text('No questions found')));
    final q = questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${questions.length}'),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _secondsRemaining < 60 ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 16, color: _secondsRemaining < 60 ? AppColors.error : AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _secondsRemaining < 60 ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress Bar indicators
            Row(
              children: List.generate(questions.length, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _answers[i] >= 0
                          ? AppColors.primary
                          : i == _currentIndex
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            
            // Question text and choices scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['question_text'] ?? '',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 24),
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
                            border: Border.all(
                              color: selected ? AppColors.primary : Colors.grey.shade200,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade400),
                                ),
                                child: selected
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : Center(
                                        child: Text(
                                          String.fromCharCode(65 + i),
                                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  opt.toString(),
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Bottom navigation buttons
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentIndex < questions.length - 1
                        ? () => setState(() => _currentIndex++)
                        : _submitTest,
                    child: Text(_currentIndex < questions.length - 1 ? 'Next' : 'Submit Test'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = _result?['score'] ?? 0.0;
    final total = _result?['total_marks'] ?? 0.0;
    final pct = _result?['percentage'] ?? 0.0;
    final correct = _result?['correct_count'] ?? 0;
    final totalQ = _result?['total_questions'] ?? 0;
    final passed = (pct as num) >= 50;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(passed ? '\u{1F389}' : '\u{1F4AA}', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(passed ? 'Test Submitted!' : 'Submission Complete!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Your test response has been recorded successfully.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              
              // Score indicator circle
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: passed ? [AppColors.success, const Color(0xFF43E97B)] : [AppColors.warning, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (passed ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${score.toInt()}/${total.toInt()}',
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      '${pct.toInt()}%',
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Stat boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatBox('\u{2705}', '$correct', 'Correct'),
                  const SizedBox(width: 24),
                  _buildStatBox('\u{274C}', '${totalQ - correct}', 'Wrong'),
                  const SizedBox(width: 24),
                  _buildStatBox('\u{23F1}', _formatTime(_secondsElapsed), 'Time Taken'),
                ],
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to Tests'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
