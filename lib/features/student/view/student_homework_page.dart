/// EduCinema LMS — Student Homework Page
/// Students view all homework assignments with subject tabs.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class StudentHomeworkPage extends StatefulWidget {
  const StudentHomeworkPage({super.key});
  @override
  State<StudentHomeworkPage> createState() => _StudentHomeworkPageState();
}

class _StudentHomeworkPageState extends State<StudentHomeworkPage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  bool _loading = true;
  int _totalAssignments = 0;
  List<dynamic> _subjects = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() { _tabController?.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.get('/student/my-homework');
      final subjects = (data['subjects'] as List?) ?? [];
      setState(() {
        _totalAssignments = data['total_assignments'] ?? 0;
        _subjects = subjects;
        _tabController?.dispose();
        _tabController = TabController(length: _subjects.length, vsync: this);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Homework'),
        bottom: _tabController != null && _subjects.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _subjects.map((s) => Tab(text: s['subject_name'] ?? 'General')).toList(),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No homework assigned',
                  subtitle: 'You\'re all caught up! Check back later.',
                )
              : Column(children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: Colors.white,
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text('$_totalAssignments total assignments', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _subjects.map((s) => _buildSubjectTab(s)).toList(),
                    ),
                  ),
                ]),
    );
  }

  Widget _buildSubjectTab(dynamic subject) {
    final assignments = (subject['assignments'] as List?) ?? [];
    if (assignments.isEmpty) {
      return const EmptyState(icon: Icons.check_circle_outline, title: 'No homework', subtitle: 'No assignments for this subject');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: assignments.length,
        itemBuilder: (_, i) => _buildAssignmentCard(assignments[i]),
      ),
    );
  }

  Widget _buildAssignmentCard(dynamic a) {
    final type = a['type'] ?? 'homework';
    final isHomework = type == 'homework';
    final dueDate = a['due_date'] != null ? DateTime.tryParse(a['due_date']) : null;
    final isOverdue = a['is_overdue'] == true;
    final color = isOverdue ? AppColors.error : isHomework ? AppColors.featureBlue : AppColors.featurePurple;

    final gradients = isOverdue
        ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
        : isHomework
            ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
            : [const Color(0xFF4ECDC4), const Color(0xFF44B09E)];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(children: [
        // Header strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradients),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(isHomework ? Icons.home_work_rounded : Icons.edit_note_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(type.toString().toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
            if (isOverdue) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
              child: Text('OVERDUE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['title'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            if (a['description'] != null && a['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(a['description'], style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 6, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(a['teacher_name'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ]),
              if (dueDate != null) Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_rounded, size: 14, color: isOverdue ? AppColors.error : AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d MMM yyyy').format(dueDate),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isOverdue ? AppColors.error : AppColors.textSecondary),
                ),
              ]),
            ]),
          ]),
        ),
      ]),
    );
  }
}
