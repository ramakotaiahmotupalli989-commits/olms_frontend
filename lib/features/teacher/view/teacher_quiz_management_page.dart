/// EduCinema LMS — Teacher Quiz Management
/// Create MCQ quizzes and schedule them for assigned classes.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class TeacherQuizManagementPage extends StatefulWidget {
  const TeacherQuizManagementPage({super.key});
  @override
  State<TeacherQuizManagementPage> createState() => _TeacherQuizManagementPageState();
}

class _TeacherQuizManagementPageState extends State<TeacherQuizManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = ApiRepository();
  bool _loading = true;
  List<dynamic> _quizzes = [];
  List<dynamic> _sessions = [];
  List<dynamic> _subjects = [];
  List<dynamic> _classes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _quizzes = await _repo.getList('/teacher/quizzes');
      _sessions = await _repo.getList('/teacher/sessions');
      _subjects = await _repo.getList('/teacher/subjects');
      _classes = await _repo.getList('/teacher/classes');
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[QuizMgmt] Load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quiz & Test Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Quizzes', icon: Icon(Icons.quiz)),
            Tab(text: 'Scheduled Tests', icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQuizzesTab(),
                _buildSessionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabController.index == 0 ? _showCreateQuizDialog() : _showScheduleTestDialog(),
        label: Text(_tabController.index == 0 ? 'Create Quiz' : 'Schedule Test'),
        icon: Icon(_tabController.index == 0 ? Icons.add : Icons.event_available),
      ),
    );
  }

  Widget _buildQuizzesTab() {
    if (_quizzes.isEmpty) {
      return const EmptyState(icon: Icons.quiz_outlined, title: 'No quizzes yet', subtitle: 'Create your first MCQ quiz to test your students');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      itemBuilder: (_, i) {
        final q = _quizzes[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(q['title'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('${(q['questions'] as List).length} Questions • Subject ID: ${q['subject_id']}', style: GoogleFonts.inter(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showQuizDetails(q),
          ),
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return const EmptyState(icon: Icons.schedule_outlined, title: 'No tests scheduled', subtitle: 'Schedule a quiz for your classes to see results');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (_, i) {
        final s = _sessions[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.event_note, color: AppColors.primary),
            title: Text('Quiz ID: ${s['quiz_id']} for Class ID: ${s['class_id']}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('Due: ${s['due_at']}\nAnswers show: ${s['answers_published_at']}', style: GoogleFonts.inter(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.leaderboard_rounded, color: AppColors.accent),
              onPressed: () => _showRankings(s['id']),
            ),
          ),
        );
      },
    );
  }

  void _showCreateQuizDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int? selectedSubjectId;
    List<Map<String, dynamic>> questions = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Quiz'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Subject'),
                  value: selectedSubjectId,
                  items: _subjects.map<DropdownMenuItem<int>>((s) {
                    final int id = s['id'] ?? 0;
                    final String name = s['name'] ?? '';
                    final String grade = s['grade'] ?? '';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text('$name (Class $grade)'),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                ),
                const Divider(height: 32),
                Text('Questions (${questions.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ...questions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(q['question_text'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(icon: const Icon(Icons.delete, size: 16), onPressed: () => setDialogState(() => questions.removeAt(idx))),
                  );
                }),
                TextButton.icon(
                  onPressed: () async {
                    final newQ = await _showAddQuestionDialog();
                    if (newQ != null) setDialogState(() => questions.add(newQ));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || questions.isEmpty || selectedSubjectId == null) return;
                try {
                  await _repo.post('/teacher/quizzes', data: {
                    'title': titleCtrl.text,
                    'description': descCtrl.text,
                    'subject_id': selectedSubjectId,
                    'questions': questions,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showAddQuestionDialog() async {
    final textCtrl = TextEditingController();
    final optionsCtrls = List.generate(4, (_) => TextEditingController());
    int correctIdx = 0;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: textCtrl, decoration: const InputDecoration(labelText: 'Question Text'), maxLines: 2),
                const SizedBox(height: 16),
                ...List.generate(4, (i) => Row(children: [
                  Radio<int>(value: i, groupValue: correctIdx, onChanged: (v) => setDialogState(() => correctIdx = v!)),
                  Expanded(child: TextField(controller: optionsCtrls[i], decoration: InputDecoration(labelText: 'Option ${i+1}'))),
                ])),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (textCtrl.text.isEmpty || optionsCtrls.any((c) => c.text.isEmpty)) return;
                Navigator.pop(ctx, {
                  'question_text': textCtrl.text,
                  'options': optionsCtrls.map((c) => c.text).toList(),
                  'correct_option_index': correctIdx,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleTestDialog({int? quizId}) {
    int? selectedQuizId = quizId;
    int? selectedClassId;
    DateTime scheduledDate = DateTime.now().add(const Duration(hours: 1));
    List<dynamic> filteredClasses = [];
    bool loadingClasses = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> loadFilteredClasses(int qId) async {
            setDialogState(() => loadingClasses = true);
            try {
              final selectedQuiz = _quizzes.firstWhere((q) => q['id'] == qId, orElse: () => null);
              if (selectedQuiz != null) {
                final subjectId = selectedQuiz['subject_id'];
                final list = await _repo.getList('/teacher/classes?subject_id=$subjectId');
                setDialogState(() {
                  filteredClasses = list;
                  loadingClasses = false;
                  if (selectedClassId != null && !filteredClasses.any((c) => c['id'] == selectedClassId)) {
                    selectedClassId = null;
                  }
                });
              } else {
                setDialogState(() {
                  filteredClasses = [];
                  loadingClasses = false;
                  selectedClassId = null;
                });
              }
            } catch (e) {
              debugPrint('Error loading filtered classes: $e');
              setDialogState(() => loadingClasses = false);
            }
          }

          if (selectedQuizId != null && filteredClasses.isEmpty && !loadingClasses) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              loadFilteredClasses(selectedQuizId!);
            });
          }

          return AlertDialog(
            title: const Text('Schedule Test'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select Quiz'),
                  value: selectedQuizId,
                  items: _quizzes.map<DropdownMenuItem<int>>((q) => DropdownMenuItem(value: q['id'] as int, child: Text(q['title'] ?? ''))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        selectedQuizId = v;
                      });
                      loadFilteredClasses(v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (loadingClasses)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Select Class'),
                    value: selectedClassId,
                    items: filteredClasses.map<DropdownMenuItem<int>>((c) {
                      final int id = c['id'] ?? 0;
                      final String grade = c['grade'] ?? '';
                      final String section = c['section'] ?? '';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text('Class $grade - $section'),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedClassId = v),
                  ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Date & Time'),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(scheduledDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: scheduledDate,
                      firstDate: DateTime.now().subtract(const Duration(minutes: 5)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      if (!ctx.mounted) return;
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(scheduledDate),
                      );
                      if (t != null) {
                        setDialogState(() {
                          scheduledDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedQuizId == null || selectedClassId == null) return;
                  try {
                    await _repo.post('/teacher/sessions', data: {
                      'quiz_id': selectedQuizId,
                      'class_id': selectedClassId,
                      'scheduled_at': scheduledDate.toUtc().toIso8601String(),
                      'due_at': scheduledDate.add(const Duration(hours: 2)).toUtc().toIso8601String(),
                    });
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuizDetails(dynamic quiz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(quiz['title'] ?? ''),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (quiz['description'] != null && quiz['description'].toString().isNotEmpty) ...[
                  Text(quiz['description'], style: GoogleFonts.inter(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                ],
                Text('Questions (${(quiz['questions'] as List).length})', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...((quiz['questions'] as List).asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  final List<dynamic> opts = q['options'] ?? [];
                  final int correctIdx = q['correct_option_index'] ?? 0;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q${idx + 1}: ${q['question_text'] ?? ''}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...opts.asMap().entries.map((optEntry) {
                          final oIdx = optEntry.key;
                          final oVal = optEntry.value;
                          final isCorrect = oIdx == correctIdx;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                  color: isCorrect ? AppColors.success : Colors.grey.shade400,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    oVal.toString(),
                                    style: GoogleFonts.inter(
                                      color: isCorrect ? AppColors.success : AppColors.textPrimary,
                                      fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Explanation: ${q['explanation']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  );
                })),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Quiz'),
                      content: const Text('Are you sure you want to delete this quiz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await _repo.delete('/teacher/quizzes/${quiz['id']}');
                      if (!mounted) return;
                      Navigator.pop(context);
                      _load();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz deleted successfully'), backgroundColor: AppColors.success));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showEditQuizDialog(quiz);
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.event_available, size: 16),
                label: const Text('Schedule'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showScheduleTestDialog(quizId: quiz['id']);
                },
              ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        ],
      ),
    );
  }

  void _showRankings(int sessionId) async {
    // Fetch and show rankings
    try {
      final data = await _repo.get('/teacher/sessions/$sessionId/rankings');
      if (data['rankings'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'No rankings yet')));
        return;
      }
      _showRankingsDialog(data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showRankingsDialog(dynamic data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rankings: ${data['quiz_title']}'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: (data['rankings'] as List).length,
            itemBuilder: (_, i) {
              final r = data['rankings'][i];
              return ListTile(
                leading: CircleAvatar(child: Text('#${r['rank']}')),
                title: Text(r['student_name']),
                trailing: Text('${r['score']}/${r['total_marks']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showEditQuizDialog(dynamic quiz) {
    final titleCtrl = TextEditingController(text: quiz['title']);
    final descCtrl = TextEditingController(text: quiz['description'] ?? '');
    int? selectedSubjectId = quiz['subject_id'];
    
    // Convert questions to editable maps
    List<Map<String, dynamic>> questions = [];
    for (var q in (quiz['questions'] as List)) {
      questions.add({
        'question_text': q['question_text'],
        'options': List<String>.from(q['options']),
        'correct_option_index': q['correct_option_index'],
        'explanation': q['explanation'],
        'marks': q['marks'] ?? 1,
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Quiz'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Subject'),
                  value: selectedSubjectId,
                  items: _subjects.map<DropdownMenuItem<int>>((s) {
                    final int id = s['id'] ?? 0;
                    final String name = s['name'] ?? '';
                    final String grade = s['grade'] ?? '';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text('$name (Class $grade)'),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                ),
                const Divider(height: 32),
                Text('Questions (${questions.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ...questions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(q['question_text'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 16),
                      onPressed: () => setDialogState(() => questions.removeAt(idx)),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () async {
                    final newQ = await _showAddQuestionDialog();
                    if (newQ != null) setDialogState(() => questions.add(newQ));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || questions.isEmpty || selectedSubjectId == null) return;
                try {
                  await _repo.put('/teacher/quizzes/${quiz['id']}', data: {
                    'title': titleCtrl.text,
                    'description': descCtrl.text,
                    'subject_id': selectedSubjectId,
                    'questions': questions,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz updated successfully'), backgroundColor: AppColors.success));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Update Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
