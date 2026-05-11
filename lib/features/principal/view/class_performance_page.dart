/// EduCinema LMS — Class Performance Page (Principal/Admin)
/// View average class-level performance with pie charts, bar charts, and KPIs.
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ClassPerformancePage extends StatefulWidget {
  const ClassPerformancePage({super.key});

  @override
  State<ClassPerformancePage> createState() => _ClassPerformancePageState();
}

class _ClassPerformancePageState extends State<ClassPerformancePage> {
  final _repo = ApiRepository();
  bool _loadingClasses = true;
  bool _loadingPerformance = false;
  List<dynamic> _classes = [];
  Map<String, dynamic>? _perfData;
  int? _selectedClassId;

  static const _bandColors = [
    Color(0xFF4CAF50), // 90-100%
    Color(0xFF2196F3), // 80-90%
    Color(0xFFFFC107), // 60-80%
    Color(0xFFFF9800), // 40-60%
    Color(0xFFE53935), // 0-40%
  ];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      _classes = await _repo.getList('/principal/classes');
      setState(() => _loadingClasses = false);

      // Auto-select first class if available
      if (_classes.isNotEmpty) {
        _loadPerformance(_classes[0]['id']);
      }
    } catch (e) {
      setState(() => _loadingClasses = false);
    }
  }

  Future<void> _loadPerformance(int classId) async {
    setState(() {
      _selectedClassId = classId;
      _loadingPerformance = true;
    });
    try {
      final data = await _repo.get('/principal/class/$classId/performance');
      setState(() {
        _perfData = data;
        _loadingPerformance = false;
      });
    } catch (e) {
      setState(() => _loadingPerformance = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading class performance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Class Performance')),
      body: _loadingClasses
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const Center(
                  child: EmptyState(
                    icon: Icons.class_rounded,
                    title: 'No classes found',
                    subtitle: 'Create classes to view performance analytics',
                  ),
                )
              : Column(
                  children: [
                    _buildClassSelector(),
                    Expanded(child: _buildPerformanceContent()),
                  ],
                ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _classes.map((c) {
            final isSelected = c['id'] == _selectedClassId;
            final label = 'Class ${c['grade']}${c['section'] != null ? ' - ${c['section']}' : ''}';
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ChoiceChip(
                  label: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _loadPerformance(c['id']),
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPerformanceContent() {
    if (_loadingPerformance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_perfData == null) {
      return const Center(
        child: EmptyState(
          icon: Icons.bar_chart_rounded,
          title: 'Select a class',
          subtitle: 'Choose a class to view its performance analytics',
        ),
      );
    }

    final classInfo = _perfData!['class_info'] as Map<String, dynamic>? ?? {};
    final overall = _perfData!['overall'] as Map<String, dynamic>? ?? {};
    final distribution = (_perfData!['score_distribution'] as List?) ?? [];
    final subjectScores = (_perfData!['subject_scores'] as List?) ?? [];
    final subjectCompletion = (_perfData!['subject_completion'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: () => _loadPerformance(_selectedClassId!),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Header
            _buildClassHeader(classInfo, overall),
            const SizedBox(height: 24),

            // KPI Cards
            _buildKpiRow(overall, classInfo),
            const SizedBox(height: 24),

            // Score Distribution Pie Chart
            if (distribution.isNotEmpty) ...[
              _buildScoreDistributionCard(distribution),
              const SizedBox(height: 24),
            ],

            // Subject-wise Bar Chart
            if (subjectScores.isNotEmpty) ...[
              _buildSubjectScoresChart(subjectScores),
              const SizedBox(height: 24),
            ],

            // Video Completion
            if (subjectCompletion.isNotEmpty) ...[
              _buildVideoCompletionCard(subjectCompletion),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassHeader(Map<String, dynamic> classInfo, Map<String, dynamic> overall) {
    final grade = classInfo['grade'] ?? '';
    final section = classInfo['section'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.class_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class $grade${section != null ? ' — Section $section' : ''}',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${classInfo['total_students'] ?? 0} students • ${overall['total_quiz_attempts'] ?? 0} quiz attempts',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${overall['class_average'] ?? 0}%',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text('Class Avg', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> overall, Map<String, dynamic> classInfo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          _kpiCard('Students', '${classInfo['total_students'] ?? 0}', Icons.people_rounded, AppColors.primary),
          _kpiCard('Class Average', '${overall['class_average'] ?? 0}%', Icons.trending_up_rounded, AppColors.success),
          _kpiCard('Highest Score', '${overall['highest_score'] ?? 0}%', Icons.emoji_events_rounded, const Color(0xFFFFB300)),
          _kpiCard('Lowest Score', '${overall['lowest_score'] ?? 0}%', Icons.trending_down_rounded, AppColors.error),
        ];
        if (isWide) {
          return Row(
            children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
          );
        }
        return Wrap(
          spacing: 12, runSpacing: 12,
          children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: c)).toList(),
        );
      },
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildScoreDistributionCard(List<dynamic> distribution) {
    final total = distribution.fold<int>(0, (sum, d) => sum + ((d['count'] ?? 0) as int));
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score Distribution', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Center(child: Text('No quiz data available yet')),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score Distribution', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Class-wide quiz score distribution', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              if (isWide) {
                return Row(
                  children: [
                    SizedBox(width: 200, height: 200, child: _buildPieChart(distribution, total)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildLegend(distribution, total)),
                  ],
                );
              }
              return Column(
                children: [
                  SizedBox(width: 200, height: 200, child: _buildPieChart(distribution, total)),
                  const SizedBox(height: 20),
                  _buildLegend(distribution, total),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<dynamic> distribution, int total) {
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 40,
        sections: distribution.asMap().entries.where((e) => (e.value['count'] ?? 0) > 0).map((e) {
          final i = e.key;
          final d = e.value;
          final count = (d['count'] ?? 0) as int;
          final percent = count / total * 100;
          return PieChartSectionData(
            color: _bandColors[i % _bandColors.length],
            value: count.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
            radius: 50,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(List<dynamic> distribution, int total) {
    return Column(
      children: distribution.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value;
        final count = (d['count'] ?? 0) as int;
        final percent = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(color: _bandColors[i % _bandColors.length], borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              Text(d['band'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('$count attempts ($percent%)', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectScoresChart(List<dynamic> subjectScores) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subject-wise Average Scores', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Class average quiz scores per subject', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final subj = subjectScores[groupIndex];
                      return BarTooltipItem(
                        '${subj['subject']}\n${subj['percentage']}%',
                        GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= subjectScores.length) return const SizedBox.shrink();
                        final name = (subjectScores[idx]['subject'] ?? '') as String;
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            name.length > 6 ? '${name.substring(0, 6)}...' : name,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: subjectScores.asMap().entries.map((e) {
                  final pct = (e.value['percentage'] ?? 0).toDouble();
                  final color = pct >= 80 ? const Color(0xFF4CAF50) : pct >= 60 ? const Color(0xFFFFC107) : const Color(0xFFE53935);
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: pct,
                        color: color,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCompletionCard(List<dynamic> subjectCompletion) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Average Video Completion', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Class-wide average video watch completion per subject', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...subjectCompletion.map((s) {
            final pct = (s['avg_completion'] ?? 0).toDouble();
            final color = pct >= 80 ? AppColors.success : pct >= 50 ? AppColors.warning : AppColors.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s['subject'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
