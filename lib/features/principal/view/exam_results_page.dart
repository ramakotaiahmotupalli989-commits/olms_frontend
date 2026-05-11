/// EduCinema LMS — Exam Results Page (Principal)
/// School-wide exam results viewer with class-wise breakdown and rankings.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ExamResultsPage extends StatefulWidget {
  const ExamResultsPage({super.key});

  @override
  State<ExamResultsPage> createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends State<ExamResultsPage> {
  final _repo = ApiRepository();

  bool _loading = true;
  List<dynamic> _exams = [];
  List<dynamic> _results = [];
  int? _selectedExamId;
  int? _selectedClassId;

  // Class list
  List<dynamic> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      _exams = await _repo.getList('/exams');
      // Load classes from principal dashboard endpoint
      final dashboard = await _repo.get('/principal/dashboard');
      final classesRaw = dashboard['classes'];
      if (classesRaw is List) {
        _classes = classesRaw;
      }
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[ExamResults] Load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadResults() async {
    if (_selectedExamId == null || _selectedClassId == null) return;
    setState(() => _loading = true);
    try {
      final data = await _repo.get('/exams/$_selectedExamId/class/$_selectedClassId/results');
      _results = (data['students'] as List?) ?? [];
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[ExamResults] Load results error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Exam Results')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const EmptyState(
                        icon: Icons.leaderboard_rounded,
                        title: 'Select Exam & Class',
                        subtitle: 'Choose an exam and class to view results with rankings',
                      )
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedExamId,
              decoration: InputDecoration(
                labelText: 'Exam',
                prefixIcon: const Icon(Icons.assignment_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              items: _exams.map<DropdownMenuItem<int>>((e) {
                final typeLabel = (e['exam_type'] ?? '').toString().replaceAll('_', ' ');
                return DropdownMenuItem(
                  value: e['id'] as int,
                  child: Text('${e['name']} ($typeLabel)', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedExamId = val);
                _loadResults();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedClassId,
              decoration: InputDecoration(
                labelText: 'Class',
                prefixIcon: const Icon(Icons.class_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              items: _classes.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem(
                  value: c['class_id'] as int? ?? c['id'] as int,
                  child: Text('${c['grade']}${c['section'] != null ? '-${c['section']}' : ''}'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedClassId = val);
                _loadResults();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final student = _results[index];
        final rank = student['rank'] ?? (index + 1);
        final name = student['student_name'] ?? '';
        final roll = student['roll_number'] ?? '';
        final pct = (student['percentage'] ?? 0).toDouble();
        final totalObtained = student['total_obtained'] ?? 0;
        final totalMax = student['total_max'] ?? 0;
        final subjects = (student['subjects'] as List?) ?? [];

        Color rankColor;
        IconData? rankIcon;
        if (rank == 1) {
          rankColor = AppColors.gold;
          rankIcon = Icons.emoji_events_rounded;
        } else if (rank == 2) {
          rankColor = AppColors.silver;
          rankIcon = Icons.emoji_events_rounded;
        } else if (rank == 3) {
          rankColor = AppColors.bronze;
          rankIcon = Icons.emoji_events_rounded;
        } else {
          rankColor = AppColors.textSecondary;
          rankIcon = null;
        }

        final pctColor = pct >= 80
            ? AppColors.success
            : pct >= 60
                ? AppColors.info
                : pct >= 40
                    ? AppColors.warning
                    : AppColors.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : Colors.grey.shade100,
              width: rank <= 3 ? 1.5 : 1,
            ),
            boxShadow: rank <= 3
                ? [BoxShadow(color: rankColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: rank <= 3
                    ? LinearGradient(colors: [rankColor, rankColor.withValues(alpha: 0.6)])
                    : null,
                color: rank > 3 ? AppColors.surfaceVariant : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: rankIcon != null && rank <= 3
                  ? Icon(rankIcon, color: Colors.white, size: 20)
                  : Text(
                      '#$rank',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: rank <= 3 ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
            ),
            title: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Row(
              children: [
                if (roll.toString().isNotEmpty)
                  Text('Roll: $roll  •  ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: pctColor),
                ),
                Text(
                  '  ($totalObtained/$totalMax)',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
            children: [
              if (subjects.isNotEmpty)
                ...subjects.map<Widget>((subj) {
                  final subjPct = (subj['percentage'] ?? 0).toDouble();
                  final subjColor = subjPct >= 80
                      ? AppColors.success
                      : subjPct >= 60
                          ? AppColors.info
                          : subjPct >= 40
                              ? AppColors.warning
                              : AppColors.error;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            subj['subject'] ?? '',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: LabeledProgressBar(
                            label: '',
                            value: subjPct / 100,
                            color: subjColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${subj['marks_obtained']}/${subj['total_marks']}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: subjColor),
                          ),
                        ),
                        if (subj['grade'] != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: subjColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subj['grade'],
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: subjColor),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
