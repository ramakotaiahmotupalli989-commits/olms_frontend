/// EduCinema LMS — Exam Management Page (Teacher)
/// Enter and manage student exam scores per exam/subject/class.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ExamManagementPage extends StatefulWidget {
  const ExamManagementPage({super.key});

  @override
  State<ExamManagementPage> createState() => _ExamManagementPageState();
}

class _ExamManagementPageState extends State<ExamManagementPage> {
  final _repo = ApiRepository();

  bool _loading = true;
  bool _saving = false;

  List<dynamic> _exams = [];
  List<dynamic> _classes = [];
  List<dynamic> _students = [];

  int? _selectedExamId;
  int? _selectedClassId;
  int? _selectedSubjectId;
  double _totalMarks = 100;

  // Score map: studentId -> marks
  final Map<int, TextEditingController> _marksControllers = {};
  final Map<int, String?> _grades = {};

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  @override
  void dispose() {
    for (var c in _marksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExams() async {
    setState(() => _loading = true);
    try {
      _exams = await _repo.getList('/exams');
      _classes = await _repo.getList('/teacher/attendance/classes');
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[ExamMgmt] Load exams error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    setState(() => _loading = true);
    try {
      final data = await _repo.get('/teacher/attendance/class/$_selectedClassId');
      _students = (data['students'] as List?) ?? [];

      _marksControllers.clear();
      _grades.clear();
      for (var s in _students) {
        final sid = s['student_id'] as int;
        _marksControllers[sid] = TextEditingController();
        _grades[sid] = null;
      }

      // If exam and subject selected, load existing scores
      if (_selectedExamId != null && _selectedSubjectId != null) {
        await _loadExistingScores();
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[ExamMgmt] Load students error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadExistingScores() async {
    if (_selectedExamId == null || _selectedSubjectId == null) return;
    try {
      final scores = await _repo.getList(
        '/exams/$_selectedExamId/scores',
        params: {
          'class_id': _selectedClassId.toString(),
          'subject_id': _selectedSubjectId.toString(),
        },
      );

      for (var score in scores) {
        final sid = score['student_id'] as int;
        if (_marksControllers.containsKey(sid)) {
          _marksControllers[sid]!.text = score['marks_obtained'].toString();
          _grades[sid] = score['grade'];
        }
      }
      setState(() {});
    } catch (e) {
      debugPrint('[ExamMgmt] Load existing scores error: $e');
    }
  }

  String _autoGrade(double marks, double total) {
    final pct = (marks / total) * 100;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 40) return 'D';
    return 'F';
  }

  Future<void> _saveScores() async {
    if (_selectedExamId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select exam and subject first')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final scores = <Map<String, dynamic>>[];
      for (var s in _students) {
        final sid = s['student_id'] as int;
        final marksText = _marksControllers[sid]?.text ?? '';
        if (marksText.isEmpty) continue;

        final marks = double.tryParse(marksText) ?? 0;
        scores.add({
          'student_id': sid,
          'subject_id': _selectedSubjectId,
          'marks_obtained': marks,
          'total_marks': _totalMarks,
          'grade': _grades[sid] ?? _autoGrade(marks, _totalMarks),
        });
      }

      if (scores.isEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No marks entered')),
        );
        return;
      }

      await _repo.post('/exams/$_selectedExamId/scores', data: {
        'subject_id': _selectedSubjectId,
        'total_marks': _totalMarks,
        'scores': scores,
      });

      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${scores.length} scores saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ExamMgmt] Save scores error: $e');
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Exam Score Entry')),
      body: Column(
        children: [
          _buildSelectors(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const EmptyState(
                        icon: Icons.assignment_rounded,
                        title: 'Select Exam & Class',
                        subtitle: 'Choose an exam and class to start entering scores',
                      )
                    : _buildScoreTable(),
          ),
          if (_students.isNotEmpty) _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Exam selector
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.featureBlue, AppColors.featurePurple]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedExamId,
                    isExpanded: true,
                    hint: Text('Select Exam', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    items: _exams.map<DropdownMenuItem<int>>((e) {
                      final typeLabel = (e['exam_type'] ?? '').toString().replaceAll('_', ' ');
                      return DropdownMenuItem(
                        value: e['id'] as int,
                        child: Text('${e['name']} ($typeLabel)'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedExamId = val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Class selector
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    prefixIcon: const Icon(Icons.class_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  items: _classes.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem(
                      value: c['class_id'] as int,
                      child: Text('Class ${c['grade']}${c['section'] != null ? '-${c['section']}' : ''}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedClassId = val);
                    _loadStudents();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Subject ID input (simplified — in production use a dropdown)
              SizedBox(
                width: 120,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Subject ID',
                    prefixIcon: const Icon(Icons.book_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 13),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    _selectedSubjectId = int.tryParse(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: '100',
                  decoration: InputDecoration(
                    labelText: 'Total',
                    prefixIcon: const Icon(Icons.score_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 13),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _totalMarks = double.tryParse(val) ?? 100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTable() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final sid = student['student_id'] as int;
        final name = student['student_name'] ?? '';
        final roll = student['roll_number'] ?? '';
        final marksText = _marksControllers[sid]?.text ?? '';
        final marks = double.tryParse(marksText) ?? 0;
        final grade = _grades[sid] ?? (marksText.isNotEmpty ? _autoGrade(marks, _totalMarks) : '');

        Color gradeColor = AppColors.textSecondary;
        if (grade == 'A+' || grade == 'A') {
          gradeColor = AppColors.success;
        } else if (grade == 'B+' || grade == 'B') {
          gradeColor = AppColors.info;
        } else if (grade == 'C' || grade == 'D') {
          gradeColor = AppColors.warning;
        } else if (grade == 'F') {
          gradeColor = AppColors.error;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.featureBlue.withValues(alpha: 0.1),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.featureBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (roll.isNotEmpty)
                      Text('Roll: $roll', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _marksControllers[sid],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade300),
                    suffixText: '/$_totalMarks',
                    suffixStyle: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  onChanged: (val) {
                    final m = double.tryParse(val) ?? 0;
                    setState(() {
                      _grades[sid] = _autoGrade(m, _totalMarks);
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  grade.isNotEmpty ? grade : '-',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: gradeColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              '${_students.length} students',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveScores,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_saving ? 'Saving...' : 'Save Scores'),
            ),
          ],
        ),
      ),
    );
  }
}
