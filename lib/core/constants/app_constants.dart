/// EduCinema LMS — App Constants
library;

class AppConstants {
  AppConstants._();

  static const String appName = 'EduCinema LMS';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = 'https://olmsbackend-production.up.railway.app';
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
}
