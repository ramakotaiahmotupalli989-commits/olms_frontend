/// EduCinema LMS — Teacher Attendance Page
/// Premium UI for teachers to mark student attendance per class.
/// Auto-notifies parents of absent students via in-app notification.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  late TabController _tabController;

  bool _loading = true;
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();

  List<dynamic> _classes = [];
  int? _selectedClassId;
  List<dynamic> _students = [];
  final Map<int, String> _attendanceStatus = {};
  final Map<int, String> _remarks = {};

  // History
  List<dynamic> _historyRecords = [];
  bool _historyLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _loading = true);
    try {
      _classes = await _repo.getList('/teacher/attendance/classes');
      if (_classes.isNotEmpty) {
        _selectedClassId = _classes[0]['class_id'];
        await _loadStudents();
      }
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[TeacherAttendance] Load classes error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final data = await _repo.get(
        '/teacher/attendance/class/$_selectedClassId',
        params: {'date': dateStr},
      );

      _students = (data['students'] as List?) ?? [];
      _attendanceStatus.clear();
      _remarks.clear();

      for (var s in _students) {
        final sid = s['student_id'] as int;
        _attendanceStatus[sid] = s['status'] ?? 'present';
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[TeacherAttendance] Load students error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadHistory() async {
    if (_selectedClassId == null) return;
    setState(() => _historyLoading = true);
    try {
      final data = await _repo.getList(
        '/teacher/attendance/class/$_selectedClassId/summary',
      );
      _historyRecords = data;
      setState(() => _historyLoading = false);
    } catch (e) {
      debugPrint('[TeacherAttendance] History error: $e');
      setState(() => _historyLoading = false);
    }
  }

  void _markAllPresent() {
    setState(() {
      for (var s in _students) {
        _attendanceStatus[s['student_id'] as int] = 'present';
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _saving = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final records = <Map<String, dynamic>>[];
      for (var s in _students) {
        final sid = s['student_id'] as int;
        records.add({
          'user_id': sid,
          'status': _attendanceStatus[sid] ?? 'present',
          'remarks': _remarks[sid],
        });
      }

      final result = await _repo.post(
        '/teacher/attendance/class/$_selectedClassId',
        data: {'date': dateStr, 'records': records},
      );

      setState(() => _saving = false);
      if (mounted) {
        final absentCount = result['absent_count'] ?? 0;
        final notifCount = result['parent_notifications_sent'] ?? 0;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 52),
            title: Text('Attendance Saved', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Attendance for ${DateFormat('d MMMM yyyy').format(_selectedDate)} recorded.',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (absentCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$notifCount parent notification${notifCount == 1 ? '' : 's'} sent for $absentCount absent student${absentCount == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _loadHistory();
      }
    } catch (e) {
      debugPrint('[TeacherAttendance] Save error: $e');
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Attendance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mark Attendance'),
            Tab(text: 'Summary'),
          ],
          onTap: (index) {
            if (index == 1 && _historyRecords.isEmpty) {
              _loadHistory();
            }
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarkTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildMarkTab() {
    return Column(
      children: [
        _buildClassSelector(),
        _buildDateSelector(),
        _buildQuickActions(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No students found',
                      subtitle: 'Select a class or add students to get started',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) => _buildStudentCard(_students[index]),
                    ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildClassSelector() {
    if (_classes.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.featureBlue, AppColors.featurePurple]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedClassId,
                isExpanded: true,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                items: _classes.map<DropdownMenuItem<int>>((c) {
                  final label = 'Class ${c['grade']}${c['section'] != null ? ' - ${c['section']}' : ''} (${c['student_count']} students)';
                  return DropdownMenuItem(value: c['class_id'] as int, child: Text(label));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedClassId = val);
                  _loadStudents();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() => _selectedDate = picked);
                _loadStudents();
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
            label: Text('Mark All Present', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            onPressed: _markAllPresent,
            backgroundColor: AppColors.success.withValues(alpha: 0.08),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 8),
          Text(
            '${_students.length} students',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final sid = student['student_id'] as int;
    final status = _attendanceStatus[sid] ?? 'present';
    final name = student['student_name'] ?? '';
    final roll = student['roll_number'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'absent'
              ? AppColors.error.withValues(alpha: 0.3)
              : status == 'late'
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : Colors.grey.shade100,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: status == 'absent'
                  ? AppColors.error.withValues(alpha: 0.1)
                  : status == 'late'
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: status == 'absent' ? AppColors.error : status == 'late' ? AppColors.warning : AppColors.success,
                ),
              ),
            ),
            title: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: roll.isNotEmpty
                ? Text('Roll: $roll', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary))
                : null,
            trailing: _buildStatusSelector(sid, status),
          ),
          if (status != 'present')
            Padding(
              padding: const EdgeInsets.only(left: 60, right: 14, bottom: 12),
              child: TextField(
                onChanged: (val) => _remarks[sid] = val,
                decoration: InputDecoration(
                  hintText: 'Add remarks (optional)...',
                  hintStyle: GoogleFonts.inter(fontSize: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(int sid, String currentStatus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusChip(sid, 'present', 'P', AppColors.success, currentStatus == 'present'),
        const SizedBox(width: 6),
        _statusChip(sid, 'absent', 'A', AppColors.error, currentStatus == 'absent'),
        const SizedBox(width: 6),
        _statusChip(sid, 'late', 'L', AppColors.warning, currentStatus == 'late'),
      ],
    );
  }

  Widget _statusChip(int sid, String status, String label, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _attendanceStatus[sid] = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 0 : 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    int present = _attendanceStatus.values.where((v) => v == 'present').length;
    int absent = _attendanceStatus.values.where((v) => v == 'absent').length;
    int late = _attendanceStatus.values.where((v) => v == 'late').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _summaryChip('Present', present, AppColors.success),
            const SizedBox(width: 6),
            _summaryChip('Absent', absent, AppColors.error),
            const SizedBox(width: 6),
            _summaryChip('Late', late, AppColors.warning),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saving || _students.isEmpty ? null : _saveAttendance,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_saving ? 'Saving...' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Summary Tab ──
  Widget _buildSummaryTab() {
    if (_historyLoading) return const Center(child: CircularProgressIndicator());
    if (_historyRecords.isEmpty) {
      return EmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'No attendance data yet',
        subtitle: 'Mark attendance to see summary reports here',
        action: ElevatedButton(
          onPressed: _loadHistory,
          child: const Text('Refresh'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyRecords.length,
        itemBuilder: (context, index) {
          final record = _historyRecords[index];
          final pct = (record['attendance_percentage'] ?? 0.0).toDouble();
          final name = record['student_name'] ?? '';
          final roll = record['roll_number'] ?? '';
          final present = record['present'] ?? 0;
          final absent = record['absent'] ?? 0;
          final late = record['late'] ?? 0;
          final total = record['total_days'] ?? 0;

          final pctColor = pct >= 85 ? AppColors.success : pct >= 70 ? AppColors.warning : AppColors.error;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: pctColor.withValues(alpha: 0.1),
                  child: Text(
                    '${pct.toInt()}%',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: pctColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      if (roll.isNotEmpty)
                        Text('Roll: $roll', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _miniStat('P', present, AppColors.success),
                    const SizedBox(width: 6),
                    _miniStat('A', absent, AppColors.error),
                    const SizedBox(width: 6),
                    _miniStat('L', late, AppColors.warning),
                    const SizedBox(width: 6),
                    _miniStat('T', total, AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
