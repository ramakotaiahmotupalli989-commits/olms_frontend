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
  List<dynamic> _subjects = [];

  int? _selectedExamId;
  int? _selectedClassId;
  int? _selectedSubjectId;
  double _totalMarks = 100;

  // Leaderboard specific state
  int? _selectedLeadExamId;
  int? _selectedLeadClassId;
  bool _leadLoading = false;
  List<dynamic> _leadResults = [];
  double _leadAvgPercentage = 0;
  int _leadPassCount = 0;
  int _leadFailCount = 0;

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
      // Load subjects for this class
      _subjects = await _repo.getList('/teacher/my-subjects', params: {'class_id': _selectedClassId.toString()});
      _selectedSubjectId = null;

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Exam Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Score Entry'),
              Tab(text: 'Class Leaderboard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
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
            _buildLeaderboardTab(),
          ],
        ),
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
          // Class and subject selectors
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
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: const Icon(Icons.book_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  items: _subjects.map<DropdownMenuItem<int>>((s) {
                    return DropdownMenuItem(
                      value: s['subject_id'] as int,
                      child: Text(s['subject_name'] ?? '', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedSubjectId = val);
                    if (_selectedExamId != null && _students.isNotEmpty) {
                      _loadExistingScores();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total marks
          Row(children: [
            SizedBox(
              width: 120,
              child: TextFormField(
                initialValue: '100',
                decoration: InputDecoration(
                  labelText: 'Total Marks',
                  prefixIcon: const Icon(Icons.score_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: GoogleFonts.inter(fontSize: 13),
                keyboardType: TextInputType.number,
                onChanged: (val) => _totalMarks = double.tryParse(val) ?? 100,
              ),
            ),
            const Spacer(),
            if (_selectedExamId != null && _selectedSubjectId != null && _students.isNotEmpty)
              TextButton.icon(
                onPressed: _loadExistingScores,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Load Saved'),
              ),
          ]),
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

  // ──────────────────────────────────────────────
  // CLASS LEADERBOARD TAB
  // ──────────────────────────────────────────────
  Future<void> _loadLeaderboard() async {
    if (_selectedLeadExamId == null || _selectedLeadClassId == null) return;
    setState(() => _leadLoading = true);
    try {
      final data = await _repo.get('/exams/$_selectedLeadExamId/class/$_selectedLeadClassId/results');
      _leadResults = (data['students'] as List?) ?? [];
      
      if (_leadResults.isEmpty) {
        _leadAvgPercentage = 0;
        _leadPassCount = 0;
        _leadFailCount = 0;
      } else {
        double totalPct = 0;
        _leadPassCount = 0;
        _leadFailCount = 0;
        for (var s in _leadResults) {
          final pct = (s['percentage'] ?? 0).toDouble();
          totalPct += pct;
          if (pct >= 40) {
            _leadPassCount++;
          } else {
            _leadFailCount++;
          }
        }
        _leadAvgPercentage = totalPct / _leadResults.length;
      }
      setState(() => _leadLoading = false);
    } catch (e) {
      debugPrint('[ExamMgmt] Load leaderboard error: $e');
      setState(() => _leadLoading = false);
    }
  }

  Widget _buildLeaderboardTab() {
    return Column(
      children: [
        _buildLeadSelectors(),
        Expanded(
          child: _leadLoading
              ? const Center(child: CircularProgressIndicator())
              : _leadResults.isEmpty
                  ? const EmptyState(
                      icon: Icons.leaderboard_rounded,
                      title: 'Select Exam & Class',
                      subtitle: 'Choose an exam and class to view results with rankings',
                    )
                  : _buildLeadResultsList(),
        ),
      ],
    );
  }

  Widget _buildLeadSelectors() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedLeadExamId,
                  decoration: InputDecoration(
                    labelText: 'Exam',
                    prefixIcon: const Icon(Icons.assignment_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  items: _exams.map<DropdownMenuItem<int>>((e) {
                    final typeLabel = (e['exam_type'] ?? '').toString().replaceAll('_', ' ');
                    return DropdownMenuItem(
                      value: e['id'] as int,
                      child: Text('${e['name']} ($typeLabel)', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedLeadExamId = val);
                    _loadLeaderboard();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedLeadClassId,
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
                    setState(() => _selectedLeadClassId = val);
                    _loadLeaderboard();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadResultsList() {
    return Column(
      children: [
        _buildLeadKPIs(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _leadResults.length,
            itemBuilder: (context, index) {
              final student = _leadResults[index];
              final rank = student['rank'] ?? (index + 1);
              final name = student['student_name'] ?? '';
              final roll = student['roll_number'] ?? '';
              final pct = (student['percentage'] ?? 0).toDouble();
              final totalObtained = student['total_obtained'] ?? 0;
              final totalMax = student['total_max'] ?? 0;
              final subjects = (student['subjects'] as List?) ?? [];

              Color rankColor;
              IconData? rankIcon;
              if (rank == 1) {
                rankColor = AppColors.gold;
                rankIcon = Icons.emoji_events_rounded;
              } else if (rank == 2) {
                rankColor = AppColors.silver;
                rankIcon = Icons.emoji_events_rounded;
              } else if (rank == 3) {
                rankColor = AppColors.bronze;
                rankIcon = Icons.emoji_events_rounded;
              } else {
                rankColor = AppColors.textSecondary;
                rankIcon = null;
              }

              final pctColor = pct >= 80 ? AppColors.success
                  : pct >= 60 ? AppColors.info
                  : pct >= 40 ? AppColors.warning
                  : AppColors.error;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : Colors.grey.shade100,
                    width: rank <= 3 ? 1.5 : 1,
                  ),
                  boxShadow: rank <= 3
                      ? [BoxShadow(color: rankColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: Container(
                    width: 40, height: 40, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: rank <= 3 ? LinearGradient(colors: [rankColor, rankColor.withValues(alpha: 0.6)]) : null,
                      color: rank > 3 ? AppColors.surfaceVariant : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: rankIcon != null && rank <= 3
                        ? Icon(rankIcon, color: Colors.white, size: 20)
                        : Text('#$rank', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: rank <= 3 ? Colors.white : AppColors.textSecondary)),
                  ),
                  title: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  subtitle: Wrap(spacing: 8, runSpacing: 2, children: [
                    if (roll.toString().isNotEmpty) Text('Roll: $roll', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: pctColor)),
                    Text('($totalObtained/$totalMax)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  ]),
                  children: [
                    if (subjects.isNotEmpty)
                      ...subjects.map<Widget>((subj) {
                        final subjPct = (subj['percentage'] ?? 0).toDouble();
                        final subjColor = subjPct >= 80 ? AppColors.success
                            : subjPct >= 60 ? AppColors.info
                            : subjPct >= 40 ? AppColors.warning
                            : AppColors.error;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            Expanded(flex: 3, child: Text(subj['subject'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))),
                            Expanded(flex: 2, child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: subjPct / 100, minHeight: 6,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation(subjColor),
                              ),
                            )),
                            const SizedBox(width: 8),
                            SizedBox(width: 55, child: Text(
                              '${subj['marks_obtained']}/${subj['total_marks']}',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: subjColor),
                            )),
                            if (subj['grade'] != null) Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: subjColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(subj['grade'], style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: subjColor)),
                            ),
                          ]),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeadKPIs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(children: [
        _leadKPIItem('Avg', '${_leadAvgPercentage.toStringAsFixed(1)}%', const Color(0xFF667EEA)),
        const SizedBox(width: 10),
        _leadKPIItem('Pass', '$_leadPassCount', AppColors.success),
        const SizedBox(width: 10),
        _leadKPIItem('Fail', '$_leadFailCount', AppColors.error),
        const SizedBox(width: 10),
        _leadKPIItem('Total', '${_leadResults.length}', AppColors.info),
      ]),
    );
  }

  Widget _leadKPIItem(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7))),
      ]),
    ));
  }
}
