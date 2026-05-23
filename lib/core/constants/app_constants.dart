/// EduCinema LMS — App Constants
library;

class AppConstants {
  AppConstants._();

  static const String appName = 'EduCinema LMS';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = 'http://localhost:8000';
  static const String apiPrefix = '/api/v1';

  // Tokens
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';

  // Roles
  static const String superAdmin = 'super_admin';
  static const String schoolAdmin = 'school_admin';
  static const String teacher = 'teacher';
  static const String student = 'student';
  static const String parent = 'parent';

  // Ranking
  static const int goldRank = 1;
  static const int silverRank = 2;
  static const int bronzeRank = 3;

  // Messaging
  static const String messagingConversations = '/messaging/conversations';
  static const String messagingUnreadCount = '/messaging/unread-count';
  static String conversationMessages(int id) => '/messaging/conversations/$id/messages';
  static String conversationStatus(int id) => '/messaging/conversations/$id/status';
  static String conversationDetail(int id) => '/messaging/conversations/$id';
  static String deleteMessage(int convId, int msgId) => '/messaging/conversations/$convId/messages/$msgId';

  // WebSocket
  static String get messagingWebSocketUrl =>
      baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://') +
      '/ws/messaging';
}
