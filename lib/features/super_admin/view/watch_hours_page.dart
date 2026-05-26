/// EduCinema LMS — Watch Hours Analytics (Super Admin)
/// Platform-wide and per-school watch hours with student-level drill-down.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class WatchHoursPage extends StatefulWidget {
  const WatchHoursPage({super.key});
  @override
  State<WatchHoursPage> createState() => _WatchHoursPageState();
}

class _WatchHoursPageState extends State<WatchHoursPage> {
  final _repo = ApiRepository();
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.get('/analytics/watch-hours');
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      debugPrint('[WatchHours] Error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Watch Hours Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const EmptyState(icon: Icons.error_outline, title: 'Failed to load data', subtitle: 'Pull to refresh')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlatformSummary(),
                        const SizedBox(height: 24),
                        _buildSchoolTable(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPlatformSummary() {
    final totalHours = _data?['platform_total_watch_hours'] ?? 0;
    final totalViewers = _data?['total_viewers'] ?? 0;
    final avgHours = _data?['avg_hours_per_student'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Flexible(
                child: Text('Platform Watch Hours', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _summaryKpi('Total Hours', _formatHours(totalHours), Icons.timer_rounded)),
              Expanded(child: _summaryKpi('Total Viewers', '$totalViewers', Icons.people_rounded)),
              Expanded(child: _summaryKpi('Avg/Student', _formatHours(avgHours), Icons.person_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryKpi(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSchoolTable() {
    final schools = (_data?['schools'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text('Watch Hours by School', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (schools.isEmpty)
          const EmptyState(icon: Icons.play_disabled, title: 'No watch data', subtitle: 'Students haven\'t watched any videos yet')
        else
          ...schools.map((s) => _buildSchoolCard(s)),
      ],
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> s) {
    final hours = _parseToDouble(s['total_watch_hours']);
    final viewers = s['active_viewers'] ?? 0;
    final avgHrs = _parseToDouble(s['avg_hours_per_student']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showSchoolStudents(
            _parseToInt(s['school_id']),
            s['school_name']?.toString() ?? '',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank circle with hours
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hours > 0
                          ? [const Color(0xFF43E97B), const Color(0xFF38F9D7)]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _formatHours(hours),
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // School info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['school_name'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(s['city'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(children: [
                      const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('$viewers viewers', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.speed_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${_formatHours(avgHrs)}/student', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ]),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Drill-down: show per-student watch hours for a school
  Future<void> _showSchoolStudents(int schoolId, String schoolName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await _repo.get('/analytics/watch-hours/school/$schoolId');
      if (mounted) Navigator.pop(context); // dismiss loading

      final students = (data['students'] as List?) ?? [];
      final schoolTotal = data['school_total_watch_hours'] ?? 0;

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            builder: (ctx, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(schoolName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Total: ${_formatHours(schoolTotal)} • ${students.length} students',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Student list
                  Expanded(
                    child: students.isEmpty
                        ? const Center(child: Text('No watch data for this school'))
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: students.length,
                            itemBuilder: (_, i) {
                              final st = students[i];
                              final hrs = _parseToDouble(st['total_watch_hours']);
                              final videos = st['videos_watched'] ?? 0;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: hrs > 0 ? AppColors.accent.withValues(alpha: 0.1) : Colors.grey.shade100,
                                  child: Text('${i + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: hrs > 0 ? AppColors.accent : Colors.grey)),
                                ),
                                title: Text(st['student_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: Text('${st['roll_number'] ?? 'N/A'} • $videos videos watched', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hrs > 0 ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatHours(hrs),
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: hrs > 0 ? AppColors.success : Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatHours(dynamic value) {
    final hours = _parseToDouble(value);
    if (hours >= 1) return '${hours.toStringAsFixed(1)}h';
    final mins = (hours * 60).round();
    return '${mins}m';
  }
}
