/// EduCinema LMS — Student Dashboard
/// High-fidelity student experience with animated hero, gradient subject cards, and ranking section.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
  final _repo = ApiRepository();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _attendanceData;
  bool _loading = true;
  late AnimationController _streakAnim;
  late AnimationController _heroAnim;

  @override
  void initState() {
    super.initState();
    _streakAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _heroAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _load();
  }

  @override
  void dispose() { _streakAnim.dispose(); _heroAnim.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final data = await _repo.get('/student/dashboard');
      final attendance = await _repo.get('/student/attendance/summary');
      setState(() { 
        _data = data; 
        _attendanceData = attendance;
        _loading = false; 
      });
      _streakAnim.forward();
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
                  _buildWelcomeBanner(),
                  const SizedBox(height: 20),
                  _buildContinueLearning(),
                  const SizedBox(height: 24),
                  _buildAskDoubtCard(),
                  const SizedBox(height: 24),
                  _buildSubjectsGrid(),
                  const SizedBox(height: 24),
                  _buildActiveTests(),
                  const SizedBox(height: 24),
                  _buildPendingAssignments(),
                  const SizedBox(height: 24),
                  _buildAttendanceSummary(),
                  const SizedBox(height: 24),
                  _buildRecentScores(),
                  const SizedBox(height: 24),
                  _buildRankingSection(),
                  const SizedBox(height: 24),
                  _buildBadges(),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeBanner() {
    final name = _data?['name'] ?? 'Student';
    final streak = _data?['current_streak'] ?? 0;
    final points = _data?['total_points'] ?? 0;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(
        opacity: _heroAnim,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hey, $name! \u{1F44B}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Ready to learn something awesome today?', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            Row(children: [
              ScaleTransition(
                scale: CurvedAnimation(parent: _streakAnim, curve: Curves.elasticOut),
                child: _statChip('\u{1F525} $streak day streak'),
              ),
              const SizedBox(width: 10),
              _statChip('\u{2B50} $points pts'),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }

  Widget _buildContinueLearning() {
    final cl = _data?['continue_learning'];
    if (cl == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Continue Learning'),
      GestureDetector(
        onTap: () {
          final videoId = cl['video_id'];
          if (videoId != null) {
            context.push(
              '/presentation/$videoId'
              '?title=${Uri.encodeComponent(cl['title'] ?? 'Lesson')}'
              '&url=${Uri.encodeComponent(cl['video_url'] ?? '')}'
              '&thumb=${Uri.encodeComponent(cl['thumbnail_url'] ?? '')}'
              '&duration=${cl['duration_secs'] ?? 0}',
            );
          }
        },
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 72, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cl['title'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (cl['watched_percent'] ?? 0) / 100,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF667EEA)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text('${(cl['watched_percent'] ?? 0).toStringAsFixed(0)}% complete', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildSubjectsGrid() {
    final subjects = (_data?['subjects'] as List?) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'My Subjects'),
      LayoutBuilder(builder: (context, c) {
        final crossCount = c.maxWidth > 500 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
          ),
          itemCount: subjects.length,
          itemBuilder: (_, i) {
            final s = subjects[i];
            final progress = (s['progress_percent'] ?? 0).toDouble();
            final gradients = [
              [const Color(0xFF667EEA), const Color(0xFF764BA2)],
              [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
              [const Color(0xFF4ECDC4), const Color(0xFF44B09E)],
              [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
              [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
              [const Color(0xFFF7797D), const Color(0xFFC471ED)],
            ];
            final gradient = gradients[i % gradients.length];
            return GestureDetector(
              onTap: () => context.push('/student/subject/${s['id']}?name=${Uri.encodeComponent(s['name'] ?? 'Subject')}'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [gradient[0], gradient[1]], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(s['name'] ?? '', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${s['completed_videos'] ?? 0}/${s['total_videos'] ?? 0} videos', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100, backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 5,
                      ),
                    ),
                  ]),
                ]),
              ),
            );
          },
        );
      }),
    ]);
  }

  Widget _buildPendingAssignments() {
    final assignments = (_data?['pending_assignments'] as List?) ?? [];
    if (assignments.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Pending Assignments'),
      ...assignments.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(a['type'] == 'homework' ? Icons.home_work_rounded : Icons.edit_note_rounded, color: AppColors.secondary, size: 20),
              ),
              title: Text(a['title'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('Due: ${a['due_date'] ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: (a['is_overdue'] ?? false) ? AppColors.error : AppColors.textSecondary)),
              trailing: StatusBadge(label: (a['type'] ?? '').toString().toUpperCase(), color: AppColors.secondary),
            ),
          )),
    ]);
  }

  Widget _buildAttendanceSummary() {
    if (_attendanceData == null) return const SizedBox.shrink();
    final pct = (_attendanceData?['attendance_percentage'] ?? 0).toDouble();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Attendance'),
        GlassCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: pct >= 75 ? AppColors.success : AppColors.error)),
                    ],
                  ),
                  SizedBox(
                    width: 56, height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(value: pct / 100, strokeWidth: 7, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(pct >= 75 ? AppColors.success : AppColors.error)),
                        Center(child: Icon(pct >= 75 ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, color: pct >= 75 ? AppColors.success : AppColors.error, size: 22)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
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

  Widget _attnStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildRecentScores() {
    final scores = (_data?['recent_scores'] as List?) ?? [];
    if (scores.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Recent Quiz Scores'),
      SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: scores.length,
          itemBuilder: (_, i) {
            final s = scores[i];
            final pct = (s['total'] ?? 1) > 0 ? (s['score'] ?? 0) / (s['total'] ?? 1) : 0.0;
            final color = pct >= 0.7 ? AppColors.success : pct >= 0.4 ? AppColors.warning : AppColors.error;
            return Container(
              width: 90, margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10)],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${s['score']}/${s['total']}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                Text('${(pct * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildRankingSection() {
    final rankings = (_data?['test_rankings'] as List?) ?? [];
    if (rankings.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Results & Ranks'),
      ...rankings.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8F00)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 8)],
                ),
                child: Center(child: Text('#${r['rank']}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              title: Text(r['quiz_title'] ?? 'Test Result', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('Score: ${r['score']}/${r['total_marks']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              trailing: TextButton(
                onPressed: () => context.push('/ranking/${r['quiz_id']}/${r['class_id']}'),
                child: const Text('View Board'),
              ),
            ),
          )),
    ]);
  }

  Widget _buildBadges() {
    final badges = (_data?['recent_badges'] as List?) ?? [];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Achievements'),
      Wrap(spacing: 10, runSpacing: 10, children: badges.map((b) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8F00)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('\u{1F3C6}', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(b['label'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          )).toList()),
    ]);
  }

  Widget _buildAskDoubtCard() {
    return GestureDetector(
      onTap: () => context.push('/messaging/new'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.info, Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.info.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask a Doubt',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stuck on a topic? Message your teachers for help.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTests() {
    final activeTests = (_data?['active_tests'] as List?) ?? [];
    if (activeTests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Active & Upcoming Quizzes'),
        const SizedBox(height: 8),
        ...activeTests.map((t) {
          final isActive = t['status'] == 'active';
          final badgeColor = isActive ? AppColors.success : AppColors.info;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badgeColor.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive ? Icons.play_arrow_rounded : Icons.lock_clock,
                      color: badgeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t['status'].toString().toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t['subject_name'] ?? 'Subject',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t['quiz_title'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isActive)
                    ElevatedButton(
                      onPressed: () => context.push('/student/test-taking/${t['id']}').then((_) => _load()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'Start',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    )
                  else
                    Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

