/// EduCinema LMS — Auth Repository
/// Handles login, OTP, token refresh, and session management.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveTokens(response.data);
    return response.data;
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _api.post('/auth/otp/send', data: {'phone': phone});
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await _api.post('/auth/otp/verify', data: {
      'phone': phone,
      'otp': otp,
    });
    await _saveTokens(response.data);
    return response.data;
  }

  Future<void> logout() async {
    try { await _api.post('/auth/logout'); } catch (_) {}
    await _storage.deleteAll();
  }

  Future<String?> getRole() => _storage.read(key: AppConstants.userRoleKey);
  Future<String?> getToken() => _storage.read(key: AppConstants.accessTokenKey);

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: data['access_token']);
    await _storage.write(key: AppConstants.refreshTokenKey, value: data['refresh_token']);
    await _storage.write(key: AppConstants.userRoleKey, value: data['role']);
    await _storage.write(key: AppConstants.userIdKey, value: data['user_id'].toString());
    if (data['name'] != null) {
      await _storage.write(key: 'user_name', value: data['name']);
    }
  }
}
