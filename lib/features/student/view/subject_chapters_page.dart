/// EduCinema LMS — Subject Chapters Page (Student)
/// Chapter cards with progress indicators, lock status, quiz badges.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_repository.dart';

class SubjectChaptersPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  const SubjectChaptersPage({super.key, required this.subjectId, required this.subjectName});
  @override
  State<SubjectChaptersPage> createState() => _SubjectChaptersPageState();
}

class _SubjectChaptersPageState extends State<SubjectChaptersPage> {
  final _repo = ApiRepository();
  List<dynamic> _chapters = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _chapters = await _repo.getList('/student/subjects/${widget.subjectId}/chapters');
      setState(() => _loading = false);
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.subjectName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chapters.length,
              itemBuilder: (_, i) => _buildChapterCard(_chapters[i], i),
            ),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> ch, int index) {
    final completion = (ch['completion_percent'] ?? 0).toDouble();
    final locked = ch['is_locked'] ?? false;
    final hasQuiz = ch['has_quiz'] ?? false;
    final lockMessage = ch['lock_message'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: locked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: locked
              ? () {
                  if (lockMessage != null && lockMessage.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: [
                        const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(lockMessage)),
                      ]),
                      backgroundColor: Colors.grey.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  }
                }
              : () {
                  // TODO: Navigate to chapter video list
                },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: locked ? Colors.grey.shade300 : Colors.grey.shade100),
            ),
            child: Row(children: [
              // Chapter number
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: locked ? Colors.grey.shade200 : completion >= 100 ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: locked
                      ? const Icon(Icons.lock, color: Colors.grey, size: 20)
                      : completion >= 100
                          ? const Icon(Icons.check_circle, color: AppColors.success, size: 22)
                          : Text('${index + 1}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ch['title'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: locked ? Colors.grey : AppColors.textPrimary)),
                const SizedBox(height: 4),
                if (locked && lockMessage != null) ...[
                  Text(lockMessage, style: GoogleFonts.inter(fontSize: 11, color: AppColors.error, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                ] else ...[
                  Row(children: [
                    Text('${ch['total_videos'] ?? 0} videos', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    if (hasQuiz) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('Quiz', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                      ),
                    ],
                  ]),
                ],
                if (!locked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completion / 100, minHeight: 5,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(completion >= 100 ? AppColors.success : AppColors.primary),
                    ),
                  ),
                ],
              ])),
              const SizedBox(width: 8),
              if (!locked)
                Text('${completion.toInt()}%', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: completion >= 100 ? AppColors.success : AppColors.primary)),
            ]),
          ),
        ),
      ),
    );
  }
}
