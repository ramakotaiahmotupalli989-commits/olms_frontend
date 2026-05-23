import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ExamLeaderboardBottomSheet extends StatefulWidget {
  final int examId;
  final int classId;
  final String examName;
  final int? currentStudentId;
  final String highlightLabel; // e.g. "You" or "Child"

  const ExamLeaderboardBottomSheet({
    super.key,
    required this.examId,
    required this.classId,
    required this.examName,
    this.currentStudentId,
    this.highlightLabel = 'You',
  });

  static void show(
    BuildContext context, {
    required int examId,
    required int classId,
    required String examName,
    int? currentStudentId,
    String highlightLabel = 'You',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ExamLeaderboardBottomSheet(
          examId: examId,
          classId: classId,
          examName: examName,
          currentStudentId: currentStudentId,
          highlightLabel: highlightLabel,
        ),
      ),
    );
  }

  @override
  State<ExamLeaderboardBottomSheet> createState() => _ExamLeaderboardBottomSheetState();
}

class _ExamLeaderboardBottomSheetState extends State<ExamLeaderboardBottomSheet> {
  final _repo = ApiRepository();
  bool _loading = true;
  String _error = '';
  List<dynamic> _results = [];
  double _avgPct = 0.0;
  int _passCount = 0;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchRankings();
  }

  Future<void> _fetchRankings() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await _repo.get('/exams/${widget.examId}/class/${widget.classId}/results');
      final students = (response['students'] as List?) ?? [];
      
      double totalPct = 0;
      int pass = 0;
      int fail = 0;
      for (var s in students) {
        final pct = (s['percentage'] ?? 0).toDouble();
        totalPct += pct;
        if (pct >= 40.0) {
          pass++;
        } else {
          fail++;
        }
      }

      setState(() {
        _results = students;
        _avgPct = students.isNotEmpty ? (totalPct / students.length) : 0.0;
        _passCount = pass;
        _failCount = fail;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏆 Class Leaderboard',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.examName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text('Failed to load rankings', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(_error, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _fetchRankings, child: const Text('Try Again')),
                            ],
                          ),
                        ),
                      )
                    : _results.isEmpty
                        ? const EmptyState(
                            icon: Icons.leaderboard_rounded,
                            title: 'No rankings yet',
                            subtitle: 'Scores have not been entered for this exam yet.',
                          )
                        : Column(
                            children: [
                              _buildKPIs(),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  itemCount: _results.length,
                                  itemBuilder: (context, index) {
                                    final student = _results[index];
                                    final sid = student['student_id'] as int;
                                    final rank = student['rank'] ?? (index + 1);
                                    final name = student['student_name'] ?? '';
                                    final roll = student['roll_number'] ?? '';
                                    final pct = (student['percentage'] ?? 0).toDouble();
                                    final totalObtained = student['total_obtained'] ?? 0;
                                    final totalMax = student['total_max'] ?? 0;
                                    final isCurrentUser = sid == widget.currentStudentId;

                                    Color medalColor = AppColors.textSecondary;
                                    IconData? medalIcon;
                                    if (rank == 1) {
                                      medalColor = AppColors.gold;
                                      medalIcon = Icons.emoji_events_rounded;
                                    } else if (rank == 2) {
                                      medalColor = AppColors.silver;
                                      medalIcon = Icons.emoji_events_rounded;
                                    } else if (rank == 3) {
                                      medalColor = AppColors.bronze;
                                      medalIcon = Icons.emoji_events_rounded;
                                    }

                                    final pctColor = pct >= 80 ? AppColors.success
                                        : pct >= 60 ? AppColors.info
                                        : pct >= 40 ? AppColors.warning
                                        : AppColors.error;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser
                                            ? AppColors.primary.withValues(alpha: 0.08)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isCurrentUser
                                              ? AppColors.primary.withValues(alpha: 0.4)
                                              : rank <= 3 ? medalColor.withValues(alpha: 0.3) : Colors.grey.shade100,
                                          width: isCurrentUser ? 2 : 1,
                                        ),
                                        boxShadow: rank <= 3
                                            ? [BoxShadow(color: medalColor.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              gradient: rank <= 3
                                                  ? LinearGradient(colors: [medalColor, medalColor.withValues(alpha: 0.6)])
                                                  : null,
                                              color: rank > 3 ? AppColors.surfaceVariant : null,
                                              shape: BoxShape.circle,
                                            ),
                                            child: medalIcon != null
                                                ? Icon(medalIcon, color: Colors.white, size: 18)
                                                : Text(
                                                    '#$rank',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        name,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isCurrentUser) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primary,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          widget.highlightLabel,
                                                          style: GoogleFonts.inter(
                                                            color: Colors.white,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    if (roll.isNotEmpty) ...[
                                                      Text('Roll: $roll', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    Text(
                                                      '${pct.toStringAsFixed(1)}%',
                                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: pctColor),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: pct / 100,
                                                    minHeight: 5,
                                                    backgroundColor: Colors.grey.shade100,
                                                    valueColor: AlwaysStoppedAnimation(pctColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$totalObtained/$totalMax',
                                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                              ),
                                              Text(
                                                'Score',
                                                style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _kpiItem('Avg %', '${_avgPct.toStringAsFixed(1)}%', const Color(0xFF667EEA)),
          _kpiItem('Pass', '$_passCount', AppColors.success),
          _kpiItem('Fail', '$_failCount', AppColors.error),
          _kpiItem('Total', '${_results.length}', AppColors.info),
        ],
      ),
    );
  }

  Widget _kpiItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
