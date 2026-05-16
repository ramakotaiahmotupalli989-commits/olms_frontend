/// EduCinema LMS — Exam Results Page (Principal)
/// School-wide exam management: create exams, view results with rankings,
/// subject analytics, and toppers.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ExamResultsPage extends StatefulWidget {
  const ExamResultsPage({super.key});

  @override
  State<ExamResultsPage> createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends State<ExamResultsPage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  late TabController _tabController;

  bool _loading = true;
  List<dynamic> _exams = [];
  List<dynamic> _classes = [];
  List<dynamic> _results = [];
  int? _selectedExamId;
  int? _selectedClassId;

  // Analytics
  double _avgPercentage = 0;
  int _passCount = 0;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      _exams = await _repo.getList('/exams');
      final dashboard = await _repo.get('/principal/dashboard');
      final classesRaw = dashboard['classes'];
      if (classesRaw is List) _classes = classesRaw;
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadResults() async {
    if (_selectedExamId == null || _selectedClassId == null) return;
    setState(() => _loading = true);
    try {
      final data = await _repo.get('/exams/$_selectedExamId/class/$_selectedClassId/results');
      _results = (data['students'] as List?) ?? [];
      _computeAnalytics();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _computeAnalytics() {
    if (_results.isEmpty) {
      _avgPercentage = 0; _passCount = 0; _failCount = 0;
      return;
    }
    double totalPct = 0;
    _passCount = 0; _failCount = 0;
    for (var s in _results) {
      final pct = (s['percentage'] ?? 0).toDouble();
      totalPct += pct;
      if (pct >= 40) { _passCount++; } else { _failCount++; }
    }
    _avgPercentage = totalPct / _results.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Exam Results'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Results'), Tab(text: 'Manage Exams')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildResultsTab(), _buildManageTab()],
      ),
    );
  }

  // ── Results Tab ──
  Widget _buildResultsTab() {
    return Column(children: [
      _buildFilters(),
      if (_results.isNotEmpty) _buildAnalyticsRow(),
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
    ]);
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
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
        ]),
      ]),
    );
  }

  Widget _buildAnalyticsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: LayoutBuilder(builder: (context, constraints) {
        return Row(children: [
          _analyticsBadge('Avg', '${_avgPercentage.toStringAsFixed(1)}%', const Color(0xFF667EEA)),
          const SizedBox(width: 10),
          _analyticsBadge('Pass', '$_passCount', AppColors.success),
          const SizedBox(width: 10),
          _analyticsBadge('Fail', '$_failCount', AppColors.error),
          const SizedBox(width: 10),
          _analyticsBadge('Total', '${_results.length}', AppColors.info),
        ]);
      }),
    );
  }

  Widget _analyticsBadge(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7))),
      ]),
    ));
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

        final pctColor = pct >= 80 ? AppColors.success
            : pct >= 60 ? AppColors.info
            : pct >= 40 ? AppColors.warning
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
              width: 40, height: 40, alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: rank <= 3 ? LinearGradient(colors: [rankColor, rankColor.withValues(alpha: 0.6)]) : null,
                color: rank > 3 ? AppColors.surfaceVariant : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: rankIcon != null && rank <= 3
                  ? Icon(rankIcon, color: Colors.white, size: 20)
                  : Text('#$rank', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: rank <= 3 ? Colors.white : AppColors.textSecondary)),
            ),
            title: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            subtitle: Wrap(spacing: 8, runSpacing: 2, children: [
              if (roll.toString().isNotEmpty) Text('Roll: $roll', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: pctColor)),
              Text('($totalObtained/$totalMax)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
            ]),
            children: [
              if (subjects.isNotEmpty)
                ...subjects.map<Widget>((subj) {
                  final subjPct = (subj['percentage'] ?? 0).toDouble();
                  final subjColor = subjPct >= 80 ? AppColors.success
                      : subjPct >= 60 ? AppColors.info
                      : subjPct >= 40 ? AppColors.warning
                      : AppColors.error;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
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
      },
    );
  }

  // ── Manage Exams Tab ──
  Widget _buildManageTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showCreateExamDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create New Exam'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _exams.isEmpty
                ? const EmptyState(icon: Icons.assignment_outlined, title: 'No exams', subtitle: 'Create your first exam')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _exams.length,
                    itemBuilder: (_, i) => _buildExamManageCard(_exams[i]),
                  ),
      ),
    ]);
  }

  Widget _buildExamManageCard(dynamic exam) {
    final typeLabel = (exam['exam_type'] ?? '').toString().replaceAll('_', ' ');
    final startDate = exam['start_date'];
    final endDate = exam['end_date'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
        ),
        title: Text(exam['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Wrap(spacing: 8, runSpacing: 4, children: [
          StatusBadge(label: typeLabel.toUpperCase(), color: AppColors.featureBlue),
          if (startDate != null) Text('From: $startDate', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          if (endDate != null) Text('To: $endDate', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
        ]),
        trailing: IconButton(
          icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
          onPressed: () => _deleteExam(exam['id'], exam['name']),
        ),
      ),
    );
  }

  Future<void> _showCreateExamDialog() async {
    final nameCtrl = TextEditingController();
    String examType = 'quarterly';
    DateTime? startDate;
    DateTime? endDate;

    // Load academic years
    List<dynamic> academicYears = [];
    int? selectedAyId;
    try {
      final dashboard = await _repo.get('/principal/dashboard');
      // Try to get academic year from dashboard
      if (dashboard['academic_year'] != null) {
        selectedAyId = dashboard['academic_year']['id'];
        academicYears = [dashboard['academic_year']];
      }
    } catch (_) {}

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Create Exam', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Exam Name *', prefixIcon: Icon(Icons.edit_rounded), hintText: 'e.g. Quarterly Exam - Term 1'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: examType,
              decoration: const InputDecoration(labelText: 'Exam Type', prefixIcon: Icon(Icons.category_rounded)),
              items: const [
                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                DropdownMenuItem(value: 'half_yearly', child: Text('Half Yearly')),
                DropdownMenuItem(value: 'annual', child: Text('Annual')),
              ],
              onChanged: (v) => setDialogState(() => examType = v!),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: ctx2, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
                  if (picked != null) setDialogState(() => startDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Start Date'),
                  child: Text(startDate != null ? DateFormat('d MMM yyyy').format(startDate!) : 'Select', style: GoogleFonts.inter(fontSize: 13)),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: ctx2, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
                  if (picked != null) setDialogState(() => endDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'End Date'),
                  child: Text(endDate != null ? DateFormat('d MMM yyyy').format(endDate!) : 'Select', style: GoogleFonts.inter(fontSize: 13)),
                ),
              )),
            ]),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (result != true || nameCtrl.text.isEmpty) return;

    try {
      await _repo.post('/exams', data: {
        'name': nameCtrl.text,
        'exam_type': examType,
        'academic_year_id': selectedAyId ?? 1,
        if (startDate != null) 'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
        if (endDate != null) 'end_date': DateFormat('yyyy-MM-dd').format(endDate!),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam created!'), backgroundColor: AppColors.success));
        _loadInitialData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteExam(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Exam?'),
        content: Text('This will permanently delete "$name" and all its scores.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _repo.delete('/exams/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam deleted'), backgroundColor: AppColors.success));
        _loadInitialData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }
}
