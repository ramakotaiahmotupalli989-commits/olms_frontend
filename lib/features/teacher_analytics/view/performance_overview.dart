/// EduCinema LMS — Teacher Performance Analytics
/// Real data: class performance, individual student progress, video watch tracking.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class PerformanceOverview extends StatefulWidget {
  const PerformanceOverview({super.key});
  @override
  State<PerformanceOverview> createState() => _PerformanceOverviewState();
}

class _PerformanceOverviewState extends State<PerformanceOverview>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  late TabController _tabCtrl;

  bool _loading = true;
  List<dynamic> _classes = [];
  List<dynamic> _classPerformance = [];
  List<dynamic> _studentProgress = [];
  Map<String, dynamic>? _videoWatch;
  int? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadInitial();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      _classes = await _repo.getList('/teacher/attendance/classes');
      final perfData = await _repo.get('/teacher/analytics/class-performance');
      _classPerformance = (perfData['classes'] as List?) ?? [];
      if (_classes.isNotEmpty) {
        _selectedClassId = _classes[0]['class_id'] as int;
        await _loadClassDetails();
      }
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[Analytics] Load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadClassDetails() async {
    if (_selectedClassId == null) return;
    try {
      final progData = await _repo.get('/teacher/analytics/student-progress', params: {'class_id': _selectedClassId.toString()});
      _studentProgress = (progData['students'] as List?) ?? [];
      _videoWatch = await _repo.get('/teacher/analytics/video-watch-status', params: {'class_id': _selectedClassId.toString()});
      setState(() {});
    } catch (e) {
      debugPrint('[Analytics] Class detail error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Classes'),
            Tab(text: 'Students'),
            Tab(text: 'Video Watch'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildClassTab(),
                _buildStudentsTab(),
                _buildVideoTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1: CLASS PERFORMANCE OVERVIEW
  // ═══════════════════════════════════════════
  Widget _buildClassTab() {
    if (_classPerformance.isEmpty) {
      return const EmptyState(
        icon: Icons.analytics_outlined,
        title: 'No class data',
        subtitle: 'Your assigned classes will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _classPerformance.map((c) => _buildClassCard(c)).toList(),
      ),
    );
  }

  Widget _buildClassCard(dynamic c) {
    final label = c['class_label'] ?? '';
    final students = c['total_students'] ?? 0;
    final quizAvg = (c['avg_quiz_score'] ?? 0).toDouble();
    final videoAvg = (c['avg_video_completion'] ?? 0).toDouble();
    final attendance = (c['attendance_rate'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.class_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Class $label', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('$students students', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ])),
            InkWell(
              onTap: () {
                setState(() => _selectedClassId = c['class_id']);
                _loadClassDetails();
                _tabCtrl.animateTo(1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('Details →', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ),
        // KPIs
        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(children: [
              _kpiMini('Quiz Avg', '${quizAvg.toStringAsFixed(1)}%', quizAvg >= 60 ? AppColors.success : AppColors.warning, Icons.quiz_rounded),
              const SizedBox(width: 8),
              _kpiMini('Video', '${videoAvg.toStringAsFixed(1)}%', videoAvg >= 50 ? AppColors.info : AppColors.warning, Icons.play_circle_rounded),
              const SizedBox(width: 8),
              _kpiMini('Attendance', '${attendance.toStringAsFixed(1)}%', attendance >= 75 ? AppColors.success : AppColors.error, Icons.how_to_reg_rounded),
            ]);
          }),
        ),
      ]),
    );
  }

  Widget _kpiMini(String label, String value, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color))),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: color.withValues(alpha: 0.7))),
      ]),
    ));
  }

  // ═══════════════════════════════════════════
  // TAB 2: INDIVIDUAL STUDENT PROGRESS
  // ═══════════════════════════════════════════
  Widget _buildStudentsTab() {
    return Column(children: [
      _buildClassSelector(),
      Expanded(
        child: _studentProgress.isEmpty
            ? const EmptyState(icon: Icons.people_outline, title: 'No students', subtitle: 'Select a class to view student progress')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _studentProgress.length,
                itemBuilder: (_, i) => _buildStudentCard(_studentProgress[i], i + 1),
              ),
      ),
    ]);
  }

  Widget _buildClassSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.class_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedClassId,
              isExpanded: true,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              items: _classes.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                value: c['class_id'] as int,
                child: Text('Class ${c['grade']}${c['section'] != null ? '-${c['section']}' : ''}'),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedClassId = val);
                _loadClassDetails();
              },
            ),
          ),
        ),
        Text('${_studentProgress.length} students', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildStudentCard(dynamic s, int rank) {
    final name = s['name'] ?? '';
    final roll = s['roll_number'] ?? '';
    final quizAvg = (s['quiz_avg'] ?? 0).toDouble();
    final videoCount = s['videos_watched'] ?? 0;
    final videoAvg = (s['avg_video_completion'] ?? 0).toDouble();
    final examAvg = s['exam_avg'];
    final attendance = (s['attendance_pct'] ?? 0).toDouble();

    // Overall health
    final overallScore = (quizAvg * 0.3 + videoAvg * 0.3 + attendance * 0.4);
    final healthColor = overallScore >= 70 ? AppColors.success
        : overallScore >= 50 ? AppColors.warning : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: healthColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const Border(),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: healthColor.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0] : '?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: healthColor)),
        ),
        title: Row(children: [
          Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: healthColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text('${overallScore.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: healthColor)),
          ),
        ]),
        subtitle: roll.isNotEmpty ? Text('Roll: $roll', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)) : null,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Progress bars
          _progressRow('Quiz Avg', quizAvg, AppColors.info, icon: Icons.quiz_rounded),
          _progressRow('Video Progress', videoAvg, const Color(0xFF764BA2), icon: Icons.play_circle_rounded),
          _progressRow('Attendance', attendance, AppColors.success, icon: Icons.how_to_reg_rounded),
          if (examAvg != null) _progressRow('Exam Avg', examAvg.toDouble(), AppColors.gold, icon: Icons.assignment_rounded),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _statChip(Icons.play_circle_outline, '$videoCount videos', const Color(0xFF764BA2)),
            _statChip(Icons.quiz_rounded, '${s['total_quizzes'] ?? 0} quizzes', AppColors.info),
          ]),
        ],
      ),
    );
  }

  Widget _progressRow(String label, double value, Color color, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 6)],
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0), minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        )),
        const SizedBox(width: 8),
        SizedBox(width: 40, child: Text('${value.toStringAsFixed(0)}%', textAlign: TextAlign.right,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 3: VIDEO WATCH TRACKING
  // ═══════════════════════════════════════════
  Widget _buildVideoTab() {
    final videos = (_videoWatch?['videos'] as List?) ?? [];

    return Column(children: [
      _buildClassSelector(),
      // Summary bar
      if (videos.isNotEmpty) Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Row(children: [
          _watchSummaryBadge('Total Videos', '${_videoWatch?['total_videos'] ?? 0}', const Color(0xFF667EEA)),
          const SizedBox(width: 8),
          _watchSummaryBadge('Students', '${_videoWatch?['total_students'] ?? 0}', AppColors.info),
        ]),
      ),
      Expanded(
        child: videos.isEmpty
            ? const EmptyState(icon: Icons.play_circle_outline, title: 'No video data', subtitle: 'Video watch progress will appear here')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: videos.length,
                itemBuilder: (_, i) => _buildVideoWatchCard(videos[i]),
              ),
      ),
    ]);
  }

  Widget _watchSummaryBadge(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: color.withValues(alpha: 0.7))),
      ]),
    ));
  }

  Widget _buildVideoWatchCard(dynamic video) {
    final title = video['video_title'] ?? '';
    final chapter = video['chapter_title'] ?? '';
    final subject = video['subject_name'] ?? '';
    final totalStudents = video['total_students'] ?? 0;
    final watchedCount = video['watched_count'] ?? 0;
    final watchPct = (video['watch_percentage'] ?? 0).toDouble();
    final students = (video['students'] as List?) ?? [];

    final pctColor = watchPct >= 80 ? AppColors.success
        : watchPct >= 50 ? AppColors.warning : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pctColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const Border(),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [pctColor.withValues(alpha: 0.15), pctColor.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: watchPct / 100, strokeWidth: 3,
              backgroundColor: pctColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(pctColor),
            ),
            Center(child: Text('${watchPct.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: pctColor))),
          ]),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Wrap(spacing: 8, runSpacing: 2, children: [
          Text(subject, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF667EEA))),
          Text('Ch: $chapter', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          Text('$watchedCount/$totalStudents watched', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: pctColor)),
        ]),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Student watch list
          ...students.map<Widget>((s) {
            final sPct = (s['watched_percent'] ?? 0).toDouble();
            final completed = s['completed'] ?? false;
            final sColor = completed ? AppColors.success
                : sPct > 0 ? AppColors.warning : AppColors.error;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(
                  completed ? Icons.check_circle_rounded
                      : sPct > 0 ? Icons.watch_later_rounded
                      : Icons.cancel_rounded,
                  size: 16, color: sColor,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(s['student_name'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))),
                SizedBox(width: 50, child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: sPct / 100, minHeight: 5,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(sColor),
                  ),
                )),
                const SizedBox(width: 6),
                SizedBox(width: 40, child: Text(
                  '${sPct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: sColor),
                )),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
