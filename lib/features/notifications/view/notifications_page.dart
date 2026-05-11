/// EduCinema LMS — Notifications Page
/// Role-aware notification inbox with unread count, and mark-all-read.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repo = ApiRepository();
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _repo.getList('/notifications/me');
      final count = await _repo.get('/notifications/me/unread-count');
      setState(() {
        _notifications = data;
        _unreadCount = count['unread_count'] ?? 0;
        _loading = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          const Text('Notifications'),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
              child: Text('$_unreadCount', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () async {
                await _repo.post('/notifications/mark-all-read');
                _load();
              },
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No notifications', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) => _buildNotificationItem(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> n) {
    final read = n['read_at'] != null;
    final type = n['notification_type'] ?? '';
    IconData icon;
    Color color;
    switch (type) {
      case 'announcement': icon = Icons.campaign; color = AppColors.primary; break;
      case 'teacher_message': icon = Icons.message; color = AppColors.info; break;
      case 'parent_reply': icon = Icons.reply; color = AppColors.accent; break;
      default: icon = Icons.notifications; color = AppColors.secondary;
    }

    return GestureDetector(
      onTap: () async {
        if (!read) {
          await _repo.patch('/notifications/${n['id']}/read');
          _load();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? Colors.white : AppColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: read ? Colors.grey.shade100 : AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n['title'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: read ? FontWeight.w500 : FontWeight.w600))),
              if (!read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 4),
            Text(n['body'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(n['created_at'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          ])),
        ]),
      ),
    );
  }
}
