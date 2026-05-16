/// EduCinema LMS — Principal Dashboard
/// High-fidelity school admin dashboard with gradient hero, animated KPIs, and premium cards.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});
  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> with SingleTickerProviderStateMixin {
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
      final data = await _repo.get('/principal/dashboard');
      debugPrint('[PrincipalDashboard] API response keys: ${data.keys}');
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      debugPrint('[PrincipalDashboard] API error: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dashboard load error: $e'), backgroundColor: Colors.red),
        );
      }
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
                  _buildSubscriptionCard(),
                  const SizedBox(height: 24),
                  _buildTeacherActivity(),
                  const SizedBox(height: 24),
                  _buildAtRiskStudents(),
                  const SizedBox(height: 24),
                  _buildTopStudents(),
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
              colors: [Color(0xFF1A237E), Color(0xFF534BAE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('School Dashboard', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Manage your school\'s learning ecosystem', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpis() {
    return LayoutBuilder(builder: (context, c) {
      final crossCount = c.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossCount, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
        children: [
          KpiCard(title: 'Active Students', value: '${_data?['active_students'] ?? 0}', icon: Icons.school_rounded, color: const Color(0xFF667EEA)),
          KpiCard(title: 'Active Teachers', value: '${_data?['active_teachers'] ?? 0}', icon: Icons.person_rounded, color: const Color(0xFF43E97B)),
          KpiCard(title: 'Video Completion', value: '${_data?['overall_video_completion'] ?? 0}%', icon: Icons.play_circle_rounded, color: const Color(0xFFFF6B6B)),
          KpiCard(title: 'Avg Quiz Score', value: '${_data?['average_quiz_score'] ?? 0}', icon: Icons.quiz_rounded, color: const Color(0xFFFF8F00)),
        ],
      );
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GradientIconButton(icon: Icons.how_to_reg_rounded, label: 'Attendance', colors: const [Color(0xFF667EEA), Color(0xFF764BA2)], onTap: () => GoRouter.of(context).push('/principal/attendance')),
              const SizedBox(width: 10),
              GradientIconButton(icon: Icons.people_alt_rounded, label: 'Teachers', colors: const [Color(0xFF43E97B), Color(0xFF38F9D7)], onTap: () => GoRouter.of(context).push('/principal/teachers')),
              const SizedBox(width: 10),
              GradientIconButton(icon: Icons.bar_chart_rounded, label: 'Students', colors: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)], onTap: () => GoRouter.of(context).push('/principal/student-performance')),
              const SizedBox(width: 10),
              GradientIconButton(icon: Icons.pie_chart_rounded, label: 'Classes', colors: const [Color(0xFFA18CD1), Color(0xFFFBC2EB)], onTap: () => GoRouter.of(context).push('/principal/class-performance')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    final status = _data?['subscription_status'] ?? 'none';
    final endDate = _data?['subscription_end_date'] ?? '';
    final amount = _data?['subscription_amount'];
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: (isActive ? const Color(0xFF667EEA) : AppColors.error).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Subscription', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 6),
            Row(children: [
              StatusBadge(label: status.toString().toUpperCase(), color: Colors.white),
              const SizedBox(width: 8),
              if (endDate.isNotEmpty) Text('Expires: $endDate', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
            ]),
            if (amount != null) ...[
              const SizedBox(height: 8),
              Text('₹$amount', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ]),
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF667EEA),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(isActive ? 'Renew' : 'Subscribe', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildTeacherActivity() {
    final teachers = (_data?['teacher_activities'] as List?) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Teacher Activity'),
      ...teachers.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              onTap: () => context.push('/principal/teachers'),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF667EEA).withValues(alpha: 0.1),
                child: Text((t['teacher_name'] ?? 'T')[0], style: GoogleFonts.outfit(color: const Color(0xFF667EEA), fontWeight: FontWeight.w700)),
              ),
              title: Text(t['teacher_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('${t['students_in_classes'] ?? 0} students', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              trailing: StatusBadge(
                label: t['last_login'] != null ? 'Active' : 'Inactive',
                color: t['last_login'] != null ? AppColors.success : AppColors.error,
                showDot: true,
              ),
            ),
          )),
    ]);
  }

  Widget _buildAtRiskStudents() {
    final students = (_data?['students_falling_behind'] as List?) ?? [];
    if (students.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Students Falling Behind', action: 'View All', onAction: () => context.push('/principal/student-performance')),
      GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(children: students.take(5).map((s) => InkWell(
              onTap: () => context.push('/principal/student-performance'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s['name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${s['avg_completion'] ?? 0}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ),
                ]),
              ),
            )).toList()),
      ),
    ]);
  }

  Widget _buildTopStudents() {
    final students = (_data?['top_students'] as List?) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Top 10 Students'),
      ...students.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final medalColors = [
          [const Color(0xFFFFD700), const Color(0xFFFF8F00)],
          [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)],
          [const Color(0xFFCD7F32), const Color(0xFF8D5524)],
        ];
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: i < 3 ? medalColors[i][0].withValues(alpha: 0.2) : Colors.grey.shade100),
            boxShadow: i < 3 ? [BoxShadow(color: medalColors[i][0].withValues(alpha: 0.1), blurRadius: 8)] : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            onTap: () => context.push('/principal/student-performance'),
            leading: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: i < 3 ? LinearGradient(colors: medalColors[i]) : null,
                color: i >= 3 ? AppColors.surfaceVariant : null,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('${i + 1}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: i < 3 ? Colors.white : AppColors.textPrimary))),
            ),
            title: Text(s['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            trailing: Text('${s['avg_score'] ?? 0}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF667EEA))),
          ),
        );
      }),
    ]);
  }
}
