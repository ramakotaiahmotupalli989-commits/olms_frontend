/// EduCinema LMS — Content Access Control Page (Super Admin)
/// Manage which schools can access which chapters/subjects.
/// Provides school-centric view with bulk subject-level toggles.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class ContentAccessControlPage extends StatefulWidget {
  const ContentAccessControlPage({super.key});
  @override
  State<ContentAccessControlPage> createState() => _ContentAccessControlPageState();
}

class _ContentAccessControlPageState extends State<ContentAccessControlPage> {
  final _repo = ApiRepository();
  List<dynamic> _schools = [];
  bool _loading = true;
  int? _selectedSchoolId;
  String? _selectedSchoolName;
  Map<String, dynamic>? _accessData;
  bool _loadingAccess = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      _schools = await _repo.getList('/schools/');
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAccessForSchool(int schoolId) async {
    setState(() => _loadingAccess = true);
    try {
      _accessData = await _repo.get('/cms/access/school/$schoolId');
      if (mounted) setState(() => _loadingAccess = false);
    } catch (e) {
      if (mounted) setState(() => _loadingAccess = false);
    }
  }

  Future<void> _toggleSubjectAccess(int subjectId, bool grant) async {
    if (_selectedSchoolId == null) return;
    try {
      await _repo.put('/cms/subjects/$subjectId/access/bulk', data: {
        'school_id': _selectedSchoolId,
        'is_accessible': grant,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(grant ? 'Access granted to all chapters' : 'Access revoked from all chapters'),
          backgroundColor: grant ? AppColors.success : AppColors.error,
        ));
        _loadAccessForSchool(_selectedSchoolId!);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _toggleChapterAccess(int chapterId, bool grant) async {
    if (_selectedSchoolId == null) return;
    try {
      await _repo.put('/cms/chapters/$chapterId/access', data: {
        'school_id': _selectedSchoolId,
        'is_accessible': grant,
      });
      if (mounted) _loadAccessForSchool(_selectedSchoolId!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Content Access Control', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schools.isEmpty
              ? const EmptyState(icon: Icons.school_rounded, title: 'No schools found', subtitle: 'Add schools first before configuring content access')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    
                    if (isWide) {
                      return Row(
                        children: [
                          // Left: School selector
                          SizedBox(
                            width: 300,
                            child: _buildSchoolList(),
                          ),
                          // Right: Access map
                          Expanded(child: _buildAccessMap()),
                        ],
                      );
                    } else {
                      // Mobile: Show list OR access map
                      return _selectedSchoolId == null
                          ? _buildSchoolList()
                          : WillPopScope(
                              onWillPop: () async {
                                setState(() => _selectedSchoolId = null);
                                return false;
                              },
                              child: Stack(
                                children: [
                                  _buildAccessMap(),
                                  Positioned(
                                    top: 10, left: 10,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                                        onPressed: () => setState(() => _selectedSchoolId = null),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                    }
                  },
                ),
    );
  }

  Widget _buildSchoolList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select School', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Choose a school to manage its content access', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _schools.length,
              itemBuilder: (_, i) {
                final school = _schools[i];
                final isSelected = _selectedSchoolId == school['id'];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.school_rounded, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                    ),
                    title: Text(
                      school['name'] ?? '',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${school['city'] ?? ''}, ${school['state'] ?? ''}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20) : null,
                    onTap: () {
                      setState(() {
                        _selectedSchoolId = school['id'];
                        _selectedSchoolName = school['name'];
                      });
                      _loadAccessForSchool(school['id']);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessMap() {
    if (_selectedSchoolId == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 64, color: Colors.black12),
            SizedBox(height: 16),
            Text('Select a school to manage access', style: TextStyle(color: Colors.black38, fontSize: 16)),
          ],
        ),
      );
    }

    if (_loadingAccess) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_accessData == null) {
      return const Center(child: Text('Failed to load access data'));
    }

    final subjects = (_accessData!['subjects'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Content Access for $_selectedSchoolName', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text('Toggle subjects/chapters to grant or revoke access', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // Stats chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${subjects.where((s) => s['all_accessible'] == true).length}/${subjects.length} subjects',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
              ),
            ],
          ),
        ),
        // Subject list
        Expanded(
          child: subjects.isEmpty
              ? const EmptyState(icon: Icons.library_books_rounded, title: 'No content yet', subtitle: 'Add subjects and chapters in CMS first')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subjects.length,
                  itemBuilder: (_, i) => _buildSubjectAccessCard(subjects[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSubjectAccessCard(Map<String, dynamic> subject) {
    final chapters = (subject['chapters'] as List?) ?? [];
    final allAccessible = subject['all_accessible'] == true;
    final anyAccessible = subject['any_accessible'] == true;
    final accessibleCount = subject['accessible_chapters'] ?? 0;
    final totalCount = subject['total_chapters'] ?? 0;

    // Gradient palette
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      [const Color(0xFF4ECDC4), const Color(0xFF44B09E)],
      [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
    ];
    final grad = gradients[(subject['subject_id'] ?? 0) % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: allAccessible ? AppColors.success.withValues(alpha: 0.3) : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: grad[0].withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: grad),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject['subject_name'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('Grade ${subject['grade'] ?? ''} • $accessibleCount/$totalCount chapters', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: allAccessible
                    ? AppColors.success.withValues(alpha: 0.1)
                    : anyAccessible
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                allAccessible ? 'Full Access' : anyAccessible ? 'Partial' : 'No Access',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: allAccessible ? AppColors.success : anyAccessible ? AppColors.warning : AppColors.error,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bulk toggle
            Switch(
              value: allAccessible,
              activeColor: AppColors.success,
              onChanged: (val) => _toggleSubjectAccess(subject['subject_id'], val),
            ),
          ],
        ),
        children: chapters.map<Widget>((ch) {
          final isAccessible = ch['is_accessible'] == true;
          final unlockDate = ch['unlock_date'];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade50))),
            child: Row(
              children: [
                // Chapter icon
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isAccessible ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAccessible ? Icons.check_rounded : Icons.lock_rounded,
                    size: 14,
                    color: isAccessible ? AppColors.success : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ch['title'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                      if (unlockDate != null)
                        Text('Unlocks: $unlockDate', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
                ),
                // Calendar button for scheduling unlock
                IconButton(
                  icon: Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.textSecondary),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: 'Schedule Unlock',
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && _selectedSchoolId != null) {
                      try {
                        await _repo.put('/cms/chapters/${ch['chapter_id']}/access', data: {
                          'school_id': _selectedSchoolId,
                          'is_accessible': isAccessible,
                          'unlock_date': picked.toIso8601String(),
                        });
                        _loadAccessForSchool(_selectedSchoolId!);
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
                // Individual toggle
                Switch(
                  value: isAccessible,
                  activeColor: AppColors.success,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => _toggleChapterAccess(ch['chapter_id'], val),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
