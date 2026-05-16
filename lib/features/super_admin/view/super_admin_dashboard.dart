/// EduCinema LMS — Super Admin Dashboard
/// High-fidelity platform-wide KPIs with gradient hero, animated counters, and premium cards.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});
  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  Map<String, dynamic>? _data;
  bool _loading = true;
  late AnimationController _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _loadDashboard();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await _repo.get('/analytics/platform');
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      debugPrint('[SuperAdminDashboard] API error: $e');
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
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroBanner(),
                        const SizedBox(height: 24),
                        _buildKpiGrid(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildChurnAlerts(),
                        const SizedBox(height: 24),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildRecentPayments()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildNewRegistrations()),
                            ],
                          )
                        else ...[
                          _buildRecentPayments(),
                          const SizedBox(height: 16),
                          _buildNewRegistrations(),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
    final kpis = _data?['kpis'] ?? {};
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(
        opacity: _heroAnim,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF302B63).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Platform Overview', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
                        Text('Real-time insights across all schools', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _hereStat('Schools', '${kpis['total_schools'] ?? 0}', Icons.school_rounded),
                    _hereStat('Students', '${kpis['total_active_students'] ?? 0}', Icons.people_rounded),
                    _hereStat('Revenue MTD', '₹${_formatAmount(kpis['total_revenue_mtd'])}', Icons.trending_up_rounded),
                    _hereStat('Watch Hours', _formatWatchHours(_data?['platform_watch_hours']), Icons.play_circle_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hereStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final kpis = _data?['kpis'] ?? {};
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 800 ? 4 : 2;
        final aspectRatio = constraints.maxWidth > 400 ? 1.5 : 1.3;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: aspectRatio,
          children: [
            KpiCard(title: 'Total Schools', value: '${kpis['total_schools'] ?? 0}', icon: Icons.school_rounded, color: const Color(0xFF667EEA)),
            KpiCard(title: 'Active Subs', value: '${kpis['active_subscriptions'] ?? 0}', icon: Icons.card_membership_rounded, color: const Color(0xFFFF6B6B)),
            KpiCard(title: 'Active Teachers', value: '${kpis['total_active_teachers'] ?? 0}', icon: Icons.person_rounded, color: const Color(0xFF43E97B)),
            KpiCard(title: 'Revenue YTD', value: '₹${_formatAmount(kpis['total_revenue_ytd'])}', icon: Icons.account_balance_rounded, color: const Color(0xFFFF8F00)),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickAction('Schools', Icons.school_rounded, [const Color(0xFF667EEA), const Color(0xFF764BA2)], () => context.go('/admin/schools')),
              const SizedBox(width: 10),
              _quickAction('Content', Icons.video_library_rounded, [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)], () => context.go('/admin/cms')),
              const SizedBox(width: 10),
              _quickAction('Access Control', Icons.lock_person_rounded, [const Color(0xFFFF8F00), const Color(0xFFFFB347)], () => context.go('/admin/content-access')),
              const SizedBox(width: 10),
              _quickAction('Watch Hours', Icons.play_circle_rounded, [const Color(0xFF43E97B), const Color(0xFF38F9D7)], () => context.go('/admin/watch-hours')),
              const SizedBox(width: 10),
              _quickAction('Subscriptions', Icons.card_membership_rounded, [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)], () => context.go('/admin/subscriptions')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon, List<Color> colors, VoidCallback onTap) {
    return GradientIconButton(icon: icon, label: label, colors: colors, onTap: onTap);
  }

  Widget _buildChurnAlerts() {
    final alerts = (_data?['churn_alerts'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Churn Alerts', action: 'View All'),
        if (alerts.isEmpty)
          GlassCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('All Clear!', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('No churn risks detected', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          )
        else
          ...alerts.take(5).map((a) => _buildAlertCard(a)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final days = alert['days_until_expiry'] ?? 0;
    final urgentColor = days <= 7 ? AppColors.error : AppColors.warning;
    return GestureDetector(
      onTap: () => context.go('/admin/subscriptions'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: urgentColor.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: urgentColor.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: urgentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.warning_amber_rounded, color: urgentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert['school_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Expires in $days days • ${alert['tier'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            StatusBadge(label: '$days days', color: urgentColor, showDot: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayments() {
    final payments = (_data?['recent_payments'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Payments'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: payments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No payments yet', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (_, idx) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final p = payments[i];
                    final isSuccess = p['status'] == 'success';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isSuccess ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isSuccess ? Icons.check_rounded : Icons.pending,
                          color: isSuccess ? AppColors.success : AppColors.warning,
                          size: 18,
                        ),
                      ),
                      title: Text(p['school_name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(p['paid_at'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      trailing: Text('₹${p['amount'] ?? 0}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNewRegistrations() {
    final regs = (_data?['new_registrations'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'New Schools'),
        if (regs.isEmpty)
          GlassCard(
            child: Text('No new registrations', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          )
        else
          ...regs.take(5).map((r) => GestureDetector(
                onTap: () => context.go('/admin/schools'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [const Color(0xFF667EEA).withValues(alpha: 0.1), const Color(0xFF764BA2).withValues(alpha: 0.05)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business_rounded, color: Color(0xFF667EEA), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r['school_name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(r['city'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        ]),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    final val = (amount ?? 0).toDouble();
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }

  String _formatWatchHours(dynamic hours) {
    final val = (hours ?? 0).toDouble();
    if (val >= 1) return '${val.toStringAsFixed(1)}h';
    final mins = (val * 60).round();
    return '${mins}m';
  }
}
