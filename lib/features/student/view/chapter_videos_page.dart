import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_repository.dart';
import '../../../core/widgets/shared_widgets.dart';

class ChapterVideosPage extends StatefulWidget {
  final int chapterId;
  final String chapterTitle;
  const ChapterVideosPage({super.key, required this.chapterId, required this.chapterTitle});

  @override
  State<ChapterVideosPage> createState() => _ChapterVideosPageState();
}

class _ChapterVideosPageState extends State<ChapterVideosPage> {
  final _repo = ApiRepository();
  List<dynamic> _videos = [];
  bool _loading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      _videos = await _repo.getList('/student/chapter/${widget.chapterId}/videos');
      setState(() => _loading = false);
    } catch (e) {
      String msg = 'Failed to load videos. Please try again.';
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          msg = e.response?.data['detail'] ?? 'Access Restricted';
        } else if (e.response?.data != null && e.response?.data['detail'] != null) {
          msg = e.response?.data['detail'];
        }
      }
      setState(() {
        _errorMessage = msg;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.chapterTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: _errorMessage != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/messaging/new'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Ask Doubt'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.error,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Access Restricted',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _videos.isEmpty
                  ? const EmptyState(
                      icon: Icons.video_library_rounded,
                      title: 'No videos available',
                      subtitle: 'Videos will appear here once they are published for this chapter.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _videos.length,
                      itemBuilder: (_, i) {
                        final v = _videos[i];
                        return _buildVideoCard(v);
                      },
                    ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final thumb = video['thumbnail_url'];
    final duration = video['duration_secs'] ?? 0;
    final mins = (duration / 60).floor();
    final secs = duration % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Play Video?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              content: Text('Do you want to play "${video['title'] ?? 'this lesson'}"?', style: GoogleFonts.inter(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with duration overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: thumb != null && thumb.isNotEmpty
                        ? Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(6)),
                    child: Text('${mins}m ${secs}s', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video['title'] ?? '', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.language_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text((video['language'] ?? 'EN').toString().toUpperCase(), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    if (video['watched_percent'] != null) ...[
                      Text('${(video['watched_percent'] as num).toInt()}% watched', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(child: Icon(Icons.play_circle_outline, color: AppColors.primary, size: 40)),
    );
  }
}
