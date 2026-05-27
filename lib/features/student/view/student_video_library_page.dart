/// EduCinema LMS — Student Video Library / Lessons Page
/// Browse subjects of the student's class, list chapters, and watch video lessons.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class StudentVideoLibraryPage extends StatefulWidget {
  const StudentVideoLibraryPage({super.key});

  @override
  State<StudentVideoLibraryPage> createState() => _StudentVideoLibraryPageState();
}

class _StudentVideoLibraryPageState extends State<StudentVideoLibraryPage> {
  final _repo = ApiRepository();
  List<dynamic> _subjects = [];
  bool _loading = true;

  // Caching loaded chapters and videos to avoid duplicate requests
  final Map<int, List<dynamic>> _chaptersMap = {};
  final Map<int, List<dynamic>> _videosMap = {};
  final Map<int, bool> _loadingChapters = {};
  final Map<int, bool> _loadingVideos = {};

  int? _expandedSubjectIdx;
  int? _expandedChapterIdx;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _loading = true);
    try {
      // Fetches the dashboard data which contains the list of subjects for the student's class grade
      final data = await _repo.get('/student/dashboard');
      if (mounted) {
        setState(() {
          _subjects = data['subjects'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadChapters(int subjectId) async {
    if (_chaptersMap.containsKey(subjectId) || _loadingChapters[subjectId] == true) return;

    setState(() => _loadingChapters[subjectId] = true);
    try {
      final chapters = await _repo.getList('/student/subjects/$subjectId/chapters');
      if (mounted) {
        setState(() {
          _chaptersMap[subjectId] = chapters;
          _loadingChapters[subjectId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingChapters[subjectId] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chapters: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadVideos(int chapterId) async {
    if (_videosMap.containsKey(chapterId) || _loadingVideos[chapterId] == true) return;

    setState(() => _loadingVideos[chapterId] = true);
    try {
      final videos = await _repo.getList('/student/chapter/$chapterId/videos');
      if (mounted) {
        setState(() {
          _videosMap[chapterId] = videos;
          _loadingVideos[chapterId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingVideos[chapterId] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading videos: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Video Lessons', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const EmptyState(
                  icon: Icons.video_library_rounded,
                  title: 'No subjects assigned',
                  subtitle: 'Contact your school administration to assign subjects to your class.',
                )
              : RefreshIndicator(
                  onRefresh: _loadSubjects,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subjects.length,
                    itemBuilder: (_, i) {
                      final s = _subjects[i];
                      return _buildSubjectCard(s, i);
                    },
                  ),
                ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, int subjectIdx) {
    final subjectId = subject['id'] as int;
    final chapters = _chaptersMap[subjectId] ?? [];
    final isExpanded = _expandedSubjectIdx == subjectIdx;
    final totalVideos = subject['total_videos'] ?? 0;
    final progress = (subject['progress_percent'] ?? 0).toDouble();

    // Custom gradient palettes matching the dashboard style
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      [const Color(0xFF4ECDC4), const Color(0xFF44B09E)],
      [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFF7797D), const Color(0xFFC471ED)],
    ];
    final grad = gradients[subjectIdx % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: grad[0].withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Subject Header Card
          InkWell(
            onTap: () {
              final expanding = !isExpanded;
              setState(() {
                _expandedSubjectIdx = expanding ? subjectIdx : null;
                _expandedChapterIdx = null; // Reset open chapter when switching subjects
              });
              if (expanding) {
                _loadChapters(subjectId);
              }
            },
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [grad[0], grad[1]],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(20))
                    : BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject['name'] ?? '',
                          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$totalVideos videos • ${progress.toStringAsFixed(0)}% watched',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ),

          // Chapters Section (Expanded)
          if (isExpanded) ...[
            if (_loadingChapters[subjectId] == true)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (chapters.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No chapters available for this subject yet.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chapters.length,
                itemBuilder: (_, chIdx) {
                  final chapter = chapters[chIdx];
                  return _buildChapterTile(chapter, subjectId, chIdx);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterTile(Map<String, dynamic> chapter, int subjectId, int chapterIdx) {
    final chapterId = chapter['chapter_id'] as int;
    final videos = _videosMap[chapterId] ?? [];
    final isChapterExpanded = _expandedChapterIdx == chapterIdx;
    final isLocked = chapter['is_locked'] ?? false;
    final lockMessage = chapter['lock_message'] as String?;

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (isLocked) {
              if (lockMessage != null && lockMessage.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [
                    const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(lockMessage)),
                  ]),
                  backgroundColor: Colors.grey.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
              return;
            }

            final expanding = !isChapterExpanded;
            setState(() {
              _expandedChapterIdx = expanding ? chapterIdx : null;
            });
            if (expanding) {
              _loadVideos(chapterId);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              color: isLocked ? Colors.grey.shade50 : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey.shade200
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isLocked
                        ? const Icon(Icons.lock_rounded, size: 16, color: Colors.grey)
                        : Text(
                            '${chapterIdx + 1}',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter['title'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isLocked ? Colors.grey : AppColors.textPrimary,
                        ),
                      ),
                      if (isLocked && lockMessage != null)
                        Text(
                          lockMessage,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.error, fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          '${chapter['total_videos'] ?? 0} video${chapter['total_videos'] != 1 ? 's' : ''} • ${chapter['completion_percent'] ?? 0}% completed',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (!isLocked)
                  AnimatedRotation(
                    turns: isChapterExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
                  ),
              ],
            ),
          ),
        ),

        // Video list (Expanded)
        if (isChapterExpanded && !isLocked) ...[
          if (_loadingVideos[chapterId] == true)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (videos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No videos in this chapter.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ),
            )
          else
            ...videos.map((v) => _buildVideoTile(v as Map<String, dynamic>)),
        ],
      ],
    );
  }

  Widget _buildVideoTile(Map<String, dynamic> video) {
    final duration = video['duration_secs'] ?? 0;
    final mins = (duration / 60).floor();
    final secs = duration % 60;
    final durationText = '${mins}m ${secs}s';
    final thumb = video['thumbnail_url'];
    final watched = video['watched_percent'] ?? 0;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Play Video?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            content: Text('Do you want to play "${video['title'] ?? 'this lesson'}"?', style: GoogleFonts.inter(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/presentation/${video['id']}'
                    '?title=${Uri.encodeComponent(video['title'] ?? 'Lesson')}'
                    '&url=${Uri.encodeComponent(video['video_url'] ?? '')}'
                    '&thumb=${Uri.encodeComponent(video['thumbnail_url'] ?? '')}'
                    '&duration=${video['duration_secs'] ?? 0}',
                  );
                },
                child: const Text('Play', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        margin: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
        ),
        child: Row(
          children: [
            // Thumbnail / Icon
            Container(
              width: 64, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                image: thumb != null && (thumb as String).isNotEmpty
                    ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover)
                    : null,
              ),
              child: thumb == null || (thumb as String).isEmpty
                  ? const Icon(Icons.play_circle_filled_rounded, color: AppColors.primary, size: 24)
                  : const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'] ?? '',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(durationText, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      if (video['language'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (video['language'] ?? 'en').toString().toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.info),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (watched > 0)
                        Text('${(watched as num).toInt()}% watched',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
