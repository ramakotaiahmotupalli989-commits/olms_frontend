/// EduCinema LMS — Student Performance Page (Principal/Admin)
/// View individual student's marks & performance with pie charts and bar charts.
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class StudentPerformancePage extends StatefulWidget {
  const StudentPerformancePage({super.key});

  @override
  State<StudentPerformancePage> createState() => _StudentPerformancePageState();
}

class _StudentPerformancePageState extends State<StudentPerformancePage> {
  final _repo = ApiRepository();
  bool _loadingStudents = true;
  bool _loadingPerformance = false;
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  Map<String, dynamic>? _perfData;
  int? _selectedStudentId;
  final _searchCtrl = TextEditingController();

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
    _loadStudents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      _students = await _repo.getList('/principal/students');
      _filteredStudents = List.from(_students);
      setState(() => _loadingStudents = false);
    } catch (e) {
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _loadPerformance(int studentId) async {
    setState(() {
      _selectedStudentId = studentId;
      _loadingPerformance = true;
    });
    try {
      final data = await _repo.get('/principal/students/$studentId/performance');
      setState(() {
        _perfData = data;
        _loadingPerformance = false;
      });
    } catch (e) {
      setState(() => _loadingPerformance = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading performance: $e')),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _filteredStudents = _students
          .where((s) => (s['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Student Performance')),
      body: _loadingStudents
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // ── Student List Panel ──
                SizedBox(
                  width: MediaQuery.of(context).size.width > 800 ? 320 : MediaQuery.of(context).size.width * 0.4,
                  child: _buildStudentList(),
                ),
                // ── Performance Panel ──
                Expanded(child: _buildPerformancePanel()),
              ],
            ),
    );
  }

  Widget _buildStudentList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterStudents,
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: GoogleFonts.inter(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ),
          // Student count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredStudents.length} Students',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Student list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final s = _filteredStudents[index];
                final isSelected = s['id'] == _selectedStudentId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
                  ),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        (s['name'] ?? 'S')[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      s['name'] ?? '',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Roll: ${s['roll_number'] ?? 'N/A'}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    onTap: () => _loadPerformance(s['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancePanel() {
    if (_selectedStudentId == null) {
      return const Center(
        child: EmptyState(
          icon: Icons.bar_chart_rounded,
          title: 'Select a student',
          subtitle: 'Choose a student from the list to view their performance',
        ),
      );
    }

    if (_loadingPerformance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_perfData == null) {
      return const Center(child: Text('No data available'));
    }

    final student = _perfData!['student'] as Map<String, dynamic>? ?? {};
    final overall = _perfData!['overall'] as Map<String, dynamic>? ?? {};
    final distribution = (_perfData!['score_distribution'] as List?) ?? [];
    final subjectScores = (_perfData!['subject_scores'] as List?) ?? [];
    final subjectCompletion = (_perfData!['subject_completion'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student header
          _buildStudentHeader(student, overall),
          const SizedBox(height: 24),

          // KPI Cards
          _buildKpiRow(overall),
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
    );
  }

  Widget _buildStudentHeader(Map<String, dynamic> student, Map<String, dynamic> overall) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              (student['name'] ?? 'S')[0].toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? '',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Class ${student['grade'] ?? ''}${student['section'] != null ? ' - ${student['section']}' : ''} • Roll: ${student['roll_number'] ?? 'N/A'}',
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
                  '${overall['average_percentage'] ?? 0}%',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text('Overall Avg', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> overall) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          _kpiCard('Total Quizzes', '${overall['total_quizzes'] ?? 0}', Icons.quiz_rounded, AppColors.primary),
          _kpiCard('Average', '${overall['average_percentage'] ?? 0}%', Icons.trending_up_rounded, AppColors.success),
          _kpiCard('Highest', '${overall['highest_percentage'] ?? 0}%', Icons.emoji_events_rounded, const Color(0xFFFFB300)),
          _kpiCard('Lowest', '${overall['lowest_percentage'] ?? 0}%', Icons.trending_down_rounded, AppColors.error),
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
    if (total == 0) return const SizedBox.shrink();

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
          Text('Quiz performance across all attempts', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
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
              Text('$count quizzes ($percent%)', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
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
          Text('Subject-wise Performance', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Average quiz scores per subject', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
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
          Text('Video Completion by Subject', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Average video watch completion percentage', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
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
