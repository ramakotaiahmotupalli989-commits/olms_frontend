/// EduCinema LMS — Messaging Repository
library;

import '../../../core/network/api_repository.dart';
import '../../../core/constants/app_constants.dart';

class MessagingRepository {
  final ApiRepository _api = ApiRepository();

  Future<Map<String, dynamic>> getConversations({
    String? category,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    return _api.get(AppConstants.messagingConversations, params: params);
  }

  Future<Map<String, dynamic>> getConversationDetail(int id) async {
    return _api.get(AppConstants.conversationDetail(id));
  }

  Future<Map<String, dynamic>> createConversation(Map<String, dynamic> data) async {
    return _api.post(AppConstants.messagingConversations, data: data);
  }

  Future<Map<String, dynamic>> getMessages(
    int conversationId, {
    int page = 1,
    int perPage = 50,
  }) async {
    final params = {
      'page': page,
      'per_page': perPage,
    };
    return _api.get(AppConstants.conversationMessages(conversationId), params: params);
  }

  Future<Map<String, dynamic>> sendMessage(int conversationId, String content) async {
    return _api.post(
      AppConstants.conversationMessages(conversationId),
      data: {'content': content},
    );
  }

  Future<Map<String, dynamic>> updateStatus(int conversationId, String status) async {
    return _api.patch(
      AppConstants.conversationStatus(conversationId),
      data: {'status': status},
    );
  }

  Future<void> deleteMessage(int conversationId, int messageId) async {
    await _api.delete(AppConstants.deleteMessage(conversationId, messageId));
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get(AppConstants.messagingUnreadCount);
    return response['unread_count'] as int? ?? 0;
  }
}
