/// EduCinema LMS — Timetable Management Page (Principal)
/// Principal creates/edits the fixed weekly timetable per class.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class TimetableManagementPage extends StatefulWidget {
  const TimetableManagementPage({super.key});
  @override
  State<TimetableManagementPage> createState() => _TimetableManagementPageState();
}

class _TimetableManagementPageState extends State<TimetableManagementPage>
    with SingleTickerProviderStateMixin {
  final _repo = ApiRepository();
  bool _loadingClasses = true;
  bool _loadingTimetable = false;
  bool _saving = false;

  List<dynamic> _classes = [];
  List<dynamic> _teachers = [];
  int? _selectedClassId;
  String? _selectedClassLabel;
  late TabController _tabController;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  // timetable data: day -> list of period maps
  Map<String, List<Map<String, dynamic>>> _timetable = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initEmptyTimetable();
    _loadInitial();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  void _initEmptyTimetable() {
    _timetable = {for (var d in _days) d: []};
  }

  Future<void> _loadInitial() async {
    try {
      final classes = await _repo.getList('/principal/timetable/classes');
      final teachers = await _repo.getList('/principal/timetable/teachers');
      setState(() {
        _classes = classes;
        _teachers = teachers;
        _loadingClasses = false;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes[0]['class_id'];
          _selectedClassLabel = _classes[0]['label'];
          _loadTimetable();
        }
      });
    } catch (e) {
      setState(() => _loadingClasses = false);
    }
  }

  Future<void> _loadTimetable() async {
    if (_selectedClassId == null) return;
    setState(() => _loadingTimetable = true);
    try {
      final data = await _repo.get('/principal/timetable/$_selectedClassId');
      final tt = data['timetable'] as Map<String, dynamic>? ?? {};
      _initEmptyTimetable();
      for (var day in _days) {
        final periods = (tt[day] as List?) ?? [];
        _timetable[day] = periods.map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p)).toList();
      }
      setState(() => _loadingTimetable = false);
    } catch (e) {
      setState(() => _loadingTimetable = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Timetable Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _days.map((d) => Tab(text: d.substring(0, 3).toUpperCase())).toList(),
        ),
        actions: [
          if (!_saving)
            IconButton(
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Save Timetable',
              onPressed: _saveTimetable,
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      body: _loadingClasses
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const EmptyState(icon: Icons.school_outlined, title: 'No Classes', subtitle: 'Create classes first')
              : Column(children: [
                  _buildClassSelector(),
                  Expanded(
                    child: _loadingTimetable
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            controller: _tabController,
                            children: _days.map((day) => _buildDayTab(day)).toList(),
                          ),
                  ),
                ]),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_view_week_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedClassId, isExpanded: true,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              items: _classes.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem(value: c['class_id'] as int, child: Text(c['label'] ?? 'Class'));
              }).toList(),
              onChanged: (val) {
                final cls = _classes.firstWhere((c) => c['class_id'] == val, orElse: () => null);
                setState(() {
                  _selectedClassId = val;
                  _selectedClassLabel = cls?['label'] ?? '';
                });
                _loadTimetable();
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDayTab(String day) {
    final periods = _timetable[day] ?? [];
    return Column(children: [
      Expanded(
        child: periods.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_note_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No periods added for $day', style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ]))
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: periods.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = periods.removeAt(oldIndex);
                    periods.insert(newIndex, item);
                    // Renumber
                    for (var i = 0; i < periods.length; i++) {
                      periods[i]['period_number'] = i + 1;
                    }
                  });
                },
                itemBuilder: (_, i) => _buildPeriodCard(day, i, key: ValueKey('${day}_$i')),
              ),
      ),
      // Add period button
      Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addPeriod(day),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Period'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildPeriodCard(String day, int index, {Key? key}) {
    final period = (_timetable[day] ?? [])[index];
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
    ];
    final colors = gradients[index % gradients.length];

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors[0].withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          // Period number badge
          Container(
            width: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('P$periodNum', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              if (startTime.isNotEmpty) Text(startTime, style: GoogleFonts.inter(fontSize: 9, color: Colors.white70)),
            ])),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subjectName.isEmpty ? 'Tap to set subject' : subjectName,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                        color: subjectName.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)),
                const SizedBox(height: 4),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  if (teacherName.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(teacherName, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  if (startTime.isNotEmpty && endTime.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.schedule_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text('$startTime - $endTime', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  if (room.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.room_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(room, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ]),
              ]),
            ),
          ),
          // Edit + Delete
          IconButton(icon: const Icon(Icons.edit_rounded, size: 18), onPressed: () => _editPeriod(day, index), tooltip: 'Edit'),
          IconButton(icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.error), onPressed: () => _removePeriod(day, index), tooltip: 'Delete'),
        ]),
      ),
    );
  }

  void _addPeriod(String day) {
    final periods = _timetable[day] ?? [];
    final nextPeriod = periods.length + 1;
    // Default time: 09:00 + 45 min per period
    final startHour = 8 + ((nextPeriod - 1) * 45) ~/ 60;
    final startMin = ((nextPeriod - 1) * 45) % 60;
    final endMin = startMin + 45;
    final endHour = startHour + endMin ~/ 60;
    final eMin = endMin % 60;

    setState(() {
      periods.add({
        'period_number': nextPeriod,
        'start_time': '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}',
        'end_time': '${endHour.toString().padLeft(2, '0')}:${eMin.toString().padLeft(2, '0')}',
        'subject_name': '',
        'teacher_id': null,
        'teacher_name': '',
        'room': '',
      });
      _timetable[day] = periods;
    });
    _editPeriod(day, periods.length - 1);
  }

  void _removePeriod(String day, int index) {
    setState(() {
      _timetable[day]?.removeAt(index);
      // Renumber
      for (var i = 0; i < (_timetable[day]?.length ?? 0); i++) {
        _timetable[day]![i]['period_number'] = i + 1;
      }
    });
  }

  Future<void> _editPeriod(String day, int index) async {
    final period = _timetable[day]![index];
    final subjectCtrl = TextEditingController(text: period['subject_name'] ?? '');
    final roomCtrl = TextEditingController(text: period['room'] ?? '');
    final startCtrl = TextEditingController(text: period['start_time'] ?? '');
    final endCtrl = TextEditingController(text: period['end_time'] ?? '');
    int? selectedTeacherId = period['teacher_id'];
    String selectedTeacherName = period['teacher_name'] ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Period ${index + 1} — $day', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject Name *', prefixIcon: Icon(Icons.book_rounded)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: selectedTeacherId,
              decoration: const InputDecoration(labelText: 'Teacher', prefixIcon: Icon(Icons.person_rounded)),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('— None —')),
                ..._teachers.map<DropdownMenuItem<int>>((t) =>
                    DropdownMenuItem(value: t['id'] as int, child: Text(t['name'] ?? ''))),
              ],
              onChanged: (v) {
                setDialogState(() {
                  selectedTeacherId = v;
                  selectedTeacherName = _teachers.firstWhere((t) => t['id'] == v, orElse: () => {'name': ''})['name'] ?? '';
                });
              },
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time', hintText: '09:00'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time', hintText: '09:45'))),
            ]),
            const SizedBox(height: 14),
            TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room (optional)', prefixIcon: Icon(Icons.room_rounded))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        period['subject_name'] = subjectCtrl.text;
        period['teacher_id'] = selectedTeacherId;
        period['teacher_name'] = selectedTeacherName;
        period['start_time'] = startCtrl.text;
        period['end_time'] = endCtrl.text;
        period['room'] = roomCtrl.text;
      });
    }
  }

  Future<void> _saveTimetable() async {
    if (_selectedClassId == null) return;
    setState(() => _saving = true);

    // Flatten all entries
    final entries = <Map<String, dynamic>>[];
    for (var day in _days) {
      for (var period in (_timetable[day] ?? [])) {
        if ((period['subject_name'] ?? '').toString().isEmpty) continue;
        entries.add({
          'day_of_week': day,
          'period_number': period['period_number'],
          'start_time': period['start_time'],
          'end_time': period['end_time'],
          'subject_name': period['subject_name'],
          'teacher_id': period['teacher_id'],
          'teacher_name': period['teacher_name'],
          'room': period['room'],
        });
      }
    }

    try {
      await _repo.post('/principal/timetable/$_selectedClassId', data: {'entries': entries});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Timetable saved for $_selectedClassLabel!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
    setState(() => _saving = false);
  }
}
