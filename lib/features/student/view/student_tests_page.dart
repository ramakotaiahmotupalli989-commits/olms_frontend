/// EduCinema LMS — Student Tests Page
/// List scheduled test sessions for the student's class with status badges (Active, Upcoming, Completed, Missed).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

DateTime _parseUtc(String str) {
  var formatted = str;
  if (!formatted.endsWith('Z') && !formatted.contains('+')) {
    final parts = formatted.split(RegExp(r'[T ]'));
    if (parts.length > 1) {
      final timePart = parts[1];
      if (!timePart.contains('-')) {
        formatted = '${formatted}Z';
      }
    } else {
      formatted = '${formatted}Z';
    }
  }
  return DateTime.parse(formatted);
}

class StudentTestsPage extends StatefulWidget {
  const StudentTestsPage({super.key});

  @override
  State<StudentTestsPage> createState() => _StudentTestsPageState();
}

class _StudentTestsPageState extends State<StudentTestsPage> {
  final _repo = ApiRepository();
  bool _loading = true;
  List<dynamic> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _sessions = await _repo.getList('/student/test-sessions');
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[StudentTests] Load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quizzes & Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No tests scheduled',
                  subtitle: 'Your teachers haven\'t scheduled any tests for your class yet.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final s = _sessions[index];
                      return _buildTestCard(s);
                    },
                  ),
                ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> s) {
    final now = DateTime.now();
    final sched = _parseUtc(s['scheduled_at']).toLocal();
    final due = _parseUtc(s['due_at']).toLocal();
    final attempted = s['has_attempted'] ?? false;
    
    // Status resolution
    String status = 'upcoming';
    Color statusColor = AppColors.info;
    if (attempted) {
      status = 'completed';
      statusColor = AppColors.success;
    } else if (now.isAfter(sched) && now.isBefore(due)) {
      status = 'active';
      statusColor = AppColors.secondary;
    } else if (now.isAfter(due)) {
      status = 'missed';
      statusColor = AppColors.error;
    }

    final double scoreVal = (s['score'] ?? 0.0).toDouble();
    final double totalVal = (s['total_marks'] ?? 0.0).toDouble();
    final percent = totalVal > 0 ? (scoreVal / totalVal * 100).toInt() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  s['subject_name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s['quiz_title'] ?? '',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (s['description'] != null && s['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                s['description'],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Due: ${DateFormat('d MMM, h:mm a').format(due)}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (attempted) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.done_all_rounded, size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(
                              'Score: ${scoreVal.toInt()}/${totalVal.toInt()} ($percent%)',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (status == 'active')
                  ElevatedButton(
                    onPressed: () => context.push('/student/test-taking/${s['id']}').then((_) => _load()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text('Start Test', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                if (status == 'completed')
                  TextButton(
                    onPressed: () => _reviewTest(s['id']),
                    child: Row(
                      children: [
                        Text('Review', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reviewTest(int sessionId) async {
    showDialog(
      context: context,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final data = await _repo.get('/student/test-sessions/$sessionId');
      if (mounted) Navigator.pop(context); // Close loading indicator
      
      final bool showAnswers = data['show_answers'] ?? false;
      final questions = (data['questions'] as List?) ?? [];
      final attempt = data['attempt_details'] ?? {};
      final List<dynamic> answers = attempt['answers'] ?? [];

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(data['quiz_title'] ?? 'Review'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Score: ${(attempt['score'] ?? 0).toInt()}/${(attempt['total_marks'] ?? 0).toInt()}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  if (!showAnswers)
                    Text(
                      'Answers are not published yet. They will be visible once the scheduled time limit is complete.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    )
                  else
                    ...questions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final q = entry.value;
                      final List<dynamic> opts = q['options'] ?? [];
                      final int correctIdx = q['correct_option_index'] ?? 0;
                      final int selectedIdx = idx < answers.length ? answers[idx] as int : -1;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedIdx == correctIdx
                              ? AppColors.success.withValues(alpha: 0.05)
                              : AppColors.error.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedIdx == correctIdx ? AppColors.success.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  selectedIdx == correctIdx ? Icons.check_circle : Icons.cancel,
                                  color: selectedIdx == correctIdx ? AppColors.success : AppColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Q${idx + 1}: ${q['question_text'] ?? ''}',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...opts.asMap().entries.map((optEntry) {
                              final oIdx = optEntry.key;
                              final oVal = optEntry.value;
                              final isCorrect = oIdx == correctIdx;
                              final isSelected = oIdx == selectedIdx;
                              
                              Color optColor = AppColors.textPrimary;
                              FontWeight optWeight = FontWeight.w400;
                              if (isCorrect) {
                                optColor = AppColors.success;
                                optWeight = FontWeight.w600;
                              } else if (isSelected) {
                                optColor = AppColors.error;
                                optWeight = FontWeight.w600;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle
                                          : isSelected
                                              ? Icons.cancel
                                              : Icons.circle_outlined,
                                      color: isCorrect
                                          ? AppColors.success
                                          : isSelected
                                              ? AppColors.error
                                              : Colors.grey.shade400,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        oVal.toString(),
                                        style: GoogleFonts.inter(
                                          color: optColor,
                                          fontWeight: optWeight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Explanation: ${q['explanation']}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading review: $e')));
      }
    }
  }
}
