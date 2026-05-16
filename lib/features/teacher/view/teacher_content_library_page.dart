/// EduCinema LMS — Teacher Content Library
/// Browse subjects, chapters, and videos for classroom presentation.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class TeacherContentLibraryPage extends StatefulWidget {
  const TeacherContentLibraryPage({super.key});
  @override
  State<TeacherContentLibraryPage> createState() => _TeacherContentLibraryPageState();
}

class _TeacherContentLibraryPageState extends State<TeacherContentLibraryPage> {
  final _repo = ApiRepository();
  List<dynamic> _subjects = [];
  bool _loading = true;
  String _searchQuery = '';
  int? _expandedSubjectIdx;
  int? _expandedChapterIdx;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _subjects = await _repo.getList('/teacher/content');
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Content Library', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearchSheet(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const EmptyState(
                  icon: Icons.library_books_rounded,
                  title: 'No content available',
                  subtitle: 'Content will appear once your subjects are assigned and videos published',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF667EEA).withValues(alpha: 0.08), const Color(0xFF764BA2).withValues(alpha: 0.04)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.15)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.assignment_ind_rounded, size: 20, color: Color(0xFF667EEA)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'Showing ${_filteredSubjects.length} subject${_filteredSubjects.length != 1 ? 's' : ''} assigned to you',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF667EEA)),
                        )),
                      ]),
                    ),
                    ..._filteredSubjects.asMap().entries.map(
                      (e) => _buildSubjectCard(e.value as Map<String, dynamic>, e.key),
                    ),
                  ],
                ),
    );
  }

  List<dynamic> get _filteredSubjects {
    if (_searchQuery.isEmpty) return _subjects;
    return _subjects.where((s) {
      final name = (s['subject_name'] ?? '').toString().toLowerCase();
      if (name.contains(_searchQuery.toLowerCase())) return true;
      // Also search within chapters and videos
      for (var ch in (s['chapters'] as List? ?? [])) {
        if ((ch['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())) return true;
        for (var v in (ch['videos'] as List? ?? [])) {
          if ((v['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())) return true;
        }
      }
      return false;
    }).toList();
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search subjects, chapters, videos...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, int subjectIdx) {
    final chapters = (subject['chapters'] as List?) ?? [];
    final isExpanded = _expandedSubjectIdx == subjectIdx;
    final totalVideos = chapters.fold<int>(0, (sum, ch) => sum + ((ch['videos'] as List?)?.length ?? 0));
    final grade = subject['grade'] ?? '';

    // Gradient palette for subjects
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
          // Subject header
          InkWell(
            onTap: () => setState(() => _expandedSubjectIdx = isExpanded ? null : subjectIdx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                          subject['subject_name'] ?? '',
                          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grade $grade • ${chapters.length} chapters • $totalVideos videos',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
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

          // Chapters (expanded)
          if (isExpanded)
            ...chapters.asMap().entries.map((entry) {
              final chIdx = entry.key;
              final ch = entry.value;
              return _buildChapterTile(ch, subjectIdx, chIdx);
            }),
        ],
      ),
    );
  }

  Widget _buildChapterTile(Map<String, dynamic> chapter, int subjectIdx, int chapterIdx) {
    final videos = (chapter['videos'] as List?) ?? [];
    final isChapterExpanded = _expandedSubjectIdx == subjectIdx && _expandedChapterIdx == chapterIdx;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expandedChapterIdx = isChapterExpanded ? null : chapterIdx),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
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
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${videos.length} video${videos.length != 1 ? 's' : ''}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isChapterExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
                ),
              ],
            ),
          ),
        ),

        // Video list
        if (isChapterExpanded)
          ...videos.map((v) => _buildVideoTile(v as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildVideoTile(Map<String, dynamic> video) {
    final duration = video['duration_secs'] ?? 0;
    final mins = (duration / 60).floor();
    final secs = duration % 60;
    final durationText = '${mins}m ${secs}s';
    final thumb = video['thumbnail_url'];

    return InkWell(
      onTap: () => _launchPresentation(video),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        margin: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 64, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                image: thumb != null
                    ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover)
                    : null,
              ),
              child: thumb == null
                  ? const Icon(Icons.play_circle_filled_rounded, color: AppColors.primary, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'] ?? '',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.present_to_all_rounded, size: 18, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  void _launchPresentation(Map<String, dynamic> video) {
    final videoId = video['id'];
    final title = video['title'] ?? 'Lesson';
    final url = video['video_url'] ?? video['hls_url'] ?? '';
    final thumbnail = video['thumbnail_url'] ?? '';
    final duration = video['duration_secs'] ?? 0;

    context.push(
      '/presentation/$videoId'
      '?title=${Uri.encodeComponent(title)}'
      '&url=${Uri.encodeComponent(url)}'
      '&thumb=${Uri.encodeComponent(thumbnail)}'
      '&duration=$duration',
    );
  }
}
