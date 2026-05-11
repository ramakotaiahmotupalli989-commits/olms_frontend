/// EduCinema LMS — Parent Dashboard
/// Child summary, subject progress, scores, teacher messages, child switcher.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});
  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _attendanceData;
  bool _loading = true;
  late AnimationController _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _load();
  }

  @override
  void dispose() { _heroAnim.dispose(); super.dispose(); }

  Future<void> _load({int? childId}) async {
    try {
      final params = childId != null ? {'child_id': childId.toString()} : null;
      final data = await _repo.get('/parent/dashboard', params: params?.cast<String, dynamic>());
      
      final targetId = childId ?? data['child']?['id'];
      Map<String, dynamic>? attendance;
      if (targetId != null) {
        attendance = await _repo.get('/parent/child/$targetId/attendance/summary');
      }

      setState(() { 
        _data = data; 
        _attendanceData = attendance;
        _loading = false; 
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildChildSwitcher(),
                  const SizedBox(height: 16),
                  _buildChildCard(),
                  const SizedBox(height: 20),
                  _buildSubjectProgress(),
                  const SizedBox(height: 24),
                  _buildRecentScores(),
                  const SizedBox(height: 24),
                  _buildAttendanceSummary(),
                  const SizedBox(height: 24),
                  _buildTeacherMessages(),
                  const SizedBox(height: 24),
                  _buildWeeklySummaryButton(),
                ]),
              ),
            ),
    );
  }

  Widget _buildChildSwitcher() {
    final children = (_data?['children'] as List?) ?? [];
    if (children.length <= 1) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: _heroAnim, child: Text('My Child\'s Progress', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('My Children', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: children.length,
          itemBuilder: (_, i) {
            final c = children[i];
            final selected = c['is_selected'] ?? false;
            return GestureDetector(
              onTap: () {
                setState(() => _loading = true);
                _load(childId: c['id']);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]) : null,
                    color: selected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: selected ? null : Border.all(color: Colors.grey.shade200),
                    boxShadow: selected ? [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                  ),
                child: Text(c['name'] ?? '', style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                )),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildChildCard() {
    final child = _data?['child'] ?? {};
    final streak = _data?['current_streak'] ?? 0;
    final completion = _data?['overall_completion'] ?? 0;
    final lastActive = _data?['last_active'] ?? 'Never';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 24, backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text((child['name'] ?? 'S')[0], style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(child['name'] ?? '', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Grade ${child['grade'] ?? ''} ${child['section'] != null ? '• Section ${child['section']}' : ''}',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _buildMiniStat('\u{1F525}', '$streak days', 'Streak'),
          const SizedBox(width: 16),
          _buildMiniStat('\u{1F4CA}', '$completion%', 'Completion'),
          const SizedBox(width: 16),
          _buildMiniStat('\u{1F4F1}', lastActive.toString().split(' ').first, 'Last Active'),
        ]),
      ]),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
    ]);
  }

  Widget _buildSubjectProgress() {
    final subjects = (_data?['subject_progress'] as List?) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Subject Progress'),
      ...subjects.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: LabeledProgressBar(
              label: s['subject'] ?? '',
              value: (s['progress_percent'] ?? 0) / 100,
              color: (s['progress_percent'] ?? 0) >= 70 ? AppColors.success : (s['progress_percent'] ?? 0) >= 40 ? AppColors.warning : AppColors.primary,
            ),
          )),
      if (subjects.isEmpty) const EmptyState(icon: Icons.subject, title: 'No subjects yet', subtitle: 'Subject progress will appear once your child starts learning'),
    ]);
  }

  Widget _buildRecentScores() {
    final scores = (_data?['recent_scores'] as List?) ?? [];
    if (scores.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Recent Quiz Scores'),
      SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: scores.length,
          itemBuilder: (_, i) {
            final s = scores[i];
            final pct = (s['total'] ?? 1) > 0 ? (s['score'] ?? 0) / (s['total'] ?? 1) : 0.0;
            return Container(
              width: 90, margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pct >= 0.7 ? AppColors.success.withValues(alpha: 0.08) : AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${s['score']}/${s['total']}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('${(pct * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildTeacherMessages() {
    final unread = _data?['unread_teacher_messages'] ?? 0;
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: unread > 0 ? AppColors.primary : Colors.grey.shade200),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.message_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Teacher Messages', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(unread > 0 ? '$unread unread message${unread > 1 ? 's' : ''}' : 'No new messages',
                style: GoogleFonts.inter(fontSize: 12, color: unread > 0 ? AppColors.primary : AppColors.textSecondary)),
          ])),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Text('$unread', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  Widget _buildWeeklySummaryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('View Weekly Summary'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    if (_attendanceData == null) return const SizedBox.shrink();
    final pct = (_attendanceData?['attendance_percentage'] ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Child Attendance'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Attendance',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pct%',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: pct >= 75 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  _buildAttendanceIndicator(pct),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attnStat('Present', _attendanceData?['total_present'] ?? 0, AppColors.success),
                  _attnStat('Absent', _attendanceData?['total_absent'] ?? 0, AppColors.error),
                  _attnStat('Late', _attendanceData?['total_late'] ?? 0, AppColors.warning),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceIndicator(double percentage) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(percentage >= 75 ? AppColors.success : AppColors.error),
          ),
          Center(
            child: Icon(
              percentage >= 75 ? Icons.verified_user_rounded : Icons.info_outline_rounded,
              color: percentage >= 75 ? AppColors.success : AppColors.error,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attnStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
