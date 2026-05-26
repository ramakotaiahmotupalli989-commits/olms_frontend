/// EduCinema LMS — Class Roster Page (Teacher)
/// Student roster with progress, quiz scores, and action menu.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_repository.dart';
import '../../../core/widgets/shared_widgets.dart';

class ClassRosterPage extends StatefulWidget {
  final int classId;
  const ClassRosterPage({super.key, required this.classId});
  @override
  State<ClassRosterPage> createState() => _ClassRosterPageState();
}

class _ClassRosterPageState extends State<ClassRosterPage> {
  final _repo = ApiRepository();
  List<dynamic> _classes = [];
  int? _selectedClassId;
  List<dynamic> _students = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _classes = await _repo.getList('/teacher/attendance/classes');
      if (_classes.isNotEmpty) {
        final hasClass = _classes.any((c) => c['class_id'] == widget.classId);
        _selectedClassId = hasClass ? widget.classId : _classes[0]['class_id'];
        await _loadRoster();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRoster() async {
    if (_selectedClassId == null) return;
    try {
      _students = await _repo.getList('/teacher/class/$_selectedClassId/roster');
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((s) => (s['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    
    final parentNameCtrl = TextEditingController();
    final parentEmailCtrl = TextEditingController();
    final parentPassCtrl = TextEditingController();
    
    bool isSubmitting = false;
    int? selectedClassId = _selectedClassId ?? widget.classId;
    final classesFuture = _repo.getList('/teacher/attendance/classes');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Onboard Student & Parent', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<dynamic>>(
              future: classesFuture,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final classes = snapshot.data ?? [];
                
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      if (classes.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final uniqueClasses = <int, Map<String, dynamic>>{};
                            for (var c in classes) {
                              final idVal = c['class_id'];
                              int? id;
                              if (idVal is int) {
                                id = idVal;
                              } else if (idVal is String) {
                                id = int.tryParse(idVal);
                              }
                              if (id != null) {
                                uniqueClasses[id] = c;
                              }
                            }
                            final hasSelected = uniqueClasses.containsKey(selectedClassId);
                            return Column(
                              children: [
                                DropdownButtonFormField<int>(
                                  value: hasSelected ? selectedClassId : null,
                                  decoration: InputDecoration(
                                    labelText: 'Class / Section *',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: uniqueClasses.entries.map((entry) {
                                    final c = entry.value;
                                    return DropdownMenuItem<int>(
                                      value: entry.key,
                                      child: Text('Class ${c['grade'] ?? ''} - ${c['section'] ?? ''}'),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setDialogState(() => selectedClassId = v),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }
                        ),
                      ],
                      TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: rollCtrl, decoration: InputDecoration(labelText: 'Roll Number *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: 'Phone (Used for both) *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: addressCtrl, decoration: InputDecoration(labelText: 'Address (Used for both) *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: passCtrl, decoration: InputDecoration(labelText: 'Student Password *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      
                      const SizedBox(height: 24),
                      Text('Parent Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      TextField(controller: parentNameCtrl, decoration: InputDecoration(labelText: 'Parent Full Name *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: parentEmailCtrl, decoration: InputDecoration(labelText: 'Parent Email *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 12),
                      TextField(controller: parentPassCtrl, decoration: InputDecoration(labelText: 'Parent Password *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    ],
                  ),
                );
              }
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (nameCtrl.text.isEmpty || rollCtrl.text.isEmpty || emailCtrl.text.isEmpty || 
                    phoneCtrl.text.isEmpty || passCtrl.text.isEmpty || addressCtrl.text.isEmpty ||
                    parentNameCtrl.text.isEmpty || parentEmailCtrl.text.isEmpty || parentPassCtrl.text.isEmpty || selectedClassId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required!'), backgroundColor: AppColors.error));
                  return;
                }
                setDialogState(() => isSubmitting = true);
                try {
                  final q = '?name=${Uri.encodeComponent(nameCtrl.text)}&class_id=$selectedClassId'
                      '&roll_number=${Uri.encodeComponent(rollCtrl.text)}'
                      '&email=${Uri.encodeComponent(emailCtrl.text)}'
                      '&phone=${Uri.encodeComponent(phoneCtrl.text)}'
                      '&password=${Uri.encodeComponent(passCtrl.text)}'
                      '&address=${Uri.encodeComponent(addressCtrl.text)}'
                      '&parent_name=${Uri.encodeComponent(parentNameCtrl.text)}'
                      '&parent_email=${Uri.encodeComponent(parentEmailCtrl.text)}'
                      '&parent_phone=${Uri.encodeComponent(phoneCtrl.text)}'
                      '&parent_password=${Uri.encodeComponent(parentPassCtrl.text)}'
                      '&parent_address=${Uri.encodeComponent(addressCtrl.text)}';
                  await _repo.post('/teacher/students$q');
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student & Parent accounts created successfully'), backgroundColor: AppColors.success));
                  }
                  _load();
                } catch (e) {
                  setDialogState(() => isSubmitting = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding student: $e'), backgroundColor: AppColors.error));
                  }
                }
              },
              child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Onboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    if (_classes.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedClassId,
                isExpanded: true,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                items: _classes.map<DropdownMenuItem<int>>((c) {
                  final label = 'Class ${c['grade']}${c['section'] != null ? ' - ${c['section']}' : ''} (${c['student_count']} students)';
                  return DropdownMenuItem(value: c['class_id'] as int, child: Text(label));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedClassId = val;
                    _loading = true;
                  });
                  _loadRoster();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Class Roster'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: _showAddStudentDialog),
        ],
      ),
      body: Column(children: [
        _buildClassSelector(),
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
              : _filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No students found',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a class or onboard students to get started',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
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
          onSelected: (v) {
            if (v == 'profile') {
              _showStudentProfile(s['id'], s);
            } else if (v == 'message') {
              _handleSendMessage(s['id'], s['name'] ?? '');
            } else if (v == 'toggle') {
              _handleToggleActive(s['id'], s['name'] ?? '', active);
            }
          },
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

  Future<void> _showStudentProfile(int studentId, Map<String, dynamic> briefData) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _repo.get('/teacher/student/$studentId/profile'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading profile: ${snapshot.error}', style: GoogleFonts.inter(color: AppColors.error)));
                  }
                  
                  final data = snapshot.data ?? {};
                  final student = data['student'] ?? {};
                  final chapters = (data['chapter_progress'] as List?) ?? [];
                  final quizzes = (data['quiz_history'] as List?) ?? [];
                  
                  return ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text((student['name'] ?? 'S')[0], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student['name'] ?? briefData['name'] ?? '', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (student['roll_number'] != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                        child: Text('Roll: #${student['roll_number']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text('Last Login: ${student['last_login'] ?? 'Never'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Contact Details'),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.email_outlined, 'Email', briefData['email'] ?? 'N/A'),
                            const Divider(height: 24),
                            _buildInfoRow(Icons.phone_outlined, 'Phone', briefData['phone'] ?? 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionHeader(title: 'Chapter Progress'),
                          StatusBadge(label: '${chapters.length} Chapters', color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (chapters.isEmpty)
                        const EmptyState(icon: Icons.video_library_outlined, title: 'No progress recorded', subtitle: 'This student hasn\'t watched any videos yet')
                      else
                        ...chapters.map((c) {
                          final pct = (c['completion_percent'] ?? 0.0).toDouble();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(c['chapter_title'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${pct.toInt()}% Completed', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionHeader(title: 'Quiz Performance'),
                          StatusBadge(label: '${quizzes.length} Quizzes', color: AppColors.secondary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (quizzes.isEmpty)
                        const EmptyState(icon: Icons.quiz_outlined, title: 'No quiz attempts', subtitle: 'This student hasn\'t taken any quizzes yet')
                      else
                        ...quizzes.map((q) {
                          final score = (q['score'] ?? 0.0).toDouble();
                          final total = (q['total_marks'] ?? 100.0).toDouble();
                          final percent = total > 0 ? (score / total) * 100 : 0.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
                            child: Row(
                              children: [
                                const Icon(Icons.assignment_turned_in_outlined, color: AppColors.secondary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('Quiz ID: #${q['quiz_id']}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                                Text(
                                  '${score.toInt()}/${total.toInt()} (${percent.toInt()}%)',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: percent >= 70 ? AppColors.success : AppColors.warning),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Future<void> _handleSendMessage(int studentId, String studentName) async {
    try {
      final res = await _repo.get('/messaging/conversations');
      final conversations = res['conversations'] as List?;
      if (conversations != null) {
        final match = conversations.firstWhere(
          (c) => c['initiator'] != null && c['initiator']['id'] == studentId,
          orElse: () => null,
        );
        if (match != null) {
          if (mounted) {
            context.push('/messaging/${match['id']}');
          }
          return;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No existing conversation with $studentName. Teachers can reply to existing student messages in the Messages tab.'),
            backgroundColor: AppColors.info,
          ),
        );
        context.push('/messaging');
      }
    } catch (e) {
      if (mounted) {
        context.push('/messaging');
      }
    }
  }

  Future<void> _handleToggleActive(int studentId, String studentName, bool currentStatus) async {
    try {
      await _repo.patch('/teacher/students/$studentId/toggle-active');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$studentName has been ${currentStatus ? 'deactivated' : 'activated'} successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadRoster();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
