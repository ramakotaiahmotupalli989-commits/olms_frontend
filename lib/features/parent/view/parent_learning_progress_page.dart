/// EduCinema LMS — Parent Learning Progress Page
/// View child's quiz history, video progress by subject, and score trends.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ParentLearningProgressPage extends StatefulWidget {
  const ParentLearningProgressPage({super.key});
  @override
  State<ParentLearningProgressPage> createState() => _ParentLearningProgressPageState();
}

class _ParentLearningProgressPageState extends State<ParentLearningProgressPage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  List<dynamic> _children = [];
  int? _selectedChildId;
  List<dynamic> _quizHistory = [];
  List<dynamic> _videoProgress = [];
  bool _loading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadChildren();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    try {
      final data = await _repo.get('/parent/dashboard');
      final children = (data['children'] as List?) ?? [];
      final child = data['child'] as Map<String, dynamic>?;

      setState(() {
        _children = children;
        _selectedChildId = child?['id'] as int?;
      });

      if (_selectedChildId != null) {
        await _loadProgress(_selectedChildId!);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProgress(int childId) async {
    setState(() => _loading = true);
    try {
      final quizzes = await _repo.getList('/parent/child/$childId/quiz-history');
      final videos = await _repo.getList('/parent/child/$childId/video-progress');

      setState(() {
        _quizHistory = quizzes;
        _videoProgress = videos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _switchChild(int childId) async {
    setState(() => _selectedChildId = childId);
    await _loadProgress(childId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadProgress(_selectedChildId ?? 0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
                        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
                      ),
                      child: FadeTransition(
                        opacity: _animController,
                        child: Text(
                          'Learning Progress',
                          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Child switcher
                    if (_children.length > 1) ...[
                      _buildChildSwitcher(),
                      const SizedBox(height: 20),
                    ],

                    // Quiz stats summary
                    if (_quizHistory.isNotEmpty) ...[
                      _buildQuizSummary(),
                      const SizedBox(height: 24),
                    ],

                    // Subject-wise video progress
                    if (_videoProgress.isNotEmpty) ...[
                      const SectionHeader(title: 'Subject Progress'),
                      ..._videoProgress.map((s) => _buildSubjectProgress(s)),
                      const SizedBox(height: 24),
                    ],

                    // Quiz history
                    const SectionHeader(title: 'Quiz History'),
                    if (_quizHistory.isEmpty)
                      const EmptyState(
                        icon: Icons.quiz_rounded,
                        title: 'No Quiz Attempts Yet',
                        subtitle: 'Quiz scores will appear here once your child takes a quiz.',
                      )
                    else
                      ..._quizHistory.take(20).map((q) => _buildQuizRecord(q)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChildSwitcher() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _children.length,
        itemBuilder: (_, i) {
          final c = _children[i];
          final selected = c['id'] == _selectedChildId;
          return GestureDetector(
            onTap: () => _switchChild(c['id']),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)])
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: selected ? null : Border.all(color: Colors.grey.shade200),
                boxShadow: selected
                    ? [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Text(
                c['name'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizSummary() {
    int totalQuizzes = _quizHistory.length;
    double avgScore = 0;
    int perfectScores = 0;

    for (final q in _quizHistory) {
      final pct = (q['percentage'] ?? 0).toDouble();
      avgScore += pct;
      if (pct >= 100) perfectScores++;
    }
    avgScore = totalQuizzes > 0 ? avgScore / totalQuizzes : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quiz Performance', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _quizSummaryStat('Total Quizzes', totalQuizzes.toString())),
              Expanded(child: _quizSummaryStat('Avg Score', '${avgScore.toStringAsFixed(1)}%')),
              Expanded(child: _quizSummaryStat('Perfect', '$perfectScores')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quizSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
      ],
    );
  }

  Widget _buildSubjectProgress(dynamic subject) {
    final name = subject['subject'] ?? '';
    final totalVids = subject['total_videos'] ?? 0;
    final completedVids = subject['completed_videos'] ?? 0;
    final pct = (subject['completion_percent'] ?? 0).toDouble();
    final watchMins = (subject['total_watch_minutes'] ?? 0).toDouble();
    final chapters = (subject['chapters'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${pct.toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: pct >= 70 ? AppColors.success : pct >= 40 ? AppColors.warning : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(
                pct >= 70 ? AppColors.success : pct >= 40 ? AppColors.warning : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$completedVids/$totalVids videos',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${watchMins.toStringAsFixed(0)} min watched',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          // Chapters breakdown
          if (chapters.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...chapters.map((ch) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        (ch['completion_percent'] ?? 0) >= 100
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 14,
                        color: (ch['completion_percent'] ?? 0) >= 100 ? AppColors.success : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ch['chapter'] ?? '',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${ch['completed_videos'] ?? 0}/${ch['total_videos'] ?? 0}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizRecord(dynamic quiz) {
    final score = quiz['score'] ?? 0;
    final total = quiz['total_marks'] ?? 0;
    final pct = (quiz['percentage'] ?? 0).toDouble();
    final date = (quiz['attempted_at'] ?? '').toString().split(' ').first;
    final timeTaken = quiz['time_taken_secs'] as int?;

    final color = pct >= 70 ? AppColors.success : pct >= 40 ? AppColors.warning : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${pct.toInt()}%',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: $score / $total',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(date, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    if (timeTaken != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${(timeTaken / 60).floor()}m ${timeTaken % 60}s',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          StatusBadge(
            label: pct >= 70 ? 'PASS' : 'FAIL',
            color: color,
          ),
        ],
      ),
    );
  }
}
