/// EduCinema LMS — Class Roster Page (Teacher)
/// Student roster with progress, quiz scores, and action menu.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_repository.dart';

class ClassRosterPage extends StatefulWidget {
  final int classId;
  const ClassRosterPage({super.key, required this.classId});
  @override
  State<ClassRosterPage> createState() => _ClassRosterPageState();
}

class _ClassRosterPageState extends State<ClassRosterPage> {
  final _repo = ApiRepository();
  List<dynamic> _students = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _students = await _repo.getList('/teacher/class/${widget.classId}/roster');
      setState(() => _loading = false);
    } catch (e) { setState(() => _loading = false); }
  }

  List<dynamic> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((s) => (s['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Class Roster'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredStudents.length,
                  itemBuilder: (_, i) => _buildStudentCard(_filteredStudents[i]),
                ),
        ),
      ]),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> s) {
    final progress = (s['avg_video_progress'] ?? 0).toDouble();
    final quiz = (s['avg_quiz_score'] ?? 0).toDouble();
    final active = s['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? Colors.grey.shade100 : Colors.grey.shade200),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade200,
          child: Text((s['name'] ?? 'S')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: active ? AppColors.primary : Colors.grey)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(s['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            if (s['roll_number'] != null) Text('#${s['roll_number']}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            if (!active) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text('Inactive', style: GoogleFonts.inter(fontSize: 9, color: AppColors.error, fontWeight: FontWeight.w600)))],
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _buildMiniMetric(Icons.play_circle_outline, '${progress.toInt()}%', progress >= 70 ? AppColors.success : AppColors.warning),
            const SizedBox(width: 14),
            _buildMiniMetric(Icons.quiz_outlined, quiz.toStringAsFixed(1), quiz >= 70 ? AppColors.success : AppColors.warning),
            const SizedBox(width: 14),
            _buildMiniMetric(Icons.access_time, s['last_login'] != null ? 'Active' : 'Never', s['last_login'] != null ? AppColors.success : AppColors.error),
          ]),
        ])),
        PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'profile', child: Text('View Profile')),
            const PopupMenuItem(value: 'message', child: Text('Send Message')),
            PopupMenuItem(value: 'toggle', child: Text(active ? 'Deactivate' : 'Activate')),
          ],
          onSelected: (v) {},
          icon: const Icon(Icons.more_vert, size: 20),
        ),
      ]),
    );
  }

  Widget _buildMiniMetric(IconData icon, String value, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 3),
      Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    ]);
  }
}
