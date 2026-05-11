/// EduCinema LMS — Attendance Management Page
/// Principal-only interface for marking teacher attendance with history records.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class AttendanceManagementPage extends StatefulWidget {
  const AttendanceManagementPage({super.key});

  @override
  State<AttendanceManagementPage> createState() => _AttendanceManagementPageState();
}

class _AttendanceManagementPageState extends State<AttendanceManagementPage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  late TabController _tabController;
  bool _loading = true;
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _users = [];
  final Map<int, String> _attendanceStatus = {};
  final Map<int, String> _remarks = {};

  // History
  List<dynamic> _historyRecords = [];
  bool _historyLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _historyRecords.isEmpty) {
        _loadHistory();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _users = await _repo.getList('/principal/teachers');

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final existingAttn = await _repo.getList(
        '/principal/attendance/teachers',
        params: {'date': dateStr},
      );

      _attendanceStatus.clear();
      _remarks.clear();
      for (var record in existingAttn) {
        _attendanceStatus[record['user_id']] = record['status'];
        if (record['remarks'] != null) {
          _remarks[record['user_id']] = record['remarks'];
        }
      }

      for (var user in _users) {
        if (!_attendanceStatus.containsKey(user['id'])) {
          _attendanceStatus[user['id']] = 'present';
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[Attendance] Load error: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      _historyRecords = await _repo.getList('/principal/attendance/teachers');
      setState(() => _historyLoading = false);
    } catch (e) {
      debugPrint('[Attendance] History error: $e');
      setState(() => _historyLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _saving = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final records = <Map<String, dynamic>>[];
      for (var u in _users) {
        records.add({
          'user_id': u['id'],
          'status': _attendanceStatus[u['id']] ?? 'present',
          'remarks': _remarks[u['id']],
        });
      }

      await _repo.post('/principal/attendance/teachers', data: {
        'date': dateStr,
        'records': records,
      });

      setState(() => _saving = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            title: Text('Attendance Saved', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            content: Text(
              'Attendance for ${DateFormat('d MMMM yyyy').format(_selectedDate)} has been recorded successfully.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        // Refresh history
        _loadHistory();
      }
    } catch (e) {
      debugPrint('[Attendance] Save error: $e');
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teacher Attendance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mark Attendance'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarkTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ── Mark Attendance Tab ──
  Widget _buildMarkTab() {
    return Column(
      children: [
        _buildDateSelector(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No teachers found',
                      subtitle: 'Add teachers to start tracking attendance',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) => _buildUserCard(_users[index]),
                    ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() => _selectedDate = picked);
                _loadData();
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final status = _attendanceStatus[user['id']] ?? 'present';
    final userId = user['id'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (user['name'] ?? 'T')[0].toUpperCase(),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
            title: Text(
              user['name'] ?? '',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(user['email'] ?? '', style: GoogleFonts.inter(fontSize: 12)),
            trailing: _buildStatusSelector(userId, status),
          ),
          if (status != 'present')
            Padding(
              padding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
              child: TextField(
                onChanged: (val) => _remarks[userId] = val,
                decoration: InputDecoration(
                  hintText: 'Add remarks (optional)...',
                  hintStyle: GoogleFonts.inter(fontSize: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(int userId, String currentStatus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusIcon(userId, 'present', Icons.check_circle_rounded, AppColors.success, currentStatus == 'present'),
        const SizedBox(width: 8),
        _statusIcon(userId, 'absent', Icons.cancel_rounded, AppColors.error, currentStatus == 'absent'),
        const SizedBox(width: 8),
        _statusIcon(userId, 'late', Icons.access_time_filled_rounded, AppColors.warning, currentStatus == 'late'),
      ],
    );
  }

  Widget _statusIcon(int userId, String status, IconData icon, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _attendanceStatus[userId] = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    int present = _attendanceStatus.values.where((v) => v == 'present').length;
    int absent = _attendanceStatus.values.where((v) => v == 'absent').length;
    int late = _attendanceStatus.values.where((v) => v == 'late').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _summaryItem('Present', present, AppColors.success),
            const SizedBox(width: 16),
            _summaryItem('Absent', absent, AppColors.error),
            const SizedBox(width: 16),
            _summaryItem('Late', late, AppColors.warning),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveAttendance,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ── History Tab ──
  Widget _buildHistoryTab() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyRecords.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No records yet',
        subtitle: 'Attendance records will appear here after you save them',
      );
    }

    // Group records by date
    final Map<String, List<dynamic>> grouped = {};
    for (var r in _historyRecords) {
      final date = r['date'] ?? 'Unknown';
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(r);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateStr = sortedDates[index];
          final records = grouped[dateStr]!;
          final presentCount = records.where((r) => r['status'] == 'present').length;
          final absentCount = records.where((r) => r['status'] == 'absent').length;
          final lateCount = records.where((r) => r['status'] == 'late').length;

          DateTime? parsedDate;
          try {
            parsedDate = DateTime.parse(dateStr);
          } catch (_) {}

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
              ),
              title: Text(
                parsedDate != null ? DateFormat('EEEE, d MMM yyyy').format(parsedDate) : dateStr,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Row(
                children: [
                  _historyBadge('$presentCount P', AppColors.success),
                  const SizedBox(width: 6),
                  _historyBadge('$absentCount A', AppColors.error),
                  const SizedBox(width: 6),
                  _historyBadge('$lateCount L', AppColors.warning),
                ],
              ),
              children: records.map<Widget>((r) {
                final userName = _users.firstWhere(
                  (u) => u['id'] == r['user_id'],
                  orElse: () => {'name': 'User #${r['user_id']}'},
                )['name'];
                final status = r['status'] ?? 'present';
                final statusColor = status == 'present'
                    ? AppColors.success
                    : status == 'absent'
                        ? AppColors.error
                        : AppColors.warning;

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(
                      status == 'present'
                          ? Icons.check_rounded
                          : status == 'absent'
                              ? Icons.close_rounded
                              : Icons.access_time_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                  ),
                  title: Text(userName ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  trailing: StatusBadge(
                    label: status.toString().toUpperCase(),
                    color: statusColor,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _historyBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
