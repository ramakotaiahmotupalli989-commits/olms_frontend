/// EduCinema LMS — Teacher Homework Management Page
/// Teachers create, manage, and track homework assignments for their classes.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class TeacherHomeworkPage extends StatefulWidget {
  const TeacherHomeworkPage({super.key});
  @override
  State<TeacherHomeworkPage> createState() => _TeacherHomeworkPageState();
}

class _TeacherHomeworkPageState extends State<TeacherHomeworkPage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _assignments = [];
  List<dynamic> _classes = [];
  int? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadClasses() async {
    try {
      _classes = await _repo.getList('/teacher/attendance/classes');
      if (_classes.isNotEmpty) {
        _selectedClassId = _classes[0]['class_id'];
      }
      await _loadAssignments();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAssignments() async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{};
      if (_selectedClassId != null) params['class_id'] = _selectedClassId;
      _assignments = await _repo.getList('/teacher/assignments', params: params);
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Homework & Assignments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'All Assignments'), Tab(text: 'Create New')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildListTab(), _buildCreateTab()],
      ),
    );
  }

  // ── List Tab ──
  Widget _buildListTab() {
    return Column(children: [
      if (_classes.isNotEmpty) _buildClassFilter(),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _assignments.isEmpty
                ? const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No assignments yet',
                    subtitle: 'Create your first homework assignment',
                  )
                : RefreshIndicator(
                    onRefresh: _loadAssignments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _assignments.length,
                      itemBuilder: (_, i) => _buildAssignmentCard(_assignments[i]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildClassFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
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
              value: _selectedClassId, isExpanded: true,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              items: _classes.map<DropdownMenuItem<int>>((c) {
                final label = 'Class ${c['grade']}${c['section'] != null ? ' - ${c['section']}' : ''} (${c['student_count']} students)';
                return DropdownMenuItem(value: c['class_id'] as int, child: Text(label));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedClassId = val);
                _loadAssignments();
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAssignmentCard(dynamic a) {
    final type = a['assignment_type'] ?? 'homework';
    final isHomework = type == 'homework';
    final dueDate = a['due_date'] != null ? DateTime.tryParse(a['due_date']) : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());
    final color = isOverdue ? AppColors.error : isHomework ? AppColors.featureBlue : AppColors.featurePurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(isHomework ? Icons.home_work_rounded : Icons.edit_note_rounded, color: color, size: 22),
        ),
        title: Text(a['title'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          StatusBadge(label: type.toString().toUpperCase(), color: color),
          if (dueDate != null) Text(
            'Due: ${DateFormat('d MMM').format(dueDate)}',
            style: GoogleFonts.inter(fontSize: 11, color: isOverdue ? AppColors.error : AppColors.textSecondary),
          ),
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (a['description'] != null && a['description'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(a['description'], style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                ),
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (a['chapter_id'] != null) _infoChip('Chapter #${a['chapter_id']}', Icons.book_rounded),
                if (a['video_id'] != null) _infoChip('Video #${a['video_id']}', Icons.play_circle_rounded),
                TextButton.icon(
                  onPressed: () => _trackAssignment(a['id']),
                  icon: const Icon(Icons.analytics_rounded, size: 16),
                  label: const Text('Track'),
                ),
                IconButton(
                  onPressed: () => _deleteAssignment(a['id']),
                  icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                  tooltip: 'Delete',
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.info),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info)),
      ]),
    );
  }

  Future<void> _trackAssignment(int id) async {
    try {
      final data = await _repo.get('/teacher/assignments/$id/track');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(data['title'] ?? 'Tracking', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _trackRow('Total Students', '${data['total_students'] ?? 0}'),
            _trackRow('Completed', '${data['completed_count'] ?? 0}', color: AppColors.success),
            const Divider(height: 20),
            ...(data['entries'] as List? ?? []).map((e) => ListTile(
                  dense: true, contentPadding: EdgeInsets.zero,
                  leading: Icon(e['watched'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: e['watched'] == true ? AppColors.success : AppColors.error, size: 20),
                  title: Text(e['student_name'] ?? '', style: GoogleFonts.inter(fontSize: 13)),
                  subtitle: Text('${(e['watched_percent'] ?? 0).toStringAsFixed(0)}% watched', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  trailing: e['quiz_score'] != null
                      ? Text('${e['quiz_score']}/${e['quiz_total']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.featureBlue))
                      : null,
                )),
          ])),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData is Map) {
          final detail = resData['detail'];
          if (detail != null) errMsg = detail.toString();
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errMsg'), backgroundColor: AppColors.error));
    }
  }

  Widget _trackRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
      ]),
    );
  }

  Future<void> _deleteAssignment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Assignment?'),
        content: const Text('This will remove the assignment from all students.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.delete('/teacher/assignments/$id');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment deleted'), backgroundColor: AppColors.success));
      _loadAssignments();
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData is Map) {
          final detail = resData['detail'];
          if (detail != null) errMsg = detail.toString();
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errMsg'), backgroundColor: AppColors.error));
    }
  }

  // ── Create Tab ──
  Widget _buildCreateTab() {
    return _CreateAssignmentForm(
      classes: _classes,
      onCreated: () {
        _loadAssignments();
        _tabController.animateTo(0);
      },
    );
  }
}

// ── Create Assignment Form Widget ──
class _CreateAssignmentForm extends StatefulWidget {
  final List<dynamic> classes;
  final VoidCallback onCreated;
  const _CreateAssignmentForm({required this.classes, required this.onCreated});
  @override
  State<_CreateAssignmentForm> createState() => _CreateAssignmentFormState();
}

class _CreateAssignmentFormState extends State<_CreateAssignmentForm> {
  final _repo = ApiRepository();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _classId;
  String _type = 'homework';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  bool _saving = false;

  // Subjects, Chapters, and Videos tracking
  List<dynamic> _subjects = [];
  int? _selectedSubjectId;

  List<dynamic> _contentData = []; // Cache of /teacher/content
  List<dynamic> _chapters = [];
  int? _selectedChapterId;

  List<dynamic> _videos = [];
  int? _selectedVideoId;

  @override
  void initState() {
    super.initState();
    _loadContentData();
    if (widget.classes.isNotEmpty) {
      _classId = widget.classes[0]['class_id'];
      _loadSubjectsForClass(_classId!);
    }
  }

  Future<void> _loadContentData() async {
    try {
      final list = await _repo.getList('/teacher/content');
      setState(() {
        _contentData = list;
        _updateChaptersAndVideos();
      });
    } catch (_) {}
  }

  Future<void> _loadSubjectsForClass(int classId) async {
    try {
      final list = await _repo.getList('/teacher/my-subjects', params: {'class_id': classId});
      setState(() {
        _subjects = list;
        _selectedSubjectId = null;
        _chapters = [];
        _selectedChapterId = null;
        _videos = [];
        _selectedVideoId = null;
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects[0]['subject_id'];
          _updateChaptersAndVideos();
        }
      });
    } catch (_) {}
  }

  void _updateChaptersAndVideos() {
    setState(() {
      _chapters = [];
      _selectedChapterId = null;
      _videos = [];
      _selectedVideoId = null;

      if (_contentData.isEmpty || _selectedSubjectId == null) return;

      final matchedSubject = _contentData.firstWhere(
        (s) => s['subject_id'] == _selectedSubjectId,
        orElse: () => null,
      );
      if (matchedSubject != null) {
        _chapters = matchedSubject['chapters'] ?? [];
        if (_chapters.isNotEmpty) {
          // Keep first option selectable or let users choose
          _selectedChapterId = null; // Default to whole subject first
        }
      }
    });
  }

  void _updateVideosForChapter() {
    setState(() {
      _videos = [];
      _selectedVideoId = null;

      if (_selectedChapterId == null) return;

      final matchedChapter = _chapters.firstWhere(
        (c) => c['chapter_id'] == _selectedChapterId,
        orElse: () => null,
      );
      if (matchedChapter != null) {
        _videos = matchedChapter['videos'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create Assignment', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),

        // Class selector
        if (widget.classes.isNotEmpty)
          DropdownButtonFormField<int>(
            value: _classId,
            decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.class_rounded)),
            items: widget.classes.map<DropdownMenuItem<int>>((c) {
              final label = 'Class ${c['grade']}${c['section'] != null ? '-${c['section']}' : ''}';
              return DropdownMenuItem(value: c['class_id'] as int, child: Text(label));
            }).toList(),
            onChanged: (v) {
              setState(() {
                _classId = v;
                _loadSubjectsForClass(v!);
              });
            },
          ),
        const SizedBox(height: 16),

        // Subject selector
        if (_subjects.isNotEmpty)
          DropdownButtonFormField<int>(
            value: _selectedSubjectId,
            decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.book_rounded)),
            items: _subjects.map<DropdownMenuItem<int>>((s) {
              return DropdownMenuItem(value: s['subject_id'] as int, child: Text(s['subject_name'] ?? ''));
            }).toList(),
            onChanged: (v) {
              setState(() {
                _selectedSubjectId = v;
                _updateChaptersAndVideos();
              });
            },
          ),
        const SizedBox(height: 16),

        // Chapter selector (optional)
        if (_chapters.isNotEmpty)
          DropdownButtonFormField<int?>(
            value: _selectedChapterId,
            decoration: const InputDecoration(labelText: 'Chapter (optional)', prefixIcon: Icon(Icons.menu_book_rounded)),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Assign Whole Subject')),
              ..._chapters.map<DropdownMenuItem<int?>>((c) {
                return DropdownMenuItem(value: c['chapter_id'] as int, child: Text(c['title'] ?? ''));
              }),
            ],
            onChanged: (v) {
              setState(() {
                _selectedChapterId = v;
                _updateVideosForChapter();
              });
            },
          ),
        const SizedBox(height: 16),

        // Video selector (optional, appears only if a chapter is selected)
        if (_selectedChapterId != null && _videos.isNotEmpty)
          DropdownButtonFormField<int?>(
            value: _selectedVideoId,
            decoration: const InputDecoration(labelText: 'Video (optional)', prefixIcon: Icon(Icons.play_circle_rounded)),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Assign Whole Chapter')),
              ..._videos.map<DropdownMenuItem<int?>>((v) {
                return DropdownMenuItem(value: v['id'] as int, child: Text(v['title'] ?? ''));
              }),
            ],
            onChanged: (v) => setState(() => _selectedVideoId = v),
          ),
        if (_selectedChapterId != null && _videos.isNotEmpty) const SizedBox(height: 16),

        // Type selector
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category_rounded)),
          items: const [
            DropdownMenuItem(value: 'homework', child: Text('Homework')),
            DropdownMenuItem(value: 'classwork', child: Text('Classwork')),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 16),

        // Title
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title_rounded)),
        ),
        const SizedBox(height: 16),

        // Description
        TextField(
          controller: _descCtrl, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.description_rounded), alignLabelWithHint: true),
        ),
        const SizedBox(height: 16),

        // Due date
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_rounded, color: AppColors.primary),
          title: Text('Due Date: ${DateFormat('d MMMM yyyy').format(_dueDate)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          trailing: TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 120)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            child: const Text('Change'),
          ),
        ),
        const SizedBox(height: 24),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(_saving ? 'Creating...' : 'Create Assignment'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]),
    );
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _classId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title, select class and subject'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.post('/teacher/assignments', data: {
        'class_id': _classId,
        'assignment_type': _type,
        'title': _titleCtrl.text,
        'description': _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
        'subject_id': _selectedSubjectId,
        'chapter_id': _selectedChapterId,
        'video_id': _selectedVideoId,
        'due_date': _dueDate.toUtc().toIso8601String(),
      });
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created!'), backgroundColor: AppColors.success),
        );
        _titleCtrl.clear();
        _descCtrl.clear();
        widget.onCreated();
      }
    } catch (e) {
      setState(() => _saving = false);
      String errMsg = e.toString();
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData is Map) {
          final detail = resData['detail'];
          if (detail != null) errMsg = detail.toString();
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errMsg'), backgroundColor: AppColors.error));
    }
  }
}
