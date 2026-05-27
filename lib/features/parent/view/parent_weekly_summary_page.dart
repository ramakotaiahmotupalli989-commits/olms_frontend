/// EduCinema LMS — Parent Weekly Summary Page
/// Weekly learning activity overview: watch time, quizzes, class comparison.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ParentWeeklySummaryPage extends StatefulWidget {
  const ParentWeeklySummaryPage({super.key});
  @override
  State<ParentWeeklySummaryPage> createState() => _ParentWeeklySummaryPageState();
}

class _ParentWeeklySummaryPageState extends State<ParentWeeklySummaryPage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  List<dynamic> _children = [];
  int? _selectedChildId;
  Map<String, dynamic>? _summary;
  List<dynamic> _videoProgress = [];
  bool _loading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadChildren();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    try {
      final data = await _repo.get('/parent/dashboard');
      final children = (data['children'] as List?) ?? [];
      final child = data['child'] as Map<String, dynamic>?;

      setState(() {
        _children = children;
        _selectedChildId = child?['id'] as int?;
      });

      if (_selectedChildId != null) {
        await _loadSummary(_selectedChildId!);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSummary(int childId) async {
    setState(() => _loading = true);
    try {
      final summary = await _repo.get('/parent/child/$childId/weekly-summary');
      List<dynamic> videos = [];
      try {
        videos = await _repo.getList('/parent/child/$childId/video-progress');
      } catch (_) {}

      setState(() {
        _summary = summary;
        _videoProgress = videos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _switchChild(int childId) async {
    setState(() => _selectedChildId = childId);
    await _loadSummary(childId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadSummary(_selectedChildId ?? 0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
                        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
                      ),
                      child: FadeTransition(
                        opacity: _animController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Summary',
                              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last 7 days learning activity',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Child switcher
                    if (_children.length > 1) ...[
                      _buildChildSwitcher(),
                      const SizedBox(height: 20),
                    ],

                    if (_summary == null)
                      const EmptyState(
                        icon: Icons.analytics_rounded,
                        title: 'No Activity Yet',
                        subtitle: 'Weekly learning data will appear here once your child starts learning.',
                      )
                    else ...[
                      // Activity hero card
                      _buildActivityHero(),
                      const SizedBox(height: 20),

                      // KPI cards
                      _buildKpiGrid(),
                      const SizedBox(height: 24),

                      // Class comparison
                      _buildClassComparison(),
                      const SizedBox(height: 24),

                      // Subject breakdown
                      if (_videoProgress.isNotEmpty) ...[
                        const SectionHeader(title: 'Subject Breakdown'),
                        ..._videoProgress.map((s) => _buildSubjectBar(s)),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChildSwitcher() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _children.length,
        itemBuilder: (_, i) {
          final c = _children[i];
          final selected = c['id'] == _selectedChildId;
          return GestureDetector(
            onTap: () => _switchChild(c['id']),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)])
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: selected ? null : Border.all(color: Colors.grey.shade200),
                boxShadow: selected
                    ? [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Text(
                c['name'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityHero() {
    final totalMins = (_summary?['week_total_minutes'] ?? 0).toDouble();
    final hours = (totalMins / 60).floor();
    final mins = (totalMins % 60).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Watch Time This Week', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      if (hours > 0) ...[
                        TextSpan(
                          text: '$hours',
                          style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        TextSpan(
                          text: 'h ',
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white70),
                        ),
                      ],
                      TextSpan(
                        text: '$mins',
                        style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      TextSpan(
                        text: 'm',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalMins > 120 ? 'Active learner! \u{1F31F}' : totalMins > 30 ? 'Good start! \u{1F44D}' : 'Encourage more learning',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final videosWatched = _summary?['videos_watched'] ?? 0;
    final quizzesTaken = _summary?['quizzes_taken'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            'Videos Watched',
            videosWatched.toString(),
            Icons.ondemand_video_rounded,
            const Color(0xFF4ECDC4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKpiCard(
            'Quizzes Taken',
            quizzesTaken.toString(),
            Icons.quiz_rounded,
            const Color(0xFFFF6B6B),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildClassComparison() {
    final childAvg = (_summary?['child_avg_score'] ?? 0).toDouble();
    final classAvg = (_summary?['class_avg_score'] ?? 0).toDouble();
    final comparison = _summary?['comparison'] ?? 'equal';

    Color compColor;
    IconData compIcon;
    String compLabel;

    switch (comparison) {
      case 'above':
        compColor = AppColors.success;
        compIcon = Icons.trending_up_rounded;
        compLabel = 'Above class average!';
        break;
      case 'below':
        compColor = AppColors.error;
        compIcon = Icons.trending_down_rounded;
        compLabel = 'Below class average';
        break;
      default:
        compColor = AppColors.info;
        compIcon = Icons.trending_flat_rounded;
        compLabel = 'At class average';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: compColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(compIcon, color: compColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Class Comparison',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${childAvg.toStringAsFixed(1)}',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: compColor),
                    ),
                    Text('Your Child', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: compColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  compLabel,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: compColor),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${classAvg.toStringAsFixed(1)}',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                    ),
                    Text('Class Avg', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBar(dynamic subject) {
    final name = subject['subject'] ?? '';
    final pct = (subject['completion_percent'] ?? 0).toDouble();
    final color = pct >= 70 ? AppColors.success : pct >= 40 ? AppColors.warning : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LabeledProgressBar(
        label: name,
        value: pct / 100,
        color: color,
      ),
    );
  }
}
