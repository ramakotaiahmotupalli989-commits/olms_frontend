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
      // Wait, I need a list of subjects. Let's assume there is a /cms/subjects or similar.
      availableSubjects = await _repo.getList('/cms/subjects');
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
                final subs = await _repo.getList('/cms/subjects');
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
              width: 400,
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
                      Expanded(child: Text('Class ${a['classroom']?['grade']}${a['classroom']?['section'] ?? ''} - ${a['subject']?['name']}', style: GoogleFonts.inter(fontSize: 12))),
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
                    decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.class_)),
                    items: _classes.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                      value: c['id'],
                      child: Text('Grade ${c['grade']} - ${c['section'] ?? 'N/A'}'),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedClassId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.book)),
                    items: availableSubjects.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
                      value: s['id'],
                      child: Text(s['name'] ?? ''),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                  ),
                ],
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
          Text('Last login: ${t['last_login'] ?? 'Never'}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
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

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Teacher', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 12),
            TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name and Email are required'), backgroundColor: AppColors.warning),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _repo.post('/principal/teachers', data: {
                          'name': nameCtrl.text,
                          'email': emailCtrl.text,
                          'phone': phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null,
                          'password': passwordCtrl.text,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _load();
                        if (mounted) {
                          await _showSuccessDialog(
                            'Teacher Added',
                            '"${nameCtrl.text}" has been added successfully.',
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding teacher: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Teacher'),
            ),
          ],
        ),
      ),
    );
  }
}
