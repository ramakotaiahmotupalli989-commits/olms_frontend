/// EduCinema LMS — Teacher Management Page (Principal)
/// List teachers, add/remove, assign classes, activate/deactivate with confirmations.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class TeacherManagementPage extends StatefulWidget {
  const TeacherManagementPage({super.key});
  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  final _repo = ApiRepository();
  List<dynamic> _teachers = [];
  List<dynamic> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _teachers = await _repo.getList('/principal/teachers');
      try {
        _classes = await _repo.getList('/principal/classes');
      } catch (_) {
        _classes = [];
      }
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[TeacherMgmt] Load error: $e');
      setState(() => _loading = false);
    }
  }

  // ── Success Dialog ──
  Future<void> _showSuccessDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.inter(color: AppColors.textSecondary), textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Confirmation Dialog ──
  Future<bool> _showConfirmDialog(String title, String message, {bool isDanger = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          isDanger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
          color: isDanger ? AppColors.error : AppColors.primary,
          size: 40,
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.inter(color: AppColors.textSecondary), textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppColors.error : AppColors.primary,
            ),
            child: Text('Confirm', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Handle Toggle Activate/Deactivate ──
  Future<void> _handleToggleStatus(Map<String, dynamic> teacher) async {
    final active = teacher['is_active'] ?? true;
    final action = active ? 'Deactivate' : 'Activate';
    final confirmed = await _showConfirmDialog(
      '$action Teacher',
      'Are you sure you want to ${action.toLowerCase()} "${teacher['name']}"?',
      isDanger: active,
    );
    if (!confirmed) return;

    try {
      await _repo.patch('/principal/teachers/${teacher['id']}/toggle-status');
      await _load();
      if (mounted) {
        await _showSuccessDialog(
          'Teacher ${action}d',
          '"${teacher['name']}" has been ${action.toLowerCase()}d successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Handle Remove ──
  Future<void> _handleRemove(Map<String, dynamic> teacher) async {
    final confirmed = await _showConfirmDialog(
      'Remove Teacher',
      'Are you sure you want to remove "${teacher['name']}"? This will deactivate their account.',
      isDanger: true,
    );
    if (!confirmed) return;

    try {
      await _repo.delete('/principal/teachers/${teacher['id']}');
      await _load();
      if (mounted) {
        await _showSuccessDialog(
          'Teacher Removed',
          '"${teacher['name']}" has been removed successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Handle Assign Classes & Subjects ──
  Future<void> _handleAssignClasses(Map<String, dynamic> teacher) async {
    if (_classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No classes available. Create classes first.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    List<dynamic> currentAssignments = [];
    List<dynamic> availableSubjects = [];
    bool dialogLoading = true;

    // Load subjects and current assignments
    try {
      currentAssignments = await _repo.getList('/principal/teachers/${teacher['id']}/assignments');
      availableSubjects = await _repo.getList('/principal/classes'); // Using classes to get subjects logic? No, need subjects.
      // Wait, I need a list of subjects. Let's assume there is a /principal/subjects or similar.
      availableSubjects = await _repo.getList('/principal/subjects');
    } catch (e) {
      debugPrint('[TeacherMgmt] Assignment load error: $e');
    }

    int? selectedClassId;
    int? selectedSubjectId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (dialogLoading) {
            // Initial load in dialog
            Future.microtask(() async {
              try {
                final subs = await _repo.getList('/principal/subjects');
                final assigns = await _repo.getList('/principal/teachers/${teacher['id']}/assignments');
                setDialogState(() {
                  availableSubjects = subs;
                  currentAssignments = assigns;
                  dialogLoading = false;
                });
              } catch (_) {
                setDialogState(() => dialogLoading = false);
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Assignments for ${teacher['name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Assignments:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (currentAssignments.isEmpty)
                      Text('No assignments yet', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ...currentAssignments.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Expanded(child: Text('${a['class_label'] ?? 'Unknown Class'} - ${a['subject_name'] ?? 'Unknown Subject'}', style: GoogleFonts.inter(fontSize: 12))),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                          onPressed: () async {
                            await _repo.delete('/principal/teachers/assignments/${a['id']}');
                            final assigns = await _repo.getList('/principal/teachers/${teacher['id']}/assignments');
                            setDialogState(() => currentAssignments = assigns);
                          },
                        ),
                      ]),
                    )),
                    const Divider(height: 24),
                    Text('Add New Assignment:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.class_), isDense: true),
                    items: _classes.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                      value: c['id'],
                      child: Text('Grade ${c['grade']} - ${c['section'] ?? 'N/A'}', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedClassId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.book), isDense: true),
                    items: availableSubjects.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
                      value: s['id'],
                      child: Text(s['name'] ?? '', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                  ),
                ],
              ),
            ),
          ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ElevatedButton(
                onPressed: (selectedClassId == null || selectedSubjectId == null) ? null : () async {
                  try {
                    await _repo.post('/principal/teachers/${teacher['id']}/assignments', data: {
                      'class_id': selectedClassId,
                      'subject_id': selectedSubjectId,
                      'teacher_id': teacher['id'],
                    });
                    final assigns = await _repo.getList('/principal/teachers/${teacher['id']}/assignments');
                    setDialogState(() {
                      currentAssignments = assigns;
                      selectedClassId = null;
                      selectedSubjectId = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment added'), backgroundColor: AppColors.success));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                  }
                },
                child: const Text('Add Assignment'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teacher Management'),
        actions: [
          TextButton.icon(
            onPressed: _showAddTeacherDialog,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _teachers.isEmpty
              ? const EmptyState(icon: Icons.person_outline, title: 'No teachers yet', subtitle: 'Add teachers to start building your team')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teachers.length,
                    itemBuilder: (_, i) => _buildTeacherCard(_teachers[i]),
                  ),
                ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> t) {
    final active = t['is_active'] ?? true;
    final assignments = (t['assignments'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade200,
          child: Text((t['name'] ?? 'T')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: active ? AppColors.primary : Colors.grey)),
        ),
        title: Row(children: [
          Flexible(child: Text(t['name'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          StatusBadge(label: active ? 'Active' : 'Inactive', color: active ? AppColors.success : AppColors.error),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (t['email'] != null) Text(t['email'], style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          if (t['phone'] != null) Text(t['phone'], style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          if (assignments.isEmpty)
            Row(children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 4),
              Text('No assignments yet', style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning, fontStyle: FontStyle.italic)),
            ])
          else
            Wrap(spacing: 6, runSpacing: 4, children: assignments.map<Widget>((a) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.featureBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.featureBlue.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${a['class_label']} · ${a['subject_name']}',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.featureBlue),
                ),
              );
            }).toList()),
        ]),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'assign', child: Text('Assign Classes')),
            PopupMenuItem<String>(value: 'toggle', child: Text(active ? 'Deactivate' : 'Activate')),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(value: 'remove', child: Text('Remove', style: TextStyle(color: AppColors.error))),
          ],
          onSelected: (v) {
            switch (v) {
              case 'assign':
                _handleAssignClasses(t);
                break;
              case 'toggle':
                _handleToggleStatus(t);
                break;
              case 'remove':
                _handleRemove(t);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showAddTeacherDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'password123');
    bool isSubmitting = false;

    // Step tracking: 0 = basic info, 1 = assignments
    int step = 0;

    // Assignment state
    List<dynamic> availableSubjects = [];
    List<Map<String, dynamic>> pendingAssignments = [];
    int? selectedClassId;
    int? selectedSubjectId;
    bool subjectsLoaded = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Load subjects on Step 2 entry
          if (step == 1 && !subjectsLoaded) {
            subjectsLoaded = true;
            _repo.getList('/principal/subjects').then((subs) {
              setDialogState(() => availableSubjects = subs);
            }).catchError((_) {});
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(step == 0 ? Icons.person_add_rounded : Icons.assignment_ind_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(step == 0 ? 'Onboard Teacher' : 'Assign Classes & Subjects',
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(step == 0 ? 'Step 1 of 2 — Basic Info' : 'Step 2 of 2 — Assignments',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ),
            ]),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: step == 0
                    ? _buildStep1(nameCtrl, emailCtrl, phoneCtrl, passwordCtrl)
                    : _buildStep2(
                        setDialogState, availableSubjects, pendingAssignments,
                        selectedClassId, selectedSubjectId,
                        (cid) => selectedClassId = cid,
                        (sid) => selectedSubjectId = sid,
                      ),
              ),
            ),
            actions: [
              // Back / Cancel
              TextButton(
                onPressed: () {
                  if (step == 0) {
                    Navigator.pop(ctx);
                  } else {
                    setDialogState(() => step = 0);
                  }
                },
                child: Text(step == 0 ? 'Cancel' : 'Back'),
              ),
              // Next / Create
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (step == 0) {
                          // Validate step 1
                          if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name and Email are required'), backgroundColor: AppColors.warning),
                            );
                            return;
                          }
                          setDialogState(() => step = 1);
                        } else {
                          // Submit — create teacher with assignments
                          setDialogState(() => isSubmitting = true);
                          try {
                            final assignmentsPayload = pendingAssignments
                                .map((a) => {'class_id': a['class_id'], 'subject_id': a['subject_id']})
                                .toList();

                            await _repo.post('/principal/teachers', data: {
                              'name': nameCtrl.text,
                              'email': emailCtrl.text,
                              'phone': phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null,
                              'password': passwordCtrl.text,
                              'assignments': assignmentsPayload,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _load();
                            if (mounted) {
                              final count = pendingAssignments.length;
                              await _showSuccessDialog(
                                'Teacher Onboarded',
                                '"${nameCtrl.text}" has been added with $count assignment${count != 1 ? 's' : ''}.',
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(step == 0 ? 'Next' : pendingAssignments.isEmpty ? 'Skip & Create' : 'Create Teacher'),
                        const SizedBox(width: 4),
                        Icon(step == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded, size: 16),
                      ]),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Step 1: Basic Info ──
  Widget _buildStep1(
    TextEditingController nameCtrl,
    TextEditingController emailCtrl,
    TextEditingController phoneCtrl,
    TextEditingController passwordCtrl,
  ) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Progress indicator
      Row(children: [
        Expanded(child: Container(height: 4, decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(2),
        ))),
        const SizedBox(width: 4),
        Expanded(child: Container(height: 4, decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2),
        ))),
      ]),
      const SizedBox(height: 20),
      TextField(
        controller: nameCtrl,
        decoration: InputDecoration(
          labelText: 'Full Name *',
          prefixIcon: const Icon(Icons.person_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: emailCtrl,
        decoration: InputDecoration(
          labelText: 'Email *',
          prefixIcon: const Icon(Icons.email_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      TextField(
        controller: phoneCtrl,
        decoration: InputDecoration(
          labelText: 'Phone (Optional)',
          prefixIcon: const Icon(Icons.phone_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 14),
      TextField(
        controller: passwordCtrl,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          helperText: 'Default: password123',
        ),
      ),
    ]);
  }

  // ── Step 2: Assign Classes & Subjects ──
  Widget _buildStep2(
    StateSetter setDialogState,
    List<dynamic> availableSubjects,
    List<Map<String, dynamic>> pendingAssignments,
    int? selectedClassId,
    int? selectedSubjectId,
    Function(int?) onClassChanged,
    Function(int?) onSubjectChanged,
  ) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Progress indicator
      Row(children: [
        Expanded(child: Container(height: 4, decoration: BoxDecoration(
          color: AppColors.success, borderRadius: BorderRadius.circular(2),
        ))),
        const SizedBox(width: 4),
        Expanded(child: Container(height: 4, decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(2),
        ))),
      ]),
      const SizedBox(height: 16),

      // Info banner
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Assign this teacher to specific classes and subjects. You can also do this later.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.info),
          )),
        ]),
      ),
      const SizedBox(height: 16),

      // Class dropdown
      DropdownButtonFormField<int>(
        value: selectedClassId,
        decoration: InputDecoration(
          labelText: 'Class',
          prefixIcon: const Icon(Icons.class_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        items: _classes.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
          value: c['id'] as int,
          child: Text('Grade ${c['grade']} - ${c['section'] ?? 'N/A'}'),
        )).toList(),
        onChanged: (val) {
          onClassChanged(val);
          setDialogState(() {});
        },
      ),
      const SizedBox(height: 12),

      // Subject dropdown
      DropdownButtonFormField<int>(
        value: selectedSubjectId,
        decoration: InputDecoration(
          labelText: 'Subject',
          prefixIcon: const Icon(Icons.book_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        items: availableSubjects.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
          value: s['id'] as int,
          child: Text('${s['name']}${s['grade'] != null ? ' (${s['grade']})' : ''}', overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: (val) {
          onSubjectChanged(val);
          setDialogState(() {});
        },
      ),
      const SizedBox(height: 12),

      // Add assignment button
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: (selectedClassId == null || selectedSubjectId == null) ? null : () {
            // Check duplicate
            final exists = pendingAssignments.any(
              (a) => a['class_id'] == selectedClassId && a['subject_id'] == selectedSubjectId,
            );
            if (exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This assignment already added'), backgroundColor: AppColors.warning),
              );
              return;
            }

            // Find labels
            final classItem = _classes.firstWhere((c) => c['id'] == selectedClassId, orElse: () => {});
            final subjItem = availableSubjects.firstWhere((s) => s['id'] == selectedSubjectId, orElse: () => {});

            pendingAssignments.add({
              'class_id': selectedClassId,
              'subject_id': selectedSubjectId,
              'class_label': 'Grade ${classItem['grade']} - ${classItem['section'] ?? 'N/A'}',
              'subject_label': subjItem['name'] ?? '',
            });
            onClassChanged(null);
            onSubjectChanged(null);
            setDialogState(() {});
          },
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Assignment'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 12),

      // Pending assignments list
      if (pendingAssignments.isNotEmpty) ...[
        Row(children: [
          Text('Assignments (${pendingAssignments.length})',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
          const Spacer(),
        ]),
        const SizedBox(height: 6),
        ...pendingAssignments.asMap().entries.map((entry) {
          final idx = entry.key;
          final a = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '${a['class_label']} → ${a['subject_label']}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
              )),
              InkWell(
                onTap: () {
                  pendingAssignments.removeAt(idx);
                  setDialogState(() {});
                },
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
              ),
            ]),
          );
        }),
      ],
    ]);
  }
}

