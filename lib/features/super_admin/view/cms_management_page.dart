/// EduCinema LMS — CMS Management Page (Super Admin)
/// Manage subjects, chapters, videos, and quizzes.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class CmsManagementPage extends StatefulWidget {
  const CmsManagementPage({super.key});
  @override
  State<CmsManagementPage> createState() => _CmsManagementPageState();
}

class _CmsManagementPageState extends State<CmsManagementPage> {
  final _repo = ApiRepository();
  List<dynamic> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _subjects = await _repo.getList('/cms/subjects');
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('[CMS] Load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Confirm'),
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
        title: const Text('Content Management (CMS)'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: _showAddSubjectDialog,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add Subject'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const EmptyState(icon: Icons.video_library_rounded, title: 'No content yet', subtitle: 'Start by adding a subject and then chapters/videos')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subjects.length,
                    itemBuilder: (_, i) => _buildSubjectExpansionTile(_subjects[i]),
                  ),
                ),
    );
  }

  Widget _buildSubjectExpansionTile(Map<String, dynamic> subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        title: Text(subject['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text('Grade ${subject['grade'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 20),
        ),
        children: [
          _ChapterList(subjectId: subject['id']),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddChapterDialog(subject['id']),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Chapter'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog() {
    final nameCtrl = TextEditingController();
    final gradeCtrl = TextEditingController(text: '10');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Subject'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Subject Name', prefixIcon: Icon(Icons.label_outline))),
          const SizedBox(height: 12),
          TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Grade', prefixIcon: Icon(Icons.school_outlined))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            final confirmed = await _showConfirmDialog('Confirm Subject', 'Do you want to add "${nameCtrl.text}" for Grade ${gradeCtrl.text}?');
            if (confirmed == true && mounted) {
              try {
                await _repo.post('/cms/subjects', data: {'name': nameCtrl.text, 'grade': gradeCtrl.text});
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject added successfully!'), backgroundColor: AppColors.success));
                  _load();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Add Subject'),
        ),
      ],
    ));
  }

  void _showAddChapterDialog(int subjectId) {
    final titleCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '1');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Chapter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Chapter Title', prefixIcon: Icon(Icons.segment_rounded))),
          const SizedBox(height: 12),
          TextField(controller: orderCtrl, decoration: const InputDecoration(labelText: 'Order Index', prefixIcon: Icon(Icons.sort_rounded))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (titleCtrl.text.isEmpty) return;
            final confirmed = await _showConfirmDialog('Confirm Chapter', 'Add chapter "${titleCtrl.text}" to this subject?');
            if (confirmed == true && mounted) {
              try {
                await _repo.post('/cms/chapters', data: {
                  'subject_id': subjectId,
                  'title': titleCtrl.text,
                  'order_index': int.tryParse(orderCtrl.text) ?? 1
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chapter added successfully!'), backgroundColor: AppColors.success));
                  _load();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Add Chapter'),
        ),
      ],
    ));
  }
}

class _ChapterList extends StatefulWidget {
  final int subjectId;
  const _ChapterList({required this.subjectId});
  @override
  State<_ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<_ChapterList> {
  final _repo = ApiRepository();
  List<dynamic> _chapters = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _repo.getList('/cms/chapters', params: {'subject_id': widget.subjectId});
      if (mounted) setState(() { _chapters = data; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator());
    if (_chapters.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No chapters yet', style: TextStyle(fontSize: 12, color: Colors.grey)));
    return Column(
      children: _chapters.map((c) => ListTile(
        title: Text(c['title'] ?? '', style: GoogleFonts.inter(fontSize: 14)),
        leading: const Icon(Icons.segment_rounded, size: 20, color: Colors.grey),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () => _showVideosForChapter(c),
      )).toList(),
    );
  }

  void _showVideosForChapter(Map<String, dynamic> chapter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ChapterVideoSheet(chapter: chapter),
    ).then((_) => _load());
  }
}

class _ChapterVideoSheet extends StatefulWidget {
  final Map<String, dynamic> chapter;
  const _ChapterVideoSheet({required this.chapter});
  @override
  State<_ChapterVideoSheet> createState() => _ChapterVideoSheetState();
}

class _ChapterVideoSheetState extends State<_ChapterVideoSheet> {
  final _repo = ApiRepository();
  List<dynamic> _videos = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _repo.getList('/cms/videos', params: {'chapter_id': widget.chapter['id']});
      if (mounted) setState(() { _videos = data; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chapter['title'] ?? 'Videos', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
                  Text('Manage video lessons for this chapter', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddVideoDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Video'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_loading && _videos.isEmpty) const Expanded(child: Center(child: Text('No videos in this chapter'))),
          if (!_loading && _videos.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 12),
                itemCount: _videos.length,
                itemBuilder: (_, i) {
                  final v = _videos[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                    child: ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                      ),
                      title: Text(v['title'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text('${v['duration_secs'] ?? 0}s • Language: ${v['language']?.toString().toUpperCase() ?? 'EN'}', style: const TextStyle(fontSize: 12)),
                      trailing: Switch(
                        value: v['is_published'] ?? true,
                        activeColor: AppColors.primary,
                        onChanged: (val) async {
                          try {
                            await _repo.post('/cms/videos/${v['id']}/${val ? 'publish' : 'unpublish'}');
                            _load();
                          } catch (e) {}
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAddVideoDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '300');
    String language = 'en';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Video Lesson'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Video Title', prefixIcon: Icon(Icons.title_rounded))),
            const SizedBox(height: 12),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Video URL (Bunny Stream/HLS)', prefixIcon: Icon(Icons.link_rounded))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: 'Duration (s)', prefixIcon: Icon(Icons.timer_outlined)))),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: language,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                      DropdownMenuItem(value: 'te', child: Text('Telugu')),
                    ],
                    onChanged: (v) => setDialogState(() => language = v!),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
              
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Confirm Upload'),
                  content: Text('Do you want to add "${titleCtrl.text}" to this chapter?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                try {
                  await _repo.post('/cms/videos', data: {
                    'chapter_id': widget.chapter['id'],
                    'title': titleCtrl.text,
                    'video_url': urlCtrl.text,
                    'hls_url': urlCtrl.text,
                    'duration_secs': int.tryParse(durationCtrl.text) ?? 300,
                    'language': language,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video added successfully!'), backgroundColor: AppColors.success));
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add Video'),
          ),
        ],
      ),
    ));
  }
}
