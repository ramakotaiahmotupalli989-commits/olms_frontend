/// EduCinema LMS — Parent Attendance Page
/// View child's attendance history with calendar view and summary stats.
library;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ParentAttendancePage extends StatefulWidget {
  const ParentAttendancePage({super.key});
  @override
  State<ParentAttendancePage> createState() => _ParentAttendancePageState();
}

class _ParentAttendancePageState extends State<ParentAttendancePage> with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _children = [];
  int? _selectedChildId;
  Map<String, dynamic>? _summary;
  List<dynamic> _records = [];
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
      // Get children list from dashboard
      final data = await _repo.get('/parent/dashboard');
      final children = (data['children'] as List?) ?? [];
      final child = data['child'] as Map<String, dynamic>?;

      setState(() {
        _children = children;
        _selectedChildId = child?['id'] as int?;
      });

      if (_selectedChildId != null) {
        await _loadAttendance(_selectedChildId!);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAttendance(int childId) async {
    setState(() => _loading = true);
    try {
      final summary = await _repo.get('/parent/child/$childId/attendance/summary');
      final history = await _repo.getList('/parent/child/$childId/attendance/history');

      setState(() {
        _summary = summary;
        _records = history;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _switchChild(int childId) async {
    setState(() => _selectedChildId = childId);
    await _loadAttendance(childId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadAttendance(_selectedChildId ?? 0),
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
                        child: Text(
                          'Child Attendance',
                          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Child switcher
                    if (_children.length > 1) ...[
                      _buildChildSwitcher(),
                      const SizedBox(height: 20),
                    ],

                    // Summary stats
                    if (_summary != null) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      _buildStatRow(),
                      const SizedBox(height: 24),
                    ],

                    // Attendance history
                    const SectionHeader(title: 'Attendance History'),
                    if (_records.isEmpty)
                      const EmptyState(
                        icon: Icons.how_to_reg_rounded,
                        title: 'No Records Yet',
                        subtitle: 'Attendance records will appear here once marked by the teacher.',
                      )
                    else
                      ..._records.map((r) => _buildAttendanceRecord(r)),
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

  Widget _buildSummaryCard() {
    final pct = (_summary?['attendance_percentage'] ?? 0).toDouble();
    final isGood = pct >= 75;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGood
              ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isGood ? AppColors.success : AppColors.error).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attendance Rate', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  isGood ? 'Great attendance! Keep it up.' : 'Needs improvement. Please check.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.verified_user_rounded : Icons.warning_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Present', _summary?['total_present'] ?? 0, AppColors.success, Icons.check_circle_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Absent', _summary?['total_absent'] ?? 0, AppColors.error, Icons.cancel_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Late', _summary?['total_late'] ?? 0, AppColors.warning, Icons.schedule_rounded)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord(dynamic record) {
    final status = (record['status'] ?? 'absent').toString().toLowerCase();
    final date = record['date'] ?? '';
    final remarks = record['remarks'] as String?;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'present':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Present';
        break;
      case 'late':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule_rounded;
        statusLabel = 'Late';
        break;
      case 'half_day':
        statusColor = AppColors.info;
        statusIcon = Icons.timelapse_rounded;
        statusLabel = 'Half Day';
        break;
      default:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Absent';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.toString(), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                if (remarks != null && remarks.isNotEmpty)
                  Text(remarks, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge(label: statusLabel, color: statusColor),
        ],
      ),
    );
  }
}
