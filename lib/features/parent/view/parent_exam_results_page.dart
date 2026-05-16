/// EduCinema LMS — Parent Exam Results Page
/// Parents view their child's exam results, rankings, and weak subjects.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ParentExamResultsPage extends StatefulWidget {
  const ParentExamResultsPage({super.key});
  @override
  State<ParentExamResultsPage> createState() => _ParentExamResultsPageState();
}

class _ParentExamResultsPageState extends State<ParentExamResultsPage> {
  final _repo = ApiRepository();
  bool _loading = true;
  List<dynamic> _children = [];
  int? _selectedChildId;
  List<dynamic> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _loading = true);
    try {
      _children = await _repo.getList('/parent/children');
      if (_children.isNotEmpty) {
        _selectedChildId = _children[0]['id'];
        await _loadExams();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadExams() async {
    if (_selectedChildId == null) return;
    setState(() => _loading = true);
    try {
      _exams = await _repo.getList('/parent/child/$_selectedChildId/exams');
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Child Exam Results')),
      body: Column(children: [
        if (_children.length > 1) _buildChildSwitcher(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _exams.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No exam results',
                      subtitle: 'Your child\'s results will appear here',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadExams,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildOverallSummary(),
                          const SizedBox(height: 16),
                          _buildWeakSubjects(),
                          const SizedBox(height: 16),
                          const SectionHeader(title: 'Exam Results'),
                          const SizedBox(height: 8),
                          ..._exams.map((exam) => _buildExamCard(exam)),
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildChildSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedChildId, isExpanded: true,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              items: _children.map<DropdownMenuItem<int>>((c) {
                final grade = c['grade'] ?? '';
                final section = c['section'] ?? '';
                final label = '${c['name']}${grade.isNotEmpty ? ' (Grade $grade$section)' : ''}';
                return DropdownMenuItem(value: c['id'] as int, child: Text(label));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedChildId = val);
                _loadExams();
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildOverallSummary() {
    if (_exams.isEmpty) return const SizedBox.shrink();
    // Use the latest exam for summary
    final latest = _exams[0];
    final pct = (latest['overall_percentage'] ?? 0).toDouble();
    final isGood = pct >= 60;

    // Average across all exams
    double avgPct = 0;
    if (_exams.isNotEmpty) {
      avgPct = _exams.fold(0.0, (sum, e) => sum + (e['overall_percentage'] ?? 0).toDouble()) / _exams.length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGood
              ? [const Color(0xFF43E97B), const Color(0xFF38F9D7)]
              : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: (isGood ? const Color(0xFF43E97B) : const Color(0xFFFF6B6B)).withValues(alpha: 0.3),
          blurRadius: 16, offset: const Offset(0, 6),
        )],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Performance Overview', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text('${avgPct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text('Average across ${_exams.length} exam${_exams.length > 1 ? 's' : ''}',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
        ])),
        SizedBox(
          width: 70, height: 70,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: avgPct / 100, strokeWidth: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
            Center(child: Icon(isGood ? Icons.thumb_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 28)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildWeakSubjects() {
    // Aggregate subject performance across exams
    final Map<String, List<double>> subjectPcts = {};
    for (var exam in _exams) {
      for (var s in (exam['subjects'] as List? ?? [])) {
        final name = s['subject'] ?? '';
        if (name.isEmpty) continue;
        subjectPcts.putIfAbsent(name, () => []);
        subjectPcts[name]!.add((s['percentage'] ?? 0).toDouble());
      }
    }

    final weakSubjects = <MapEntry<String, double>>[];
    for (var entry in subjectPcts.entries) {
      final avg = entry.value.fold(0.0, (s, v) => s + v) / entry.value.length;
      if (avg < 60) weakSubjects.add(MapEntry(entry.key, avg));
    }
    weakSubjects.sort((a, b) => a.value.compareTo(b.value));

    if (weakSubjects.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
        const SizedBox(width: 8),
        Text('Weak Subjects', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning)),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: weakSubjects.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(s.key, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('${s.value.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.error)),
        ]),
      )).toList()),
    ]);
  }

  Widget _buildExamCard(dynamic exam) {
    final examName = exam['exam_name'] ?? '';
    final examType = (exam['exam_type'] ?? '').toString().replaceAll('_', ' ');
    final pct = (exam['overall_percentage'] ?? 0).toDouble();
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

    // Derive grade from pct
    String grade = pct >= 90 ? 'A+' : pct >= 80 ? 'A' : pct >= 70 ? 'B+' : pct >= 60 ? 'B' : pct >= 50 ? 'C' : pct >= 40 ? 'D' : 'F';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          decoration: BoxDecoration(gradient: LinearGradient(colors: gradeGradient), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(grade, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
        title: Text(examName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        subtitle: Wrap(spacing: 12, runSpacing: 4, children: [
          Text(examType.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: pctColor)),
          Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: pctColor)),
          Text('$totalObtained/$totalMax', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
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
