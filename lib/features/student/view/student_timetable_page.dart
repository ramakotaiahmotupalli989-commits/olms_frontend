/// EduCinema LMS — Student Timetable Page
/// Students view their class's fixed weekly timetable (read-only).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class StudentTimetablePage extends StatefulWidget {
  const StudentTimetablePage({super.key});
  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  bool _loading = true;
  late TabController _tabController;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  Map<String, List<dynamic>> _timetable = {};

  @override
  void initState() {
    super.initState();
    // Default to today's tab
    int todayIdx = DateTime.now().weekday - 1; // 0=Mon
    if (todayIdx > 5) todayIdx = 0;
    _tabController = TabController(length: 6, vsync: this, initialIndex: todayIdx);
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.get('/student/my-timetable');
      final tt = data['timetable'] as Map<String, dynamic>? ?? {};
      _timetable = {};
      for (var day in _days) {
        _timetable[day] = (tt[day] as List?) ?? [];
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayName = _days[DateTime.now().weekday - 1 > 5 ? 0 : DateTime.now().weekday - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Timetable'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _days.map((d) {
            final isToday = d == todayName;
            return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isToday) Container(
                width: 6, height: 6, margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(color: Color(0xFF43E97B), shape: BoxShape.circle),
              ),
              Text(d.substring(0, 3).toUpperCase()),
            ]));
          }).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _days.map((day) => _buildDayView(day, day == todayName)).toList(),
            ),
    );
  }

  Widget _buildDayView(String day, bool isToday) {
    final periods = _timetable[day] ?? [];
    if (periods.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(isToday ? Icons.weekend_rounded : Icons.event_note_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(isToday ? 'No classes today! 🎉' : 'No classes on $day', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: periods.length,
        itemBuilder: (_, i) => _buildPeriodCard(periods[i], i, isToday),
      ),
    );
  }

  Widget _buildPeriodCard(dynamic period, int index, bool isToday) {
    final subjectName = period['subject_name'] ?? '';
    final teacherName = period['teacher_name'] ?? '';
    final startTime = period['start_time'] ?? '';
    final endTime = period['end_time'] ?? '';
    final room = period['room'] ?? '';
    final periodNum = period['period_number'] ?? (index + 1);

    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
      [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)],
      [const Color(0xFF89F7FE), const Color(0xFF66A6FF)],
    ];
    final colors = gradients[index % gradients.length];

    // Check if current period (only on today's tab)
    bool isCurrent = false;
    if (isToday && startTime.isNotEmpty && endTime.isNotEmpty) {
      final now = TimeOfDay.now();
      final parts = startTime.split(':');
      final endParts = endTime.split(':');
      if (parts.length == 2 && endParts.length == 2) {
        final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        final nowMinutes = now.hour * 60 + now.minute;
        isCurrent = nowMinutes >= startMinutes && nowMinutes < endMinutes;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isCurrent ? colors[0] : colors[0].withValues(alpha: 0.12), width: isCurrent ? 2 : 1),
        boxShadow: [
          if (isCurrent) BoxShadow(color: colors[0].withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          // Period badge
          Container(
            width: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('P$periodNum', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              if (startTime.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(startTime, style: GoogleFonts.inter(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(subjectName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
                  if (isCurrent) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('NOW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 10, runSpacing: 4, children: [
                  if (teacherName.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(teacherName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  if (startTime.isNotEmpty && endTime.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('$startTime – $endTime', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  if (room.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.meeting_room_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(room, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
