/// EduCinema LMS — Conversation Detail Page
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/messaging_models.dart';
import '../providers/messaging_providers.dart';

class ConversationDetailPage extends ConsumerStatefulWidget {
  final int conversationId;
  const ConversationDetailPage({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends ConsumerState<ConversationDetailPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  int _currentUserId = 0;
  String _currentUserRole = '';
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadUserAndMessages();
  }

  Future<void> _loadUserAndMessages() async {
    final uid = await _storage.read(key: AppConstants.userIdKey);
    final role = await _storage.read(key: AppConstants.userRoleKey);
    if (mounted) {
      setState(() {
        _currentUserId = int.tryParse(uid ?? '0') ?? 0;
        _currentUserRole = role ?? '';
      });
    }
    await _fetchMessages();
    _connectWebSocket();
  }

  Future<void> _fetchMessages() async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final res = await repo.getMessages(widget.conversationId);
      final rawList = res['messages'] as List<dynamic>? ?? [];
      setState(() {
        _messages = rawList.map((e) => Message.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _connectWebSocket() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token == null) return;

    final wsUrl = Uri.parse('${AppConstants.messagingWebSocketUrl}?token=$token');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'new_message' && data['conversation_id'] == widget.conversationId) {
        _fetchMessages();
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.sendMessage(widget.conversationId, content);
      _msgCtrl.clear();
      await _fetchMessages();
      ref.invalidate(conversationsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _deleteMessage(int msgId) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.deleteMessage(widget.conversationId, msgId);
      await _fetchMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete message')));
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.updateStatus(widget.conversationId, newStatus);
      ref.invalidate(conversationDetailProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final convAsync = ref.watch(conversationDetailProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: convAsync.when(
          data: (conv) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conv.title, style: GoogleFonts.outfit(fontSize: 16)),
              if (conv.subjectName != null)
                Text(conv.subjectName!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          convAsync.maybeWhen(
            data: (conv) {
              if (conv.statusEnum == ConversationStatus.closed) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(child: StatusBadge(label: 'Closed', color: AppColors.textSecondary)),
                );
              }
              if (_currentUserRole == AppConstants.teacher || _currentUserRole == AppConstants.schoolAdmin || _currentUserRole == AppConstants.superAdmin) {
                return PopupMenuButton<String>(
                  onSelected: _updateStatus,
                  itemBuilder: (context) => [
                    if (conv.statusEnum != ConversationStatus.resolved)
                      PopupMenuItem(value: 'resolved', child: Text('Mark Resolved', style: GoogleFonts.inter(color: AppColors.success))),
                    PopupMenuItem(value: 'closed', child: Text('Close Conversation', style: GoogleFonts.inter(color: AppColors.error))),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: convAsync.when(
        data: (conv) => Column(
          children: [
            if (conv.statusEnum == ConversationStatus.resolved)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.success.withValues(alpha: 0.1),
                child: Center(
                  child: Text(
                    'This conversation is marked as resolved.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg.sender.id == _currentUserId;
                        return _buildMessageBubble(msg, isMe);
                      },
                    ),
            ),
            if (conv.statusEnum != ConversationStatus.closed)
              _buildInputBar()
            else
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Text(
                  'This conversation has been closed and cannot accept new messages.',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    if (msg.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'This message was deleted',
            style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe
            ? () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Message?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteMessage(msg.id);
                        },
                        child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            gradient: isMe ? const LinearGradient(colors: [AppColors.featureBlue, AppColors.featurePurple]) : null,
            color: isMe ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
            ],
            border: isMe ? null : Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Text(
                  msg.sender.name,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                msg.content,
                style: GoogleFonts.inter(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(msg.createdAt),
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.white70 : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all : Icons.check,
                      size: 12,
                      color: msg.isRead ? Colors.blue.shade200 : Colors.white70,
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _isSending
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.featureBlue, AppColors.featurePurple]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
