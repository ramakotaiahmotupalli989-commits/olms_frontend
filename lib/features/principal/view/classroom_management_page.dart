/// EduCinema LMS — Classroom Management Page (Principal)
/// Create/manage sections, view student counts, seed default grades.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ClassroomManagementPage extends StatefulWidget {
  const ClassroomManagementPage({super.key});

  @override
  State<ClassroomManagementPage> createState() =>
      _ClassroomManagementPageState();
}

class _ClassroomManagementPageState extends State<ClassroomManagementPage> {
  final _repo = ApiRepository();
  List<dynamic> _classes = [];
  bool _loading = true;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _classes = await _repo.getList('/principal/classes');
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[ClassMgmt] Load error: $e');
      setState(() => _loading = false);
    }
  }

  // ── Seed default grades ──
  Future<void> _seedDefaults() async {
    final confirmed = await _showConfirmDialog(
      'Seed Default Classes',
      'This will create Nursery, LKG, UKG, and Grades 1–10 with Section A. '
          'Already-existing grades will be skipped.',
    );
    if (!confirmed) return;

    setState(() => _seeding = true);
    try {
      final result = await _repo.post('/principal/classes/seed-defaults');
      await _load();
      setState(() => _seeding = false);
      if (mounted) {
        _showSuccessDialog(
          'Classes Seeded',
          '${result['created']} new classes created, ${result['skipped']} already existed.',
        );
      }
    } catch (e) {
      setState(() => _seeding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Add section ──
  Future<void> _showAddSectionDialog() async {
    String selectedGrade = '1';
    final sectionCtrl = TextEditingController();
    bool isSubmitting = false;

    final grades = [
      'Nursery', 'LKG', 'UKG',
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
    ];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Class / Section',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: InputDecoration(
                  labelText: 'Grade',
                  prefixIcon: const Icon(Icons.school_rounded, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: grades
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedGrade = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sectionCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Section (e.g. A, B, C)',
                  prefixIcon: const Icon(Icons.label_rounded, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  hintText: 'A',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (sectionCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Section is required'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _repo.post('/principal/classes', data: {
                          'grade': selectedGrade,
                          'section': sectionCtrl.text.trim().toUpperCase(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _load();
                        if (mounted) {
                          _showSuccessDialog(
                            'Section Created',
                            'Grade $selectedGrade - Section ${sectionCtrl.text.trim().toUpperCase()} has been created.',
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete section ──
  Future<void> _handleDelete(Map<String, dynamic> cls) async {
    final label =
        '${cls['grade']}${cls['section'] != null ? '-${cls['section']}' : ''}';
    final studentCount = cls['student_count'] ?? 0;

    if (studentCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cannot delete $label: $studentCount students enrolled. Move them first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Delete Class $label',
      'Are you sure you want to delete this section? This cannot be undone.',
      isDanger: true,
    );
    if (!confirmed) return;

    try {
      await _repo.delete('/principal/classes/${cls['id']}');
      await _load();
      if (mounted) {
        _showSuccessDialog('Deleted', 'Class $label has been removed.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── View students ──
  Future<void> _viewStudents(Map<String, dynamic> cls) async {
    final label =
        '${cls['grade']}${cls['section'] != null ? '-${cls['section']}' : ''}';

    showDialog(
      context: context,
      builder: (_) => FutureBuilder(
        future: _repo.get('/principal/classes/${cls['id']}/students'),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(snapshot.error.toString()),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close')),
              ],
            );
          }

          final data = snapshot.data as Map<String, dynamic>;
          final students = (data['students'] as List?) ?? [];

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Class $label Students',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 400,
              height: 400,
              child: students.isEmpty
                  ? Center(
                      child: Text('No students enrolled',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final s = students[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppColors.featureBlue.withValues(alpha: 0.1),
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.featureBlue),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['name'] ?? '',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    if (s['roll_number'] != null)
                                      Text('Roll: ${s['roll_number']}',
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: (s['is_active'] ?? true)
                                    ? 'Active'
                                    : 'Inactive',
                                color: (s['is_active'] ?? true)
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  // ── Dialogs ──
  Future<void> _showSuccessDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title:
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text(message,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message,
      {bool isDanger = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          isDanger
              ? Icons.warning_amber_rounded
              : Icons.help_outline_rounded,
          color: isDanger ? AppColors.error : AppColors.primary,
          size: 40,
        ),
        title:
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text(message,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDanger ? AppColors.error : AppColors.primary,
            ),
            child: Text('Confirm',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    // Group classes by grade for a better UI
    final gradeGroups = <String, List<dynamic>>{};
    for (var c in _classes) {
      final grade = c['grade'] ?? 'Unknown';
      gradeGroups.putIfAbsent(grade, () => []).add(c);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Classes & Sections'),
        actions: [
          if (_classes.isEmpty)
            TextButton.icon(
              onPressed: _seeding ? null : _seedDefaults,
              icon: _seeding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_fix_high_rounded, size: 16),
              label: Text(_seeding ? 'Seeding...' : 'Seed Defaults'),
            ),
          TextButton.icon(
            onPressed: _showAddSectionDialog,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Section'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? EmptyState(
                  icon: Icons.class_rounded,
                  title: 'No Classes Yet',
                  subtitle:
                      'Tap "Seed Defaults" to create Nursery–10 with Section A,\nor add sections manually.',
                  action: ElevatedButton.icon(
                    onPressed: _seedDefaults,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('Seed Default Classes'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary row
                      _buildSummaryRow(),
                      const SizedBox(height: 16),

                      // Classes grouped by grade
                      ...gradeGroups.entries.map((entry) {
                        final grade = entry.key;
                        final sections = entry.value;
                        final totalStudents = sections.fold<int>(
                            0, (sum, c) => sum + ((c['student_count'] ?? 0) as int));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        AppColors.featureBlue,
                                        AppColors.featurePurple
                                      ]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Grade $grade',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${sections.length} section${sections.length == 1 ? '' : 's'} • $totalStudents students',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            ...sections.map<Widget>(
                                (c) => _buildClassCard(c)),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryRow() {
    final totalClasses = _classes.length;
    final totalStudents = _classes.fold<int>(
        0, (sum, c) => sum + ((c['student_count'] ?? 0) as int));
    final uniqueGrades = _classes.map((c) => c['grade']).toSet().length;

    return Row(
      children: [
        Expanded(
          child: KpiCard(
            title: 'Total Sections',
            value: '$totalClasses',
            icon: Icons.class_rounded,
            color: AppColors.featureBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            title: 'Grades',
            value: '$uniqueGrades',
            icon: Icons.school_rounded,
            color: AppColors.featurePurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            title: 'Total Students',
            value: '$totalStudents',
            icon: Icons.people_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(Map<String, dynamic> cls) {
    final section = cls['section'] ?? '';
    final studentCount = cls['student_count'] ?? 0;
    final teacherCount = cls['teacher_count'] ?? 0;
    final grade = cls['grade'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.accent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            section.isNotEmpty ? section : '—',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          ),
        ),
        title: Text(
          'Grade $grade - Section ${section.isNotEmpty ? section : 'Default'}',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.people_outline_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '$studentCount student${studentCount == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Icon(Icons.person_outline_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '$teacherCount teacher${teacherCount == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            const PopupMenuItem(
                value: 'students', child: Text('View Students')),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child:
                  Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
          onSelected: (v) {
            switch (v) {
              case 'students':
                _viewStudents(cls);
                break;
              case 'delete':
                _handleDelete(cls);
                break;
            }
          },
        ),
      ),
    );
  }
}
