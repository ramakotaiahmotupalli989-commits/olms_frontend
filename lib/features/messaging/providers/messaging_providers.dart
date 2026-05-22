/// EduCinema LMS — Messaging Providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/messaging_repository.dart';
import '../data/messaging_models.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository();
});

final conversationsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String?>((ref, category) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getConversations(category: category);
});

final conversationDetailProvider = FutureProvider.family.autoDispose<Conversation, int>((ref, id) async {
  final repo = ref.watch(messagingRepositoryProvider);
  final data = await repo.getConversationDetail(id);
  return Conversation.fromJson(data);
});

final messagesProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, int>((ref, conversationId) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getMessages(conversationId);
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getUnreadCount();
});
