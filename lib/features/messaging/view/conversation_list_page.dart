/// EduCinema LMS — Conversation List Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/messaging_models.dart';
import '../providers/messaging_providers.dart';

class ConversationListPage extends ConsumerStatefulWidget {
  const ConversationListPage({super.key});

  @override
  ConsumerState<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends ConsumerState<ConversationListPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider(_selectedCategory));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(conversationsProvider(_selectedCategory)),
          ),
        ],
      ),
      floatingActionButton: GradientIconButton(
        icon: Icons.add_comment_rounded,
        label: 'New Message',
        colors: const [AppColors.featureBlue, AppColors.featurePurple],
        onTap: () => context.push('/messaging/new').then((_) => ref.invalidate(conversationsProvider(_selectedCategory))),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(),
          Expanded(
            child: conversationsAsync.when(
              data: (data) {
                final List<dynamic> rawList = data['conversations'] ?? [];
                final conversations = rawList.map((e) => Conversation.fromJson(e)).toList();

                if (conversations.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    subtitle: 'You have no conversations in this category.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(conversationsProvider(_selectedCategory)),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      return _buildConversationTile(conv);
                    },
                  ),
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: 110, radius: 18),
              ),
              error: (err, stack) => Center(
                child: Text('Error loading messages: $err', style: GoogleFonts.inter(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final categories = [
      null, // All
      'doubt',
      'academic',
      'attendance',
      'fee',
    ];

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final String label = cat == null ? 'All' : cat[0].toUpperCase() + cat.substring(1);

          return Center(
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              backgroundColor: AppColors.surfaceVariant,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv) {
    final categoryEnum = conv.categoryEnum;
    final statusEnum = conv.statusEnum;

    return Stack(
      children: [
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 18,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/messaging/${conv.id}').then((_) => ref.invalidate(conversationsProvider(_selectedCategory))),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: categoryEnum.color.withValues(alpha: 0.1),
                      child: Icon(categoryEnum.icon, color: categoryEnum.color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(conv.lastMessageAt),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: conv.unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv.lastMessagePreview ?? 'No messages yet.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: conv.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                    fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conv.unreadCount == 0) ...[
                                const SizedBox(width: 8),
                                StatusBadge(label: statusEnum.label, color: statusEnum.color),
                              ]
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  conv.teacher.name,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (conv.unreadCount > 0)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conv.unreadCount}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0 && now.day == time.day) {
      return DateFormat('h:mm a').format(time);
    } else if (diff.inDays < 2 && now.day != time.day) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
