/// EduCinema LMS — Student Exam Results Page
/// Students view their exam marks, percentages, grades, and class rank.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class StudentExamResultsPage extends StatefulWidget {
  const StudentExamResultsPage({super.key});
  @override
  State<StudentExamResultsPage> createState() => _StudentExamResultsPageState();
}

class _StudentExamResultsPageState extends State<StudentExamResultsPage> {
  final _repo = ApiRepository();
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.get('/student/my-results');
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exams = (_data?['exams'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Exam Results')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : exams.isEmpty
              ? const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No exam results yet',
                  subtitle: 'Your results will appear here once published',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStudentHeader(),
                      const SizedBox(height: 16),
                      ...exams.map((exam) => _buildExamCard(exam)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStudentHeader() {
    final name = _data?['student_name'] ?? '';
    final classLabel = _data?['class_label'] ?? '';
    final roll = _data?['roll_number'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26, backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(name.isNotEmpty ? name[0] : 'S', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          Wrap(spacing: 8, children: [
            if (classLabel.isNotEmpty) Text(classLabel, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
            if (roll.isNotEmpty) Text('Roll: $roll', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildExamCard(dynamic exam) {
    final examName = exam['exam_name'] ?? '';
    final examType = (exam['exam_type'] ?? '').toString().replaceAll('_', ' ');
    final pct = (exam['overall_percentage'] ?? 0).toDouble();
    final grade = exam['overall_grade'] ?? '';
    final rank = exam['rank'] ?? 0;
    final totalStudents = exam['total_students'] ?? 0;
    final totalObtained = exam['total_obtained'] ?? 0;
    final totalMax = exam['total_max'] ?? 0;
    final subjects = (exam['subjects'] as List?) ?? [];

    final pctColor = pct >= 80 ? AppColors.success
        : pct >= 60 ? AppColors.info
        : pct >= 40 ? AppColors.warning
        : AppColors.error;

    final gradeGradient = pct >= 80
        ? [const Color(0xFF43E97B), const Color(0xFF38F9D7)]
        : pct >= 60
            ? [const Color(0xFF4FACFE), const Color(0xFF00F2FE)]
            : pct >= 40
                ? [const Color(0xFFFA709A), const Color(0xFFFEE140)]
                : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pctColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        shape: const Border(),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradeGradient),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(grade, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
        title: Text(examName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Wrap(spacing: 12, runSpacing: 4, children: [
          Text(examType.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: pctColor)),
          Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: pctColor)),
          Text('$totalObtained/$totalMax', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          if (rank > 0 && totalStudents > 0) Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(rank <= 3 ? Icons.emoji_events_rounded : Icons.leaderboard_rounded, size: 14, color: rank <= 3 ? AppColors.gold : AppColors.textSecondary),
            const SizedBox(width: 3),
            Text('Rank $rank/$totalStudents', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: rank <= 3 ? AppColors.gold : AppColors.textSecondary)),
          ]),
        ]),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...subjects.map<Widget>((subj) {
            final subjPct = (subj['percentage'] ?? 0).toDouble();
            final subjColor = subjPct >= 80 ? AppColors.success
                : subjPct >= 60 ? AppColors.info
                : subjPct >= 40 ? AppColors.warning
                : AppColors.error;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(flex: 3, child: Text(subj['subject'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))),
                Expanded(flex: 2, child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: subjPct / 100, minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(subjColor),
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 55, child: Text(
                  '${subj['marks_obtained']}/${subj['total_marks']}',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: subjColor),
                )),
                if (subj['grade'] != null) Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: subjColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(subj['grade'], style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: subjColor)),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
