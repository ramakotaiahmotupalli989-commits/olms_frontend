/// EduCinema LMS — Teacher Quiz Management
/// Create MCQ quizzes and schedule them for assigned classes.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<dynamic> _myAssignments = [];

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
      // To schedule tests, we need to know which classes the teacher teaches
      // We'll get this from a new endpoint or by checking their assignments
      // For now, let's assume we can list their assignments
      _myAssignments = await _repo.getList('/principal/teachers/me/assignments'); // TODO: implement /me/assignments or use principal's
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
                  items: [1, 2, 3].map((id) => DropdownMenuItem(value: id, child: Text('Subject $id'))).toList(), // TODO: use real subjects
                  onChanged: (v) => selectedSubjectId = v,
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
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
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

  void _showScheduleTestDialog() {
    int? selectedQuizId;
    int? selectedClassId;
    DateTime scheduledDate = DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Schedule Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Select Quiz'),
                items: _quizzes.map<DropdownMenuItem<int>>((q) => DropdownMenuItem(value: q['id'], child: Text(q['title']))).toList(),
                onChanged: (v) => selectedQuizId = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Select Class'),
                items: [1, 2, 3].map((id) => DropdownMenuItem(value: id, child: Text('Class $id'))).toList(), // TODO: use my assignments
                onChanged: (v) => selectedClassId = v,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date & Time'),
                subtitle: Text(scheduledDate.toString()),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: scheduledDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setDialogState(() => scheduledDate = DateTime(d.year, d.month, d.day, scheduledDate.hour, scheduledDate.minute));
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
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizDetails(dynamic quiz) {
    // Show questions preview
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
}
