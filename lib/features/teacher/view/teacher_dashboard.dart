/// EduCinema LMS — Teacher Dashboard
/// High-fidelity teacher experience with animated hero, quick actions grid, and premium cards.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  Map<String, dynamic>? _data;
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

  Future<void> _load() async {
    try {
      final data = await _repo.get('/teacher/dashboard');
      setState(() { _data = data; _loading = false; });
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
                  _buildHeroBanner(),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildKpis(),
                  const SizedBox(height: 24),
                  _buildQuizPerformance(),
                  const SizedBox(height: 24),
                  _buildAttentionNeeded(),
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
                ]),
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
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
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF11998E).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('My Classes', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Student engagement & performance insights', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpis() {
    return LayoutBuilder(builder: (context, c) {
      final crossCount = c.maxWidth > 500 ? 3 : 2;
      return GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossCount, mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: c.maxWidth > 500 ? 2.0 : 1.5,
        children: [
          KpiCard(
            title: 'Total Students', value: '${_data?['total_students'] ?? 0}',
            icon: Icons.people_rounded, color: const Color(0xFF667EEA),
          ),
          KpiCard(
            title: 'Watched This Week', value: '${_data?['watched_this_week'] ?? 0}',
            icon: Icons.play_circle_rounded, color: const Color(0xFF43E97B),
          ),
          KpiCard(
            title: 'Quiz Avg', value: '${_data?['avg_quiz_score'] ?? 0}%',
            icon: Icons.quiz_rounded, color: const Color(0xFFFF8F00),
          ),
        ],
      );
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    const int mockClassId = 1; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GradientIconButton(
                icon: Icons.assignment_ind_rounded,
                label: 'Class Roster',
                colors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                onTap: () => GoRouter.of(context).push('/teacher/class/$mockClassId/roster'),
              ),
              const SizedBox(width: 10),
              GradientIconButton(
                icon: Icons.video_library_rounded,
                label: 'Content Library',
                colors: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                onTap: () => GoRouter.of(context).push('/teacher/library'),
              ),
              const SizedBox(width: 10),
              GradientIconButton(
                icon: Icons.quiz_rounded,
                label: 'Quizzes & Tests',
                colors: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
                onTap: () => GoRouter.of(context).push('/teacher/quizzes'),
              ),
              const SizedBox(width: 10),
              GradientIconButton(
                icon: Icons.analytics_rounded,
                label: 'Analytics',
                colors: const [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
                onTap: () => GoRouter.of(context).push('/teacher/analytics'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizPerformance() {
    final quizzes = (_data?['quiz_performance'] as List?) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Quiz Performance by Chapter'),
      if (quizzes.isEmpty)
        const EmptyState(icon: Icons.quiz_rounded, title: 'No quiz data yet', subtitle: 'Quiz performance will appear once students start taking quizzes')
      else
        ...quizzes.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LabeledProgressBar(
                label: q['chapter'] ?? '',
                value: (q['avg_score'] ?? 0) / 100,
                color: (q['avg_score'] ?? 0) >= 70 ? AppColors.success : (q['avg_score'] ?? 0) >= 40 ? AppColors.warning : AppColors.error,
              ),
            )),
    ]);
  }

  Widget _buildAttentionNeeded() {
    final students = (_data?['attention_needed'] as List?) ?? [];
    if (students.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.error_outline, color: AppColors.error, size: 18),
        ),
        const SizedBox(width: 10),
        Text('Needs Attention', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.error)),
        const SizedBox(width: 8),
        StatusBadge(label: '${students.length}', color: AppColors.error),
      ]),
      const SizedBox(height: 12),
      ...students.take(5).map((s) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              dense: true,
              onTap: () => context.push('/teacher/analytics'),
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.person_off_rounded, size: 18, color: AppColors.error),
              ),
              title: Text(s['name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              trailing: Text('Last: ${s['last_login'] ?? 'Never'}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ),
          )),
    ]);
  }

  Widget _buildRecentActivity() {
    final activity = (_data?['recent_activity'] as List?) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Recent Activity'),
      GlassCard(
        padding: EdgeInsets.zero,
        child: activity.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No recent activity', style: GoogleFonts.inter(color: AppColors.textSecondary)),
              )
            : ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: activity.length,
                separatorBuilder: (_, idx) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final a = activity[i];
                  return ListTile(
                    dense: true,
                    onTap: () => context.push('/teacher/analytics'),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(a['type'] == 'quiz' ? Icons.quiz_rounded : Icons.play_arrow_rounded, color: AppColors.primary, size: 18),
                    ),
                    title: Text(a['student_name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Score: ${a['score'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  );
                },
              ),
      ),
    ]);
  }
}
