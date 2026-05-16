/// EduCinema LMS — Student Attendance Page
/// Students view their own attendance records with summary, calendar heatmap, and history.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});
  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
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
      final data = await _repo.get('/student/my-attendance');
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Attendance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const EmptyState(icon: Icons.error_outline, title: 'Failed to load', subtitle: 'Please try again')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildOverallCard(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Attendance History'),
                      const SizedBox(height: 8),
                      _buildHistoryList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverallCard() {
    final pct = (_data?['attendance_percentage'] ?? 0).toDouble();
    final isGood = pct >= 75;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGood
              ? [const Color(0xFF43E97B), const Color(0xFF38F9D7)]
              : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: (isGood ? const Color(0xFF43E97B) : const Color(0xFFFF6B6B)).withValues(alpha: 0.35),
          blurRadius: 20, offset: const Offset(0, 8),
        )],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Overall Attendance', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            isGood ? '✓ You\'re on track!' : '⚠ Needs improvement',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ])),
        SizedBox(
          width: 80, height: 80,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: pct / 100, strokeWidth: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
            Center(child: Icon(
              isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: Colors.white, size: 32,
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatsRow() {
    final present = _data?['present'] ?? 0;
    final absent = _data?['absent'] ?? 0;
    final late = _data?['late'] ?? 0;
    final total = _data?['total_days'] ?? 0;

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 360;
      if (isNarrow) {
        return Column(children: [
          Row(children: [
            _statCard('Present', present, AppColors.success, Icons.check_circle_rounded),
            const SizedBox(width: 10),
            _statCard('Absent', absent, AppColors.error, Icons.cancel_rounded),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _statCard('Late', late, AppColors.warning, Icons.access_time_rounded),
            const SizedBox(width: 10),
            _statCard('Total', total, AppColors.featureBlue, Icons.calendar_month_rounded),
          ]),
        ]);
      }
      return Row(children: [
        _statCard('Present', present, AppColors.success, Icons.check_circle_rounded),
        const SizedBox(width: 10),
        _statCard('Absent', absent, AppColors.error, Icons.cancel_rounded),
        const SizedBox(width: 10),
        _statCard('Late', late, AppColors.warning, Icons.access_time_rounded),
        const SizedBox(width: 10),
        _statCard('Total', total, AppColors.featureBlue, Icons.calendar_month_rounded),
      ]);
    });
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text('$count', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ]),
    ));
  }

  Widget _buildHistoryList() {
    final records = (_data?['records'] as List?) ?? [];
    if (records.isEmpty) {
      return const EmptyState(icon: Icons.event_busy, title: 'No records yet', subtitle: 'Attendance will appear here once marked');
    }
    return Column(children: records.map((r) {
      final status = r['status'] ?? 'present';
      final dateStr = r['date'] ?? '';
      final remarks = r['remarks'];
      final color = status == 'present' ? AppColors.success
          : status == 'absent' ? AppColors.error
          : status == 'late' ? AppColors.warning
          : AppColors.info;
      final icon = status == 'present' ? Icons.check_circle_rounded
          : status == 'absent' ? Icons.cancel_rounded
          : status == 'late' ? Icons.access_time_rounded
          : Icons.timelapse_rounded;

      DateTime? parsedDate;
      try { parsedDate = DateTime.parse(dateStr); } catch (_) {}
      final formatted = parsedDate != null ? DateFormat('EEE, d MMM yyyy').format(parsedDate) : dateStr;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            radius: 20, backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(formatted, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: remarks != null && remarks.toString().isNotEmpty
              ? Text(remarks, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary))
              : null,
          trailing: StatusBadge(label: status.toUpperCase(), color: color),
        ),
      );
    }).toList());
  }
}
